# GrpcClient

This is a gRPC client based on the one in [Spear](https://github.com/NFIBrokerage/spear/), using Mint. It is currently in alpha stage.

## Example
```elixir
msg = %Routeguide.Point{latitude: 408_122_808, longitude: -743_999_179}

rpc = %GrpcClient.Rpc{
  name: "GetFeature",
  request_type: Routeguide.Point,
  request_stream?: false,
  response_type: Routeguide.Feature,
  response_stream?: false,
  service: "GetFeature",
  service_module: "RouteGuide",
  path: "/routeguide.RouteGuide/GetFeature"
}

request = %{Request.from_rpc(rpc) | messages: [msg]}

{:ok, resp} = GenServer.call(conn, {:request, request}, 5000)
response = GrpcClient.Response.from_connection_response(resp, request.rpc, false)
```
