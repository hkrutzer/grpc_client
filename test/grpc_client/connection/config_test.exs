defmodule GrpcClient.Connection.ConfigTest do
  use ExUnit.Case

  alias GrpcClient.Connection.Config

  test "creates a new config" do
    assert Config.new(url: "http://example.org") == %GrpcClient.Connection.Config{
             host: "example.org",
             keep_alive_interval: 10000,
             keep_alive_timeout: 10000,
             mint_opts: [protocols: [:http2], mode: :active],
             port: 80,
             scheme: :http,
             ssl_key_log_file: nil
           }

    assert Config.new(url: "https://example.org") == %GrpcClient.Connection.Config{
             host: "example.org",
             keep_alive_interval: 10000,
             keep_alive_timeout: 10000,
             mint_opts: [protocols: [:http2], mode: :active],
             port: 443,
             scheme: :https,
             ssl_key_log_file: nil
           }
  end

  test "fails with invalid configuration" do
    assert_raise RuntimeError, fn ->
      assert Config.new(url: "1234") == %{}
    end

    assert_raise RuntimeError, fn ->
      assert Config.new(url: "example.org") == %{}
    end
  end

  test "mint protocols and mode options cannot be overriden" do
    config =
      Config.new(
        url: "http://example.org",
        mint_opts: [protocols: [:http2, :http], mode: :passive]
      )

    assert config.mint_opts[:protocols] == [:http2]
    assert config.mint_opts[:mode] == :active
  end
end
