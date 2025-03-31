defmodule GrpcClient.Connection do
  @behaviour :gen_statem

  require Logger

  defstruct [:config, :conn, requests: %{}]

  alias GrpcClient.Connection.Config
  alias GrpcClient.Connection.Request

  # Client API
  def start_link(opts) do
    {gen_statem_opts, opts} = Keyword.split(opts, [:hibernate_after, :debug, :spawn_opt])
    start_args = opts

    case Keyword.fetch(opts, :name) do
      :error ->
        :gen_statem.start_link(__MODULE__, start_args, gen_statem_opts)

      {:ok, atom} when is_atom(atom) ->
        :gen_statem.start_link({:local, atom}, __MODULE__, start_args, gen_statem_opts)

      {:ok, {:global, _term} = tuple} ->
        :gen_statem.start_link(tuple, __MODULE__, start_args, gen_statem_opts)

      {:ok, {:via, via_module, _term} = tuple} when is_atom(via_module) ->
        :gen_statem.start_link(tuple, __MODULE__, start_args, gen_statem_opts)

      {:ok, other} ->
        raise ArgumentError, """
        expected :name option to be one of the following:
          * nil
          * atom
          * {:global, term}
          * {:via, module, term}
        Got: #{inspect(other)}
        """
    end
  end

  def rpc(pid, rpc, payload, opts \\ [])

  def rpc(pid, %GrpcClient.Rpc{} = rpc, payload, opts) do
    rpc = GrpcClient.Request.from_rpc(rpc)
    rpc(pid, rpc, payload, opts)
  end

  def rpc(pid, %GrpcClient.Request{} = rpc, payload, opts) do
    opts = Keyword.put_new(opts, :stream_to, self())
    :gen_statem.call(pid, {:rpc, rpc, payload, opts})
  end

  def stream(pid, ref, payload) do
    :gen_statem.cast(pid, {:stream, ref, payload})
  end

  @doc """
  Send a stream end signal to the server.
  """
  def stream_end(pid, ref) do
    :gen_statem.cast(pid, {:stream_end, ref})
  end

  def stop(pid) do
    :gen_statem.stop(pid)
  end

  # Callbacks
  @impl :gen_statem
  def callback_mode, do: :state_functions

  @impl :gen_statem
  def init(opts) do
    config = Config.new(opts)

    case Mint.HTTP.connect(config.scheme, config.host, config.port, config.mint_opts) do
      {:ok, conn} ->
        state = %__MODULE__{
          config: config,
          conn: conn,
          requests: %{}
        }

        {:ok, :connected, state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def connected({:call, from}, {:rpc, rpc_info, payload, opts}, state) do
    type =
      if rpc_info.rpc.request_stream? and rpc_info.rpc.response_stream? do
        {:stream, opts[:stream_to]}
      else
        :request
      end

    with {:ok, conn, request_ref} <-
           Mint.HTTP2.request(state.conn, "POST", rpc_info.path, rpc_info.headers, :stream),
         request = Request.new(%{messages: payload, rpc: rpc_info.rpc}, request_ref, from, type),
         state = put_in(state.conn, conn),
         state = put_in(state.requests[request_ref], request),
         {:ok, state} <- Request.emit_messages(state, request) do
      case type do
        :request ->
          {:keep_state, state}

        {:stream, _} ->
          state = put_in(state.requests[request_ref].from, nil)
          {:keep_state, state, [{:reply, from, {:ok, request_ref}}]}
      end
    else
      {:error, conn, reason} ->
        {:stop, {:shutdown, reason}, put_in(state.conn, conn)}
    end
  end

  def connected(:cast, {:stream, request_ref, payload}, state) when is_reference(request_ref) do
    case Map.fetch(state.requests, request_ref) do
      {:ok, request} ->
        if payload == :eof do
          # state = put_in(state.requests[request_ref].status, :done)
          # state = Request.continue_request(state, request)
          request = Request.append_data(request, :eof)
          state = Request.continue_request(state, request)
          {:keep_state, state}
        else
          {data, _size} = GrpcClient.Encoding.to_binary_data(payload)
          request = Request.append_data(request, IO.iodata_to_binary(data))
          state = Request.continue_request(state, request)
          {:keep_state, state}
        end

      :error ->
        Logger.error("Cannot stream data over unknown gRPC stream (#{inspect(request_ref)})",
          request_ref: request_ref
        )

        {:keep_state, state}
    end
  end

  def connected(:cast, {:stream_end, request_ref}, state) when is_reference(request_ref) do
    with {:ok, conn} <- Mint.HTTP2.stream_request_body(state.conn, request_ref, :eof) do
      {:keep_state, put_in(state.conn, conn)}
    else
      {:error, conn, reason} ->
        {:stop, {:shutdown, reason}, put_in(state.conn, conn)}
    end
  end

  def connected(:info, message, state) do
    with {:ok, conn, responses} <- Mint.HTTP2.stream(state.conn, message) do
      new_state = handle_responses(%{state | conn: conn}, responses)
      {:keep_state, new_state}
    else
      {:error, conn, reason, responses} ->
        state = put_in(state.conn, conn) |> handle_responses(responses)

        {:stop, {:shutdown, reason}, put_in(state.conn, conn)}

      # unknown message / no active conn in state
      e ->
        Logger.error("Stream error: #{inspect(e)}")
        {:keep_state, state}
    end
  end

  # Private functions
  defp handle_responses(state, responses) do
    Enum.reduce(responses, state, fn response, acc -> handle_response(response, acc) end)
  end

  defp handle_response({:data, request_ref, chunk}, state) do
    update_in(
      state.requests[request_ref],
      &Request.handle_data(&1, chunk)
    )
  end

  defp handle_response({:done, request_ref}, state) do
    {request, state} = pop_in(state.requests[request_ref])

    case request do
      %{type: {:stream, subscriber}, response: response} ->
        grpc_response = GrpcClient.Response.from_connection_response(response, request.rpc, false)

        if grpc_response.status_code == 0 do
          send(subscriber, {request_ref, :eos, :ok})
        else
          send(subscriber, {request_ref, :eos, {:error, grpc_response}})
        end

      %{from: from, response: response} ->
        grpc_response = GrpcClient.Response.from_connection_response(response, request.rpc, false)

        if grpc_response.status_code == 0 do
          :gen_statem.reply(from, {:ok, grpc_response})
        else
          :gen_statem.reply(from, {:error, grpc_response})
        end
    end

    state
  end

  defp handle_response({:status, request_ref, status_code}, state) do
    put_in(state.requests[request_ref].response.status, status_code)
  end

  defp handle_response({:headers, request_ref, new_headers}, state) do
    update_in(
      state.requests[request_ref].response.headers,
      fn headers -> headers ++ new_headers end
    )
  end
end
