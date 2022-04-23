defmodule GrpcClient.EncodingTest do
  use ExUnit.Case

  alias GrpcClient.Encoding

  test "encodes and decodes" do
    msg = %Routeguide.Point{
      latitude: 1,
      longitude: 5
    }

    {encoded, _pos} = Encoding.to_binary_data(msg)
    {decoded, _rest} = Encoding.from_binary_data(IO.iodata_to_binary(encoded), Routeguide.Point)

    assert decoded == msg
  end

  test "invalid data"
end
