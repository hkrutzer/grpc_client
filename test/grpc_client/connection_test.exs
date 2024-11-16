defmodule GrpcClientTest.ConnectionTest do
  use ExUnit.Case

  alias GrpcClient.Connection

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

    {:ok, response} = GrpcClient.Connection.rpc(conn, rpc, [msg])

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

    {:ok, resp} = GrpcClient.Connection.rpc(conn, rpc, [msg])

    %GrpcClient.Response{
      data: stream,
      message: "",
      status: :ok,
      status_code: 0
    } = resp

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

    {:ok, ref} = GrpcClient.Connection.rpc(conn, rpc, [])

    GrpcClient.Connection.stream(conn, ref, msg)

    assert_receive(
      {_ref,
       %Routeguide.RouteNote{
         location: %Routeguide.Point{
           latitude: 409_146_138,
           longitude: -750_000_000
         },
         message: "test message please ignore"
       }}
    )

    GrpcClient.Connection.stream(conn, ref, %{msg | message: "test msg 2"})

    assert_receive({
      _ref,
      %Routeguide.RouteNote{
        location: %Routeguide.Point{
          latitude: 409_146_138,
          longitude: -750_000_000
        },
        message: "test msg 2"
      }
    })

    GrpcClient.Connection.stream_end(conn, ref)

    assert_receive({^ref, :eos, :ok})
  end
end
