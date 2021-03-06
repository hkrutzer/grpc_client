defmodule GrpcClient.Connection.Response do
  @moduledoc false

  # a slim data structure for storing information about an HTTP/2 response

  defstruct [:status, :type, headers: [], data: <<>>]
end
