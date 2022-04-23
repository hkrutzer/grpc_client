defmodule GrpcClientTest.ConnectionTest do
  use ExUnit.Case

  alias GrpcClient.Connection
  alias GrpcClient.Request
  alias GrpcClient.Rpc

  setup do
    {:ok, conn} = Connection.start_link(url: "http://localhost:50051")
    {:ok, [conn: conn]}
  end

  test "sync call, sync response", %{conn: conn} do
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

    assert response == %GrpcClient.Response{
             data: %Routeguide.Feature{
               location: %Routeguide.Point{
                 latitude: 408_122_808,
                 longitude: -743_999_179
               },
               name: "101 New Jersey 10, Whippany, NJ 07981, USA"
             },
             message: "",
             status: :ok,
             status_code: 0
           }
  end

  test "sync call, stream response" do
    {:ok, conn} = Connection.start_link(url: "http://localhost:50051")

    msg = %Routeguide.Rectangle{
      lo: %Routeguide.Point{
        latitude: 406_400_000,
        longitude: -750_000_000
      },
      hi: %Routeguide.Point{
        latitude: 406_500_000,
        longitude: -730_000_000
      }
    }

    rpc = %GrpcClient.Rpc{
      name: "ListFeatures",
      request_type: Routeguide.Point,
      request_stream?: false,
      response_type: Routeguide.Feature,
      response_stream?: true,
      service: "ListFeatures",
      service_module: "RouteGuide",
      path: "/routeguide.RouteGuide/ListFeatures"
    }

    request = %{Request.from_rpc(rpc) | messages: [msg]}

    {:ok, resp} = GenServer.call(conn, {:request, request}, 5000)

    %GrpcClient.Response{
      data: stream,
      message: "",
      status: :ok,
      status_code: 0
    } = GrpcClient.Response.from_connection_response(resp, request.rpc, false)

    assert Enum.into(stream, []) ==
             [
               %Routeguide.Feature{
                 location: %Routeguide.Point{
                   latitude: 406_421_967,
                   longitude: -747_727_624
                 },
                 name: "1 Merck Access Road, Whitehouse Station, NJ 08889, USA"
               },
               %Routeguide.Feature{
                 location: %Routeguide.Point{
                   latitude: 406_411_633,
                   longitude: -741_722_051
                 },
                 name: "3387 Richmond Terrace, Staten Island, NY 10303, USA"
               }
             ]
  end

  test "async call, async response", %{conn: conn} do
    msg = %Routeguide.RouteNote{
      location: %Routeguide.Point{
        latitude: 409_146_138,
        longitude: -750_000_000
      },
      message: "test message please ignore"
    }

    rpc = %GrpcClient.Rpc{
      name: "RouteChat",
      request_type: Routeguide.RouteNote,
      request_stream?: true,
      response_type: Routeguide.RouteNote,
      response_stream?: true,
      service: "RouteChat",
      service_module: "RouteGuide",
      path: "/routeguide.RouteGuide/RouteChat"
    }

    through = fn message, request_ref -> {request_ref, message} end

    request = Request.from_rpc(rpc)

    {:ok, resp} = GenServer.call(conn, {{:subscription, self(), through}, request}, 5000)
    GenServer.cast(conn, {:push, resp, msg})

    assert_receive(
      {_,
       %Routeguide.RouteNote{
         location: %Routeguide.Point{
           latitude: 409_146_138,
           longitude: -750_000_000
         },
         message: "test message please ignore"
       }}
    )

    GenServer.cast(conn, {:push, resp, %{msg | message: "test msg 2"}})

    assert_receive(
      {_,
       %Routeguide.RouteNote{
         location: %Routeguide.Point{
           latitude: 409_146_138,
           longitude: -750_000_000
         },
         message: "test message please ignore"
       }}
    )

    assert_receive(
      {_,
       %Routeguide.RouteNote{
         location: %Routeguide.Point{
           latitude: 409_146_138,
           longitude: -750_000_000
         },
         message: "test msg 2"
       }}
    )

    # TODO send more
  end

  test "ping" do
    {:ok, conn} =
      Connection.start_link(
        url: "http://localhost:50051",
        keep_alive_interval: 100
      )

    Process.sleep(500)

    # TODO ensure we actually pinged
  end
end
