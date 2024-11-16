defmodule GrpcClient.Rpc do
  # This file is derived from https://github.com/NFIBrokerage/spear/blob/9177196721d943fda2ee1a70698580b036f220ee/lib/spear/rpc.ex

  @type t :: %__MODULE__{
          request_type: module(),
          response_type: module(),
          request_stream?: boolean(),
          response_stream?: boolean(),
          path: String.t(),
          name: String.t(),
          service: String.t(),
          service_module: String.t()
        }

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
