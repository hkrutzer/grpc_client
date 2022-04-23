defmodule GrpcClient.Rpc do
  # This file is derived from https://github.com/NFIBrokerage/spear/blob/9177196721d943fda2ee1a70698580b036f220ee/lib/spear/rpc.ex

  @type t :: %__MODULE__{}

  defstruct [
    :request_type,
    :response_type,
    :request_stream?,
    :response_stream?,
    :path,
    :name,
    :service,
    :service_module
  ]
end
