defmodule GrpcClient.Connection do
  # see the very similar original implementation of this process architecture
  # from the Mint documentation:
  # https://github.com/elixir-mint/mint/blob/796b8db097d69ede7163acba223ab2045c2773a4/pages/Architecture.md
  # This file is mostly based on https://github.com/NFIBrokerage/spear/blob/9177196721d943fda2ee1a70698580b036f220ee/lib/spear/connection.ex

  use Connection
  require Logger

  alias GrpcClient.Connection.KeepAliveTimer
  alias GrpcClient.Connection.Config
  alias GrpcClient.Connection.Request

  @post "POST"
  @closed %Mint.TransportError{reason: :closed}

  defstruct [:config, :conn, requests: %{}, keep_alive_timer: %KeepAliveTimer{}]

  @type t :: pid() | GenServer.name()

  @doc false
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]}
    }
  end

  @doc """
  Starts a connection process

  This function can be called directly in order to link it to the current
  process, but the more common workflow is to start a `Spear.Connection`
  GenServer as a part of a supervision tree.

  ## Examples

  E.g. in an application's supervision tree defined in
  `lib/my_app/application.ex`:

      children = [
        {GrpcClient.Connection, name: MyConnection}
      ]
      Supervisor.start_link(children, strategy: :one_for_one)
  """
  @spec start_link(opts :: Keyword.t()) :: {:ok, t()} | GenServer.on_start()
  def start_link(opts) do
    name = Keyword.take(opts, [:name])
    rest = Keyword.delete(opts, :name)

    Connection.start_link(__MODULE__, rest, name)
  end

  @impl Connection
  def init(opts) do
    {:connect, :init, %__MODULE__{config: Config.new(opts)}}
  end

  @impl Connection
  def connect(_, s) do
    case do_connect(s.config) do
      {:ok, conn} ->
        {:ok, %__MODULE__{s | conn: conn, keep_alive_timer: KeepAliveTimer.start(s.config)}}

      {:error, _reason} ->
        # TODO
        {:backoff, 500, s}
    end
  end

  @impl Connection
  def disconnect(info, %__MODULE__{conn: conn} = s) do
    {:ok, _conn} = Mint.HTTP.close(conn)

    :ok = close_requests(s)

    s = %__MODULE__{
      s
      | conn: nil,
        requests: %{},
        keep_alive_timer: KeepAliveTimer.clear(s.keep_alive_timer)
    }

    case info do
      {:close, from} ->
        Connection.reply(from, {:ok, :closed})

        {:noconnect, s}

      _ ->
        {:connect, :reconnect, s}
    end
  end

  @impl Connection
  def handle_cast(:connect, s), do: {:connect, s.config, s}

  def handle_cast({:push, request_ref, message}, s) when is_reference(request_ref) do
    with {wire_data, _size} = GrpcClient.Encoding.to_binary_data(message),
         {:ok, conn} <- Mint.HTTP2.stream_request_body(s.conn, request_ref, wire_data) do
      {:noreply, put_in(s.conn, conn)}
    else
      nil ->
        {:noreply, s}

      {:error, conn, reason} ->
        s = put_in(s.conn, conn)

        if reason == @closed, do: {:disconnect, :closed, s}, else: {:noreply, s}
    end
  end

  @impl Connection
  def handle_call(_call, _from, %__MODULE__{conn: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call(:close, from, s), do: {:disconnect, {:close, from}, s}

  def handle_call(:ping, from, s) do
    case Mint.HTTP2.ping(s.conn) do
      {:ok, conn, request_ref} ->
        s = put_in(s.conn, conn)
        s = put_in(s.requests[request_ref], {:ping, from})
        # put request ref
        {:noreply, s}

      {:error, conn, @closed} ->
        {:disconnect, :closed, {:error, :closed}, put_in(s.conn, conn)}

      {:error, conn, reason} ->
        {:reply, {:error, reason}, put_in(s.conn, conn)}
    end
  end

  def handle_call({:cancel, request_ref}, _from, s) when is_reference(request_ref) do
    with true <- Map.has_key?(s.requests, request_ref),
         {:ok, conn} <- Mint.HTTP2.cancel_request(s.conn, request_ref) do
      {:reply, :ok, put_in(s.conn, conn)}
    else
      false ->
        # idempotent success when the request_ref is not active
        {:reply, :ok, s}

      {:error, conn, @closed} ->
        {:disconnect, :closed, {:error, :closed}, put_in(s.conn, conn)}

      {:error, conn, reason} ->
        {:reply, {:error, reason}, put_in(s.conn, conn)}
    end
  end

  def handle_call({{:subscription, _, _} = type, request}, _from, s) do
    with {:ok, {s, request}} <- request_and_stream_body(s, request, nil, type) do
      {:reply, {:ok, request.request_ref}, s}
    else
      {:error, s, @closed} ->
        {:disconnect, :closed, {:error, :closed}, s}

      {:error, s, reason} ->
        {:reply, {:error, reason}, s}
    end
  end

  def handle_call({:close_subscription, request_ref}, _from, s) do
    with {:ok, conn} <- Mint.HTTP2.stream_request_body(s.conn, request_ref, :eof) do
      {:reply, :ok, put_in(s.conn, conn)}
    else
      {:error, s, @closed} ->
        {:disconnect, :closed, {:error, :closed}, s}

      {:error, s, reason} ->
        {:reply, {:error, reason}, s}
    end
  end

  def handle_call({:request, request}, from, s) do
    with {:ok, {s, _request}} <- request_and_stream_body(s, request, from, :request) do
      {:noreply, s}
    else
      {:error, s, @closed} ->
        {:disconnect, :closed, {:error, :closed}, s}

      {:error, s, reason} ->
        {:reply, {:error, reason}, s}
    end
  end

  @impl Connection
  def handle_info({:DOWN, monitor_ref, :process, _object, _reason}, s) do
    with {:ok, %{request_ref: request_ref} = request} <-
           fetch_subscription(s, monitor_ref),
         {^request, s} <- pop_in(s.requests[request_ref]),
         {:ok, conn} <- Mint.HTTP2.cancel_request(s.conn, request_ref) do
      {:noreply, put_in(s.conn, conn)}
    else
      {:error, conn, reason} ->
        s = put_in(s.conn, conn)

        if reason == @closed, do: {:disconnect, :closed, s}, else: {:noreply, s}

      _ ->
        {:noreply, s}
    end
  end

  def handle_info(:keep_alive, s) do
    case Mint.HTTP2.ping(s.conn) do
      {:ok, conn, request_ref} ->
        s = put_in(s.conn, conn)
        s = update_in(s.keep_alive_timer, &KeepAliveTimer.start_timeout_timer(&1, request_ref))

        {:noreply, s}

      {:error, conn, reason} ->
        s = put_in(s.conn, conn)

        if reason == @closed, do: {:disconnect, :closed, s}, else: {:noreply, s}
    end
  end

  def handle_info(:keep_alive_expired, s), do: {:disconnect, :keep_alive_timeout, s}

  def handle_info(message, s) do
    with %Mint.HTTP2{} = conn <- s.conn,
         {:ok, conn, responses} <- Mint.HTTP2.stream(conn, message) do
      {:noreply, put_in(s.conn, conn) |> handle_responses(responses)}
    else
      {:error, conn, reason, responses} ->
        s = put_in(s.conn, conn) |> handle_responses(responses)

        # TODO error handling
        if reason == @closed, do: {:disconnect, :closed, s}, else: {:noreply, s}

      # unknown message / no active conn in state
      _ ->
        {:noreply, s}
    end
  end

  @spec handle_responses(%__MODULE__{}, list()) :: %__MODULE__{}
  defp handle_responses(s, responses) do
    s = update_in(s.keep_alive_timer, &KeepAliveTimer.reset_interval_timer/1)

    responses
    |> Enum.reduce(s, &process_response/2)
    |> Request.continue_requests()
  end

  defp process_response({:status, request_ref, status}, s) do
    put_in(s.requests[request_ref].response.status, status)
  end

  defp process_response({:headers, request_ref, new_headers}, s) do
    update_in(
      s.requests[request_ref].response.headers,
      fn headers -> headers ++ new_headers end
    )
  end

  defp process_response({:data, request_ref, new_data}, s) do
    update_in(
      s.requests[request_ref],
      &Request.handle_data(&1, new_data)
    )
  end

  defp process_response({:pong, request_ref}, s) do
    case pop_in(s.requests[request_ref]) do
      {{:ping, from}, s} ->
        # ping was initiated by a GenServer.call/3
        Connection.reply(from, :pong)

        s

      {nil, s} ->
        # ping was initiated by the keepalive timer
        update_in(s.keep_alive_timer, &KeepAliveTimer.clear_after_timer(&1, request_ref))
    end
  end

  defp process_response({:done, request_ref}, s) do
    {request, s} = pop_in(s.requests[request_ref])

    case request do
      %{type: {:subscription, subscriber, _through}, from: nil} ->
        send(subscriber, {:eos, request_ref, :dropped})

      %{from: from, response: response} ->
        Connection.reply(from, {:ok, response})
    end

    s
  end

  defp process_response(_unknown, s), do: s

  defp request_and_stream_body(s, request, from, request_type) do
    with {:ok, conn, request_ref} <-
           Mint.HTTP2.request(s.conn, @post, request.path, request.headers, :stream),
         request = Request.new(request, request_ref, from, request_type),
         s = put_in(s.conn, conn),
         s = put_in(s.requests[request_ref], request),
         {:ok, s} <- Request.emit_messages(s, request) do
      {:ok, {s, request}}
    else
      {:error, %__MODULE__{} = s, reason} ->
        {:error, s, reason}

      {:error, conn, reason} ->
        {:error, put_in(s.conn, conn), reason}
    end
  end

  defp do_connect(config) do
    {:ok, conn} = Mint.HTTP.connect(config.scheme, config.host, config.port, config.mint_opts)

    if config.ssl_key_log_file do
      socket = Mint.HTTP.get_socket(conn)

      with file <- File.open!(config.ssl_key_log_file, [:append]),
           {:ok, [{:keylog, keylog_items}]} <- :ssl.connection_information(socket, [:keylog]) do
        for keylog_item <- keylog_items do
          :ok = IO.puts(file, keylog_item)
        end
      end
    end

    {:ok, conn}
  end

  defp close_requests(s) do
    :ok = s.requests |> Map.values() |> Enum.each(&close_request/1)
  end

  defp close_request(%{
         type: {:subscription, proc, _through},
         from: nil,
         request_ref: request_ref
       }) do
    send(proc, {:eos, request_ref, :closed})
  end

  defp close_request(%{type: _, from: from}) do
    Connection.reply(from, {:error, :closed})
  end

  @doc false
  @spec fetch_subscription(%__MODULE__{}, reference()) :: {:ok, Request.t()} | :error
  def fetch_subscription(s, monitor_ref) do
    Enum.find_value(s.requests, :error, fn {_request_ref, request} ->
      request.monitor_ref == monitor_ref && {:ok, request}
    end)
  end
end
