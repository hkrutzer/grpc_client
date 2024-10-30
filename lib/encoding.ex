defmodule GrpcClient.Encoding do
  # This module is derived from https://github.com/NFIBrokerage/spear/blob/9177196721d943fda2ee1a70698580b036f220ee/lib/spear/grpc.ex
  # and https://github.com/NFIBrokerage/spear/blob/main/lib/spear/request.ex

  @spec to_binary_data(struct()) :: {iodata(), pos_integer()}
  def to_binary_data(%module{} = message) do
    {:ok, encoded} = module.encode(message)
    iodata = :binary.list_to_bin(encoded)
    length = byte_size(iodata)
    compressed = 0

    {[<<compressed::unsigned-integer-8, length::unsigned-big-integer-8-unit(4)>>, iodata],
     1 + 4 + length}
  end

  # Parse DATA frame(s)
  # See https://github.com/grpc/grpc/blob/fd27fb09b028e5823f3f246e90bad2d02dfd90d3/doc/PROTOCOL-HTTP2.md
  #
  # notes:
  # - "1 byte unsigned integer" is 8 bits, hence `unsigned-integer-8`
  # - `unit(4)` captures 4 bytes for the message_length
  # - endianness does not matter when the binary in question is 1 byte
  #   hence big/little is not specified for `compressed_flag` (however the
  #   default according to the Elixir documentation is big endian).
  #     - it _does_ matter for message_length however which is 4 bytes
  #     - this is why the specification says "big endian" for the message_length
  # - the signature of this function makes it very easy to use with
  #   Stream.unfold/2
  @spec from_binary_data(binary(), module()) :: nil | no_return() | {struct(), binary()}
  def from_binary_data(
        <<0::unsigned-integer-8, message_length::unsigned-big-integer-8-unit(4),
          encoded_message::binary-size(message_length), rest::binary>>,
        module
      ) do
    decoded = Protox.decode!(encoded_message, module)
    {decoded, rest}
  end

  def from_binary_data(_empty_or_malformed, _module), do: nil
end
