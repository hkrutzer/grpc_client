defmodule GrpcClient.Connection.Response do
  @moduledoc false

  # a slim data structure for storing information about an HTTP/2 response

  @type t :: %{
          status: number(),
          type: any(),
          headers: Mint.Types.headers(),
          data: binary()
        }

  defstruct [:status, :type, headers: [], data: <<>>]
end
