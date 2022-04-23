defmodule Spear.Connection.KeepAliveTimerTest do
  use ExUnit.Case, async: true

  alias GrpcClient.Connection.Config
  alias GrpcClient.Connection.KeepAliveTimer

  test "a connection configured to disable keep-alive sets no timers" do
    timer =
      Config.new(url: "http://localhost:2113", keep_alive_interval: false)
      |> KeepAliveTimer.start()

    assert timer.interval_timer == nil
    assert timer.timeout_timers == %{}
  end

  test "starting a timeout timer inserts the timer into timout_timers" do
    ref = make_ref()

    timer = %KeepAliveTimer{interval: 20, timeout: 10} |> KeepAliveTimer.start_timeout_timer(ref)

    assert_receive :keep_alive_expired

    assert Map.has_key?(timer.timeout_timers, ref)
  end

  test "canceling a timeout timer takes the timer out of timout_timers" do
    ref = make_ref()

    timer =
      %KeepAliveTimer{interval: 300, timeout: 200} |> KeepAliveTimer.start_timeout_timer(ref)

    assert Map.has_key?(timer.timeout_timers, ref)

    timer = KeepAliveTimer.clear_after_timer(timer, ref)

    refute Map.has_key?(timer.timeout_timers, ref)

    refute_receive :keep_alive_expired
  end
end
