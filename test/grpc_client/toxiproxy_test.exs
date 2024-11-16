defmodule GrpcClientTest.ToxiproxyTest do
  use ExUnit.Case

  alias GrpcClient.Connection

  setup do
    ToxiproxyEx.populate!([
      %{
        name: "grpc_host",
        listen: "localhost:21212",
        upstream: "localhost:50051"
      }
    ])

    :ok
  end

  test "sync call, sync response" do
    Process.flag(:trap_exit, true)
    {:ok, conn} = Connection.start_link(url: "http://localhost:21212")
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

    assert {{:shutdown, %Mint.HTTPError{reason: :closed}}, _} =
             ToxiproxyEx.get!(:grpc_host)
             |> ToxiproxyEx.down!(fn ->
               catch_exit(GrpcClient.Connection.rpc(conn, rpc, [msg]))
             end)
  end

  test "sync call, sync response 2" do
    Process.flag(:trap_exit, true)
    {:ok, conn} = Connection.start_link(url: "http://localhost:21212")
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

    assert {{:shutdown, %Mint.TransportError{reason: :closed}}, _} =
             ToxiproxyEx.get!(:grpc_host)
             |> ToxiproxyEx.downstream(:reset_peer, [])
             |> ToxiproxyEx.apply!(fn ->
               catch_exit(GrpcClient.Connection.rpc(conn, rpc, [msg]))
             end)
  end
end
