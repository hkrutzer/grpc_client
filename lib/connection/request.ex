defmodule GrpcClient.Connection.Request do
  @moduledoc false

  # a struct representing a stream-able request

  @type t :: %{
          continuation: Enumerable.continuation(),
          request_ref: Mint.Types.request_ref(),
          buffer: binary(),
          from: :gen_statem.from(),
          response: GrpcClient.Connection.Response.t(),
          status: :streaming | :done,
          type: :request | {:stream, pid()},
          rpc: GrpcClient.Rpc.t()
        }

  defstruct [
    :continuation,
    :buffer,
    :request_ref,
    :from,
    :response,
    :status,
    :type,
    :rpc
  ]

  alias GrpcClient.Connection

  def new(
        %{messages: event_stream, rpc: rpc},
        request_ref,
        from,
        type
      ) do
    reducer = &reduce_with_suspend/2

    stream =
      Stream.map(
        event_stream,
        &GrpcClient.Encoding.to_binary_data(&1)
      )

    continuation = &Enumerable.reduce(stream, &1, reducer)

    %__MODULE__{
      continuation: continuation,
      buffer: <<>>,
      request_ref: request_ref,
      from: from,
      response: %GrpcClient.Connection.Response{type: {rpc.service_module, rpc.response_type}},
      status: :streaming,
      type: type,
      rpc: rpc
    }
  end

  defp reduce_with_suspend(
         {message, message_size},
         {message_buffer, message_buffer_size, max_size}
       )
       when message_size + message_buffer_size > max_size do
    {:suspend,
     {[{message, message_size} | message_buffer], message_size + message_buffer_size, max_size}}
  end

  defp reduce_with_suspend(
         {message, message_size},
         {message_buffer, message_buffer_size, max_size}
       ) do
    {:cont,
     {[{message, message_size} | message_buffer], message_size + message_buffer_size, max_size}}
  end

  @spec emit_messages(%Connection{}, %__MODULE__{}) ::
          {:ok, %Connection{}} | {:error, %Connection{}, reason :: any()}
  def emit_messages(state, %__MODULE__{status: :done, buffer: <<>>}), do: {:ok, state}

  def emit_messages(state, %__MODULE__{status: :done, buffer: buffer} = request) do
    smallest_window = get_smallest_window(state.conn, request.request_ref)

    {bytes_to_send, size, rest} =
      case buffer do
        <<bytes_to_send::binary-size(smallest_window), rest::binary>> ->
          {bytes_to_send, smallest_window, rest}

        ^buffer ->
          {buffer, byte_size(buffer), <<>>}
      end

    state
    |> put_request(%__MODULE__{request | buffer: rest})
    |> stream_messages(
      request.request_ref,
      [{bytes_to_send, size}]
    )
  end

  def emit_messages(state, %__MODULE__{buffer: <<>>, continuation: continuation} = request) do
    smallest_window = get_smallest_window(state.conn, request.request_ref)

    {:cont, {[], 0, smallest_window}}
    |> continuation.()
    |> handle_continuation(state, request)
  end

  def emit_messages(
        state,
        %__MODULE__{buffer: buffer, continuation: continuation} = request
      ) do
    smallest_window = get_smallest_window(state.conn, request.request_ref)

    case buffer do
      <<bytes_to_send::binary-size(smallest_window), rest::binary>> ->
        state
        |> put_request(%__MODULE__{request | buffer: rest})
        |> stream_messages(
          request.request_ref,
          [{bytes_to_send, smallest_window}]
        )

      ^buffer ->
        # buffer is small enough to be sent in one go
        # so we resume the happy path of cramming as many messages as possible
        # into frames
        buffer_size = byte_size(buffer)
        request = put_in(request.buffer, <<>>)

        {:cont, {[{buffer, buffer_size}], buffer_size, smallest_window}}
        |> continuation.()
        |> handle_continuation(state, request)
    end
  end

  defp handle_continuation(
         {finished, {message_buffer, _buffer_size, _max_size}},
         state,
         request
       )
       when finished in [:done, :halted] do
    request = put_in(request.status, :done)

    messages =
      if request.rpc.request_stream? and request.rpc.response_stream? do
        message_buffer
      else
        [:eof | message_buffer]
      end

    state
    |> put_request(request)
    |> stream_messages(
      request.request_ref,
      messages
    )
  end

  defp handle_continuation(
         {:suspended,
          {[{overload_message, overload_message_size} | messages_that_fit], buffer_size,
           max_size}, next_continuation},
         state,
         request
       ) do
    # stream messages    :list.reverse(messages_that_fit)
    # turn overload_message into a binary, break it down to allowed size
    # send what any of what the overload_message binary can be sent,
    # add the rest of overload_message binary to the buffer
    fittable_size = max_size - (buffer_size - overload_message_size)

    <<fittable_binary::binary-size(fittable_size), overload_binary::binary>> =
      IO.iodata_to_binary(overload_message)

    request = %__MODULE__{
      request
      | buffer: overload_binary,
        continuation: next_continuation
    }

    state
    |> put_request(request)
    |> stream_messages(
      request.request_ref,
      [{fittable_binary, fittable_size} | messages_that_fit]
    )
  end

  defp stream_messages(state, request_ref, [:eof | others]) do
    case stream_messages(state, request_ref, others) do
      {:ok, state} ->
        stream_single(state, request_ref, :eof)

      error ->
        error
    end
  end

  defp stream_messages(state, request_ref, reversed_messages) when is_list(reversed_messages) do
    body =
      reversed_messages
      |> :lists.reverse()
      |> Enum.map(fn {message, _size} -> message end)

    # write all messages in one shot as iodata
    stream_single(state, request_ref, body)
  end

  defp stream_single(state, request_ref, body) do
    case Mint.HTTP2.stream_request_body(state.conn, request_ref, body) do
      {:ok, conn} ->
        {:ok, put_in(state.conn, conn)}

      {:error, conn, reason} ->
        {:error, put_in(state.conn, conn), reason}
    end
  end

  defp put_request(state, %{request_ref: request_ref} = request) do
    put_in(state.requests[request_ref], request)
  end

  defp get_smallest_window(conn, request_ref) do
    min(
      Mint.HTTP2.get_window_size(conn, :connection),
      Mint.HTTP2.get_window_size(conn, {:request, request_ref})
    )
  end

  def continue_requests(state) do
    Enum.reduce(state.requests, state, fn
      {_request_ref, %__MODULE__{status: status, buffer: buffer} = request}, state
      when status == :streaming or buffer != <<>> ->
        continue_request(state, request)

      _, state ->
        state
    end)
  end

  def continue_request(state, %__MODULE__{type: {:stream, subscriber}} = request) do
    case emit_messages(state, request) do
      {:ok, state} ->
        state

      {:error, state, reason} ->
        # TODO See if we need to handle this differently
        send(subscriber, {request.request_ref, {:error, reason}})

        state
    end
  end

  def continue_request(state, request) do
    case emit_messages(state, request) do
      {:ok, state} ->
        state

      {:error, state, reason} ->
        {%{from: from}, state} = pop_in(state.requests[request.request_ref])

        :gen_statem.reply(from, {:error, reason})

        state
    end
  end

  def handle_data(%__MODULE__{type: :request} = request, new_data) do
    update_in(request.response.data, fn data -> data <> new_data end)
  end

  def handle_data(%__MODULE__{type: {:stream, subscriber}} = request, new_data) do
    case GrpcClient.Encoding.from_binary_data(
           request.response.data <> new_data,
           request.rpc.response_type
         ) do
      {message, rest} ->
        send(subscriber, {request.request_ref, message})

        put_in(request.response.data, rest)
        |> handle_data(<<>>)

      nil ->
        update_in(request.response.data, fn data -> data <> new_data end)
    end
  end

  def append_data(request, data) do
    update_in(request.buffer, &(&1 <> data))
  end
end
