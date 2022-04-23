defmodule GrpcClient.Request do
  @moduledoc false

  # This file is derived from https://github.com/NFIBrokerage/spear/blob/9177196721d943fda2ee1a70698580b036f220ee/lib/spear/request.ex

  alias GrpcClient.Rpc

  defstruct [
    :service,
    :service_module,
    :rpc,
    :path,
    :headers,
    messages: []
  ]

  def from_rpc(%Rpc{} = rpc, authorization \\ nil) do
    %__MODULE__{
      service: rpc.service,
      service_module: rpc.service_module,
      rpc: rpc,
      path: rpc.path,
      headers: headers(authorization)
    }
  end

  @spec headers(String.t() | nil) :: [{String.t(), String.t()}]
  defp headers(authorization) do
    maybe_auth_header =
      if authorization do
        [{"authorization", authorization}]
      else
        []
      end

    [
      {"te", "trailers"},
      {"content-type", "application/grpc"}
    ] ++ maybe_auth_header
  end
end
