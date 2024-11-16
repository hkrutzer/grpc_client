defmodule GrpcClient.Connection.Config do
  @default_mint_opts [
    protocols: [:http2],
    mode: :active,
    tcp_opts: [nodelay: true]
  ]

  @options_schema [
    url: [
      type: :string,
      default: "http://localhost:50051"
    ],
    ssl_key_log_file: [
      type: :string
    ],
    keep_alive_interval: [
      type: {:or, [:pos_integer, :boolean]},
      default: 10_000
    ],
    keep_alive_timeout: [
      type: {:or, [:pos_integer, :boolean]},
      default: 10_000
    ],
    mint_opts: [
      type: :keyword_list,
      required: true
    ]
  ]

  @moduledoc """
  Configuration the GrpcClient connection

  ## Options

  * `:mint_opts` - (default: `#{inspect(@default_mint_opts)}`) a keyword
    list of options to pass to mint. The default values cannot be overridden.

  * `:host` - (default: `"http://localhost"`) the host address of the gRPC server

  * `:port` - (default: `2113`) the external gRPC port of the gRPC server

  * `:tls?` - (default: `false`) whether or not to use TLS to secure the
    connection to the EventStoreDB

  * `:keep_alive_interval` - (default: `10_000`ms - 10s) the period to send
    keep-alive pings to the EventStoreDB. Set `-1` to disable keep-alive
    checks. Should be any integer value `>= 10_000`. This option can be used
    in conjunction with `:keep_alive_timeout` to properly disconnect if the
    EventStoreDB is not responding to network traffic.

  * `:keep_alive_timeout` - (default: `10_000`ms - 10s) the time after sending
    a keep-alive ping when the ping will be considered unacknowledged. Used
    in conjunction with `:keep_alive_interval`. Set to `-1` to disable
    keep-alive checks. Should be any integer value `>= 10_000`.

  #{NimbleOptions.docs(@options_schema)}
  """

  # This file is based in part on https://github.com/NFIBrokerage/spear/blob/9177196721d943fda2ee1a70698580b036f220ee/lib/spear/connection/configuration.ex

  require Logger

  @typedoc """
  gRPC connection configuration
  """
  @type t :: %__MODULE__{
          scheme: :http | :https,
          host: Mint.Types.address(),
          port: :inet.port_number(),
          ssl_key_log_file: String.t() | nil,
          keep_alive_interval: pos_integer() | false,
          keep_alive_timeout: pos_integer() | false,
          mint_opts: Keyword.t()
        }

  defstruct scheme: :http,
            host: "localhost",
            port: 50051,
            ssl_key_log_file: nil,
            keep_alive_interval: 10_000,
            keep_alive_timeout: 10_000,
            mint_opts: []

  @spec new(Keyword.t()) :: t()
  def new(opts) when is_list(opts) do
    opts =
      opts
      |> override_mint_opts()
      |> NimbleOptions.validate!(@options_schema)

    uri =
      opts
      |> Keyword.get(:url)
      |> URI.parse()

    unless uri.host do
      raise "Missing host in URL"
    end

    config =
      opts
      |> Keyword.take([
        :ssl_key_log_file,
        :keep_alive_interval,
        :keep_alive_timeout,
        :mint_opts
      ])
      |> Map.new()
      |> Map.merge(%{
        scheme: String.to_existing_atom(uri.scheme || "http"),
        host: uri.host,
        port: uri.port
      })

    struct(__MODULE__, config)
  end

  defp override_mint_opts(opts) do
    mint_opts =
      opts
      |> Keyword.get(:mint_opts, [])
      |> Keyword.merge(@default_mint_opts)

    Keyword.merge(opts, mint_opts: mint_opts)
  end
end
