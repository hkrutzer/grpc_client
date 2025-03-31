# credo:disable-for-this-file
[
  defmodule Routeguide.Feature do
    @moduledoc false
    defstruct name: "", location: nil, __uf__: []

    (
      (
        @spec encode(struct) :: {:ok, iodata} | {:error, any}
        def encode(msg) do
          try do
            {:ok, encode!(msg)}
          rescue
            e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
          end
        end

        @spec encode!(struct) :: iodata | no_return
        def encode!(msg) do
          [] |> encode_name(msg) |> encode_location(msg) |> encode_unknown_fields(msg)
        end
      )

      []

      [
        defp encode_name(acc, msg) do
          try do
            if msg.name == "" do
              acc
            else
              [acc, "\n", Protox.Encode.encode_string(msg.name)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:name, "invalid field value"), __STACKTRACE__
          end
        end,
        defp encode_location(acc, msg) do
          try do
            if msg.location == nil do
              acc
            else
              [acc, "\x12", Protox.Encode.encode_message(msg.location)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:location, "invalid field value"), __STACKTRACE__
          end
        end
      ]

      defp encode_unknown_fields(acc, msg) do
        Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
          case wire_type do
            0 ->
              [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

            1 ->
              [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

            2 ->
              len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
              [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

            5 ->
              [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
          end
        end)
      end
    )

    (
      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def decode(bytes) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def decode!(bytes) do
            parse_key_value(bytes, struct(Routeguide.Feature))
          end
        )
      )

      (
        @spec parse_key_value(binary, struct) :: struct
        defp parse_key_value(<<>>, msg) do
          msg
        end

        defp parse_key_value(bytes, msg) do
          {field, rest} =
            case Protox.Decode.parse_key(bytes) do
              {0, _, _} ->
                raise %Protox.IllegalTagError{}

              {1, _, bytes} ->
                {len, bytes} = Protox.Varint.decode(bytes)
                {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
                {[name: delimited], rest}

              {2, _, bytes} ->
                {len, bytes} = Protox.Varint.decode(bytes)
                {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

                {[
                   location:
                     Protox.MergeMessage.merge(msg.location, Routeguide.Point.decode!(delimited))
                 ], rest}

              {tag, wire_type, rest} ->
                {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

                {[
                   {msg.__struct__.unknown_fields_name,
                    [value | msg.__struct__.unknown_fields(msg)]}
                 ], rest}
            end

          msg_updated = struct(msg, field)
          parse_key_value(rest, msg_updated)
        end
      )

      []
    )

    (
      @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
      def json_decode(input, opts \\ []) do
        try do
          {:ok, json_decode!(input, opts)}
        rescue
          e in Protox.JsonDecodingError -> {:error, e}
        end
      end

      @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
      def json_decode!(input, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

        Protox.JsonDecode.decode!(
          input,
          Routeguide.Feature,
          &json_library_wrapper.decode!(json_library, &1)
        )
      end

      @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
      def json_encode(msg, opts \\ []) do
        try do
          {:ok, json_encode!(msg, opts)}
        rescue
          e in Protox.JsonEncodingError -> {:error, e}
        end
      end

      @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
      def json_encode!(msg, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
        Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
      end
    )

    (
      @deprecated "Use fields_defs()/0 instead"
      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs() do
        %{
          1 => {:name, {:scalar, ""}, :string},
          2 => {:location, {:scalar, nil}, {:message, Routeguide.Point}}
        }
      end

      @deprecated "Use fields_defs()/0 instead"
      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs_by_name() do
        %{
          location: {2, {:scalar, nil}, {:message, Routeguide.Point}},
          name: {1, {:scalar, ""}, :string}
        }
      end
    )

    (
      @spec fields_defs() :: list(Protox.Field.t())
      def fields_defs() do
        [
          %{
            __struct__: Protox.Field,
            json_name: "name",
            kind: {:scalar, ""},
            label: :optional,
            name: :name,
            tag: 1,
            type: :string
          },
          %{
            __struct__: Protox.Field,
            json_name: "location",
            kind: {:scalar, nil},
            label: :optional,
            name: :location,
            tag: 2,
            type: {:message, Routeguide.Point}
          }
        ]
      end

      [
        @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
        (
          def field_def(:name) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "name",
               kind: {:scalar, ""},
               label: :optional,
               name: :name,
               tag: 1,
               type: :string
             }}
          end

          def field_def("name") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "name",
               kind: {:scalar, ""},
               label: :optional,
               name: :name,
               tag: 1,
               type: :string
             }}
          end

          []
        ),
        (
          def field_def(:location) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "location",
               kind: {:scalar, nil},
               label: :optional,
               name: :location,
               tag: 2,
               type: {:message, Routeguide.Point}
             }}
          end

          def field_def("location") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "location",
               kind: {:scalar, nil},
               label: :optional,
               name: :location,
               tag: 2,
               type: {:message, Routeguide.Point}
             }}
          end

          []
        ),
        def field_def(_) do
          {:error, :no_such_field}
        end
      ]
    )

    (
      @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
      def unknown_fields(msg) do
        msg.__uf__
      end

      @spec unknown_fields_name() :: :__uf__
      def unknown_fields_name() do
        :__uf__
      end

      @spec clear_unknown_fields(struct) :: struct
      def clear_unknown_fields(msg) do
        struct!(msg, [{unknown_fields_name(), []}])
      end
    )

    (
      @spec required_fields() :: []
      def required_fields() do
        []
      end
    )

    (
      @spec syntax() :: atom()
      def syntax() do
        :proto3
      end
    )

    [
      @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
      def default(:name) do
        {:ok, ""}
      end,
      def default(:location) do
        {:ok, nil}
      end,
      def default(_) do
        {:error, :no_such_field}
      end
    ]
  end,
  defmodule Routeguide.Point do
    @moduledoc false
    defstruct latitude: 0, longitude: 0, __uf__: []

    (
      (
        @spec encode(struct) :: {:ok, iodata} | {:error, any}
        def encode(msg) do
          try do
            {:ok, encode!(msg)}
          rescue
            e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
          end
        end

        @spec encode!(struct) :: iodata | no_return
        def encode!(msg) do
          [] |> encode_latitude(msg) |> encode_longitude(msg) |> encode_unknown_fields(msg)
        end
      )

      []

      [
        defp encode_latitude(acc, msg) do
          try do
            if msg.latitude == 0 do
              acc
            else
              [acc, "\b", Protox.Encode.encode_int32(msg.latitude)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:latitude, "invalid field value"), __STACKTRACE__
          end
        end,
        defp encode_longitude(acc, msg) do
          try do
            if msg.longitude == 0 do
              acc
            else
              [acc, "\x10", Protox.Encode.encode_int32(msg.longitude)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:longitude, "invalid field value"), __STACKTRACE__
          end
        end
      ]

      defp encode_unknown_fields(acc, msg) do
        Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
          case wire_type do
            0 ->
              [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

            1 ->
              [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

            2 ->
              len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
              [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

            5 ->
              [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
          end
        end)
      end
    )

    (
      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def decode(bytes) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def decode!(bytes) do
            parse_key_value(bytes, struct(Routeguide.Point))
          end
        )
      )

      (
        @spec parse_key_value(binary, struct) :: struct
        defp parse_key_value(<<>>, msg) do
          msg
        end

        defp parse_key_value(bytes, msg) do
          {field, rest} =
            case Protox.Decode.parse_key(bytes) do
              {0, _, _} ->
                raise %Protox.IllegalTagError{}

              {1, _, bytes} ->
                {value, rest} = Protox.Decode.parse_int32(bytes)
                {[latitude: value], rest}

              {2, _, bytes} ->
                {value, rest} = Protox.Decode.parse_int32(bytes)
                {[longitude: value], rest}

              {tag, wire_type, rest} ->
                {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

                {[
                   {msg.__struct__.unknown_fields_name,
                    [value | msg.__struct__.unknown_fields(msg)]}
                 ], rest}
            end

          msg_updated = struct(msg, field)
          parse_key_value(rest, msg_updated)
        end
      )

      []
    )

    (
      @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
      def json_decode(input, opts \\ []) do
        try do
          {:ok, json_decode!(input, opts)}
        rescue
          e in Protox.JsonDecodingError -> {:error, e}
        end
      end

      @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
      def json_decode!(input, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

        Protox.JsonDecode.decode!(
          input,
          Routeguide.Point,
          &json_library_wrapper.decode!(json_library, &1)
        )
      end

      @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
      def json_encode(msg, opts \\ []) do
        try do
          {:ok, json_encode!(msg, opts)}
        rescue
          e in Protox.JsonEncodingError -> {:error, e}
        end
      end

      @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
      def json_encode!(msg, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
        Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
      end
    )

    (
      @deprecated "Use fields_defs()/0 instead"
      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs() do
        %{1 => {:latitude, {:scalar, 0}, :int32}, 2 => {:longitude, {:scalar, 0}, :int32}}
      end

      @deprecated "Use fields_defs()/0 instead"
      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs_by_name() do
        %{latitude: {1, {:scalar, 0}, :int32}, longitude: {2, {:scalar, 0}, :int32}}
      end
    )

    (
      @spec fields_defs() :: list(Protox.Field.t())
      def fields_defs() do
        [
          %{
            __struct__: Protox.Field,
            json_name: "latitude",
            kind: {:scalar, 0},
            label: :optional,
            name: :latitude,
            tag: 1,
            type: :int32
          },
          %{
            __struct__: Protox.Field,
            json_name: "longitude",
            kind: {:scalar, 0},
            label: :optional,
            name: :longitude,
            tag: 2,
            type: :int32
          }
        ]
      end

      [
        @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
        (
          def field_def(:latitude) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "latitude",
               kind: {:scalar, 0},
               label: :optional,
               name: :latitude,
               tag: 1,
               type: :int32
             }}
          end

          def field_def("latitude") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "latitude",
               kind: {:scalar, 0},
               label: :optional,
               name: :latitude,
               tag: 1,
               type: :int32
             }}
          end

          []
        ),
        (
          def field_def(:longitude) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "longitude",
               kind: {:scalar, 0},
               label: :optional,
               name: :longitude,
               tag: 2,
               type: :int32
             }}
          end

          def field_def("longitude") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "longitude",
               kind: {:scalar, 0},
               label: :optional,
               name: :longitude,
               tag: 2,
               type: :int32
             }}
          end

          []
        ),
        def field_def(_) do
          {:error, :no_such_field}
        end
      ]
    )

    (
      @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
      def unknown_fields(msg) do
        msg.__uf__
      end

      @spec unknown_fields_name() :: :__uf__
      def unknown_fields_name() do
        :__uf__
      end

      @spec clear_unknown_fields(struct) :: struct
      def clear_unknown_fields(msg) do
        struct!(msg, [{unknown_fields_name(), []}])
      end
    )

    (
      @spec required_fields() :: []
      def required_fields() do
        []
      end
    )

    (
      @spec syntax() :: atom()
      def syntax() do
        :proto3
      end
    )

    [
      @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
      def default(:latitude) do
        {:ok, 0}
      end,
      def default(:longitude) do
        {:ok, 0}
      end,
      def default(_) do
        {:error, :no_such_field}
      end
    ]
  end,
  defmodule Routeguide.Rectangle do
    @moduledoc false
    defstruct lo: nil, hi: nil, __uf__: []

    (
      (
        @spec encode(struct) :: {:ok, iodata} | {:error, any}
        def encode(msg) do
          try do
            {:ok, encode!(msg)}
          rescue
            e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
          end
        end

        @spec encode!(struct) :: iodata | no_return
        def encode!(msg) do
          [] |> encode_lo(msg) |> encode_hi(msg) |> encode_unknown_fields(msg)
        end
      )

      []

      [
        defp encode_lo(acc, msg) do
          try do
            if msg.lo == nil do
              acc
            else
              [acc, "\n", Protox.Encode.encode_message(msg.lo)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:lo, "invalid field value"), __STACKTRACE__
          end
        end,
        defp encode_hi(acc, msg) do
          try do
            if msg.hi == nil do
              acc
            else
              [acc, "\x12", Protox.Encode.encode_message(msg.hi)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:hi, "invalid field value"), __STACKTRACE__
          end
        end
      ]

      defp encode_unknown_fields(acc, msg) do
        Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
          case wire_type do
            0 ->
              [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

            1 ->
              [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

            2 ->
              len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
              [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

            5 ->
              [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
          end
        end)
      end
    )

    (
      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def decode(bytes) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def decode!(bytes) do
            parse_key_value(bytes, struct(Routeguide.Rectangle))
          end
        )
      )

      (
        @spec parse_key_value(binary, struct) :: struct
        defp parse_key_value(<<>>, msg) do
          msg
        end

        defp parse_key_value(bytes, msg) do
          {field, rest} =
            case Protox.Decode.parse_key(bytes) do
              {0, _, _} ->
                raise %Protox.IllegalTagError{}

              {1, _, bytes} ->
                {len, bytes} = Protox.Varint.decode(bytes)
                {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

                {[lo: Protox.MergeMessage.merge(msg.lo, Routeguide.Point.decode!(delimited))],
                 rest}

              {2, _, bytes} ->
                {len, bytes} = Protox.Varint.decode(bytes)
                {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

                {[hi: Protox.MergeMessage.merge(msg.hi, Routeguide.Point.decode!(delimited))],
                 rest}

              {tag, wire_type, rest} ->
                {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

                {[
                   {msg.__struct__.unknown_fields_name,
                    [value | msg.__struct__.unknown_fields(msg)]}
                 ], rest}
            end

          msg_updated = struct(msg, field)
          parse_key_value(rest, msg_updated)
        end
      )

      []
    )

    (
      @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
      def json_decode(input, opts \\ []) do
        try do
          {:ok, json_decode!(input, opts)}
        rescue
          e in Protox.JsonDecodingError -> {:error, e}
        end
      end

      @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
      def json_decode!(input, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

        Protox.JsonDecode.decode!(
          input,
          Routeguide.Rectangle,
          &json_library_wrapper.decode!(json_library, &1)
        )
      end

      @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
      def json_encode(msg, opts \\ []) do
        try do
          {:ok, json_encode!(msg, opts)}
        rescue
          e in Protox.JsonEncodingError -> {:error, e}
        end
      end

      @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
      def json_encode!(msg, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
        Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
      end
    )

    (
      @deprecated "Use fields_defs()/0 instead"
      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs() do
        %{
          1 => {:lo, {:scalar, nil}, {:message, Routeguide.Point}},
          2 => {:hi, {:scalar, nil}, {:message, Routeguide.Point}}
        }
      end

      @deprecated "Use fields_defs()/0 instead"
      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs_by_name() do
        %{
          hi: {2, {:scalar, nil}, {:message, Routeguide.Point}},
          lo: {1, {:scalar, nil}, {:message, Routeguide.Point}}
        }
      end
    )

    (
      @spec fields_defs() :: list(Protox.Field.t())
      def fields_defs() do
        [
          %{
            __struct__: Protox.Field,
            json_name: "lo",
            kind: {:scalar, nil},
            label: :optional,
            name: :lo,
            tag: 1,
            type: {:message, Routeguide.Point}
          },
          %{
            __struct__: Protox.Field,
            json_name: "hi",
            kind: {:scalar, nil},
            label: :optional,
            name: :hi,
            tag: 2,
            type: {:message, Routeguide.Point}
          }
        ]
      end

      [
        @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
        (
          def field_def(:lo) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "lo",
               kind: {:scalar, nil},
               label: :optional,
               name: :lo,
               tag: 1,
               type: {:message, Routeguide.Point}
             }}
          end

          def field_def("lo") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "lo",
               kind: {:scalar, nil},
               label: :optional,
               name: :lo,
               tag: 1,
               type: {:message, Routeguide.Point}
             }}
          end

          []
        ),
        (
          def field_def(:hi) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "hi",
               kind: {:scalar, nil},
               label: :optional,
               name: :hi,
               tag: 2,
               type: {:message, Routeguide.Point}
             }}
          end

          def field_def("hi") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "hi",
               kind: {:scalar, nil},
               label: :optional,
               name: :hi,
               tag: 2,
               type: {:message, Routeguide.Point}
             }}
          end

          []
        ),
        def field_def(_) do
          {:error, :no_such_field}
        end
      ]
    )

    (
      @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
      def unknown_fields(msg) do
        msg.__uf__
      end

      @spec unknown_fields_name() :: :__uf__
      def unknown_fields_name() do
        :__uf__
      end

      @spec clear_unknown_fields(struct) :: struct
      def clear_unknown_fields(msg) do
        struct!(msg, [{unknown_fields_name(), []}])
      end
    )

    (
      @spec required_fields() :: []
      def required_fields() do
        []
      end
    )

    (
      @spec syntax() :: atom()
      def syntax() do
        :proto3
      end
    )

    [
      @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
      def default(:lo) do
        {:ok, nil}
      end,
      def default(:hi) do
        {:ok, nil}
      end,
      def default(_) do
        {:error, :no_such_field}
      end
    ]
  end,
  defmodule Routeguide.RouteNote do
    @moduledoc false
    defstruct location: nil, message: "", __uf__: []

    (
      (
        @spec encode(struct) :: {:ok, iodata} | {:error, any}
        def encode(msg) do
          try do
            {:ok, encode!(msg)}
          rescue
            e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
          end
        end

        @spec encode!(struct) :: iodata | no_return
        def encode!(msg) do
          [] |> encode_location(msg) |> encode_message(msg) |> encode_unknown_fields(msg)
        end
      )

      []

      [
        defp encode_location(acc, msg) do
          try do
            if msg.location == nil do
              acc
            else
              [acc, "\n", Protox.Encode.encode_message(msg.location)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:location, "invalid field value"), __STACKTRACE__
          end
        end,
        defp encode_message(acc, msg) do
          try do
            if msg.message == "" do
              acc
            else
              [acc, "\x12", Protox.Encode.encode_string(msg.message)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:message, "invalid field value"), __STACKTRACE__
          end
        end
      ]

      defp encode_unknown_fields(acc, msg) do
        Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
          case wire_type do
            0 ->
              [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

            1 ->
              [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

            2 ->
              len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
              [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

            5 ->
              [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
          end
        end)
      end
    )

    (
      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def decode(bytes) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def decode!(bytes) do
            parse_key_value(bytes, struct(Routeguide.RouteNote))
          end
        )
      )

      (
        @spec parse_key_value(binary, struct) :: struct
        defp parse_key_value(<<>>, msg) do
          msg
        end

        defp parse_key_value(bytes, msg) do
          {field, rest} =
            case Protox.Decode.parse_key(bytes) do
              {0, _, _} ->
                raise %Protox.IllegalTagError{}

              {1, _, bytes} ->
                {len, bytes} = Protox.Varint.decode(bytes)
                {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

                {[
                   location:
                     Protox.MergeMessage.merge(msg.location, Routeguide.Point.decode!(delimited))
                 ], rest}

              {2, _, bytes} ->
                {len, bytes} = Protox.Varint.decode(bytes)
                {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
                {[message: delimited], rest}

              {tag, wire_type, rest} ->
                {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

                {[
                   {msg.__struct__.unknown_fields_name,
                    [value | msg.__struct__.unknown_fields(msg)]}
                 ], rest}
            end

          msg_updated = struct(msg, field)
          parse_key_value(rest, msg_updated)
        end
      )

      []
    )

    (
      @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
      def json_decode(input, opts \\ []) do
        try do
          {:ok, json_decode!(input, opts)}
        rescue
          e in Protox.JsonDecodingError -> {:error, e}
        end
      end

      @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
      def json_decode!(input, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

        Protox.JsonDecode.decode!(
          input,
          Routeguide.RouteNote,
          &json_library_wrapper.decode!(json_library, &1)
        )
      end

      @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
      def json_encode(msg, opts \\ []) do
        try do
          {:ok, json_encode!(msg, opts)}
        rescue
          e in Protox.JsonEncodingError -> {:error, e}
        end
      end

      @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
      def json_encode!(msg, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
        Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
      end
    )

    (
      @deprecated "Use fields_defs()/0 instead"
      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs() do
        %{
          1 => {:location, {:scalar, nil}, {:message, Routeguide.Point}},
          2 => {:message, {:scalar, ""}, :string}
        }
      end

      @deprecated "Use fields_defs()/0 instead"
      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs_by_name() do
        %{
          location: {1, {:scalar, nil}, {:message, Routeguide.Point}},
          message: {2, {:scalar, ""}, :string}
        }
      end
    )

    (
      @spec fields_defs() :: list(Protox.Field.t())
      def fields_defs() do
        [
          %{
            __struct__: Protox.Field,
            json_name: "location",
            kind: {:scalar, nil},
            label: :optional,
            name: :location,
            tag: 1,
            type: {:message, Routeguide.Point}
          },
          %{
            __struct__: Protox.Field,
            json_name: "message",
            kind: {:scalar, ""},
            label: :optional,
            name: :message,
            tag: 2,
            type: :string
          }
        ]
      end

      [
        @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
        (
          def field_def(:location) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "location",
               kind: {:scalar, nil},
               label: :optional,
               name: :location,
               tag: 1,
               type: {:message, Routeguide.Point}
             }}
          end

          def field_def("location") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "location",
               kind: {:scalar, nil},
               label: :optional,
               name: :location,
               tag: 1,
               type: {:message, Routeguide.Point}
             }}
          end

          []
        ),
        (
          def field_def(:message) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "message",
               kind: {:scalar, ""},
               label: :optional,
               name: :message,
               tag: 2,
               type: :string
             }}
          end

          def field_def("message") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "message",
               kind: {:scalar, ""},
               label: :optional,
               name: :message,
               tag: 2,
               type: :string
             }}
          end

          []
        ),
        def field_def(_) do
          {:error, :no_such_field}
        end
      ]
    )

    (
      @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
      def unknown_fields(msg) do
        msg.__uf__
      end

      @spec unknown_fields_name() :: :__uf__
      def unknown_fields_name() do
        :__uf__
      end

      @spec clear_unknown_fields(struct) :: struct
      def clear_unknown_fields(msg) do
        struct!(msg, [{unknown_fields_name(), []}])
      end
    )

    (
      @spec required_fields() :: []
      def required_fields() do
        []
      end
    )

    (
      @spec syntax() :: atom()
      def syntax() do
        :proto3
      end
    )

    [
      @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
      def default(:location) do
        {:ok, nil}
      end,
      def default(:message) do
        {:ok, ""}
      end,
      def default(_) do
        {:error, :no_such_field}
      end
    ]
  end,
  defmodule Routeguide.RouteSummary do
    @moduledoc false
    defstruct point_count: 0, feature_count: 0, distance: 0, elapsed_time: 0, __uf__: []

    (
      (
        @spec encode(struct) :: {:ok, iodata} | {:error, any}
        def encode(msg) do
          try do
            {:ok, encode!(msg)}
          rescue
            e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
          end
        end

        @spec encode!(struct) :: iodata | no_return
        def encode!(msg) do
          []
          |> encode_point_count(msg)
          |> encode_feature_count(msg)
          |> encode_distance(msg)
          |> encode_elapsed_time(msg)
          |> encode_unknown_fields(msg)
        end
      )

      []

      [
        defp encode_point_count(acc, msg) do
          try do
            if msg.point_count == 0 do
              acc
            else
              [acc, "\b", Protox.Encode.encode_int32(msg.point_count)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:point_count, "invalid field value"),
                      __STACKTRACE__
          end
        end,
        defp encode_feature_count(acc, msg) do
          try do
            if msg.feature_count == 0 do
              acc
            else
              [acc, "\x10", Protox.Encode.encode_int32(msg.feature_count)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:feature_count, "invalid field value"),
                      __STACKTRACE__
          end
        end,
        defp encode_distance(acc, msg) do
          try do
            if msg.distance == 0 do
              acc
            else
              [acc, "\x18", Protox.Encode.encode_int32(msg.distance)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:distance, "invalid field value"), __STACKTRACE__
          end
        end,
        defp encode_elapsed_time(acc, msg) do
          try do
            if msg.elapsed_time == 0 do
              acc
            else
              [acc, " ", Protox.Encode.encode_int32(msg.elapsed_time)]
            end
          rescue
            ArgumentError ->
              reraise Protox.EncodingError.new(:elapsed_time, "invalid field value"),
                      __STACKTRACE__
          end
        end
      ]

      defp encode_unknown_fields(acc, msg) do
        Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
          case wire_type do
            0 ->
              [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

            1 ->
              [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

            2 ->
              len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
              [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

            5 ->
              [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
          end
        end)
      end
    )

    (
      (
        @spec decode(binary) :: {:ok, struct} | {:error, any}
        def decode(bytes) do
          try do
            {:ok, decode!(bytes)}
          rescue
            e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
              {:error, e}
          end
        end

        (
          @spec decode!(binary) :: struct | no_return
          def decode!(bytes) do
            parse_key_value(bytes, struct(Routeguide.RouteSummary))
          end
        )
      )

      (
        @spec parse_key_value(binary, struct) :: struct
        defp parse_key_value(<<>>, msg) do
          msg
        end

        defp parse_key_value(bytes, msg) do
          {field, rest} =
            case Protox.Decode.parse_key(bytes) do
              {0, _, _} ->
                raise %Protox.IllegalTagError{}

              {1, _, bytes} ->
                {value, rest} = Protox.Decode.parse_int32(bytes)
                {[point_count: value], rest}

              {2, _, bytes} ->
                {value, rest} = Protox.Decode.parse_int32(bytes)
                {[feature_count: value], rest}

              {3, _, bytes} ->
                {value, rest} = Protox.Decode.parse_int32(bytes)
                {[distance: value], rest}

              {4, _, bytes} ->
                {value, rest} = Protox.Decode.parse_int32(bytes)
                {[elapsed_time: value], rest}

              {tag, wire_type, rest} ->
                {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

                {[
                   {msg.__struct__.unknown_fields_name,
                    [value | msg.__struct__.unknown_fields(msg)]}
                 ], rest}
            end

          msg_updated = struct(msg, field)
          parse_key_value(rest, msg_updated)
        end
      )

      []
    )

    (
      @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
      def json_decode(input, opts \\ []) do
        try do
          {:ok, json_decode!(input, opts)}
        rescue
          e in Protox.JsonDecodingError -> {:error, e}
        end
      end

      @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
      def json_decode!(input, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

        Protox.JsonDecode.decode!(
          input,
          Routeguide.RouteSummary,
          &json_library_wrapper.decode!(json_library, &1)
        )
      end

      @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
      def json_encode(msg, opts \\ []) do
        try do
          {:ok, json_encode!(msg, opts)}
        rescue
          e in Protox.JsonEncodingError -> {:error, e}
        end
      end

      @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
      def json_encode!(msg, opts \\ []) do
        {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
        Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
      end
    )

    (
      @deprecated "Use fields_defs()/0 instead"
      @spec defs() :: %{
              required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs() do
        %{
          1 => {:point_count, {:scalar, 0}, :int32},
          2 => {:feature_count, {:scalar, 0}, :int32},
          3 => {:distance, {:scalar, 0}, :int32},
          4 => {:elapsed_time, {:scalar, 0}, :int32}
        }
      end

      @deprecated "Use fields_defs()/0 instead"
      @spec defs_by_name() :: %{
              required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
            }
      def defs_by_name() do
        %{
          distance: {3, {:scalar, 0}, :int32},
          elapsed_time: {4, {:scalar, 0}, :int32},
          feature_count: {2, {:scalar, 0}, :int32},
          point_count: {1, {:scalar, 0}, :int32}
        }
      end
    )

    (
      @spec fields_defs() :: list(Protox.Field.t())
      def fields_defs() do
        [
          %{
            __struct__: Protox.Field,
            json_name: "pointCount",
            kind: {:scalar, 0},
            label: :optional,
            name: :point_count,
            tag: 1,
            type: :int32
          },
          %{
            __struct__: Protox.Field,
            json_name: "featureCount",
            kind: {:scalar, 0},
            label: :optional,
            name: :feature_count,
            tag: 2,
            type: :int32
          },
          %{
            __struct__: Protox.Field,
            json_name: "distance",
            kind: {:scalar, 0},
            label: :optional,
            name: :distance,
            tag: 3,
            type: :int32
          },
          %{
            __struct__: Protox.Field,
            json_name: "elapsedTime",
            kind: {:scalar, 0},
            label: :optional,
            name: :elapsed_time,
            tag: 4,
            type: :int32
          }
        ]
      end

      [
        @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
        (
          def field_def(:point_count) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "pointCount",
               kind: {:scalar, 0},
               label: :optional,
               name: :point_count,
               tag: 1,
               type: :int32
             }}
          end

          def field_def("pointCount") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "pointCount",
               kind: {:scalar, 0},
               label: :optional,
               name: :point_count,
               tag: 1,
               type: :int32
             }}
          end

          def field_def("point_count") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "pointCount",
               kind: {:scalar, 0},
               label: :optional,
               name: :point_count,
               tag: 1,
               type: :int32
             }}
          end
        ),
        (
          def field_def(:feature_count) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "featureCount",
               kind: {:scalar, 0},
               label: :optional,
               name: :feature_count,
               tag: 2,
               type: :int32
             }}
          end

          def field_def("featureCount") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "featureCount",
               kind: {:scalar, 0},
               label: :optional,
               name: :feature_count,
               tag: 2,
               type: :int32
             }}
          end

          def field_def("feature_count") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "featureCount",
               kind: {:scalar, 0},
               label: :optional,
               name: :feature_count,
               tag: 2,
               type: :int32
             }}
          end
        ),
        (
          def field_def(:distance) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "distance",
               kind: {:scalar, 0},
               label: :optional,
               name: :distance,
               tag: 3,
               type: :int32
             }}
          end

          def field_def("distance") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "distance",
               kind: {:scalar, 0},
               label: :optional,
               name: :distance,
               tag: 3,
               type: :int32
             }}
          end

          []
        ),
        (
          def field_def(:elapsed_time) do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "elapsedTime",
               kind: {:scalar, 0},
               label: :optional,
               name: :elapsed_time,
               tag: 4,
               type: :int32
             }}
          end

          def field_def("elapsedTime") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "elapsedTime",
               kind: {:scalar, 0},
               label: :optional,
               name: :elapsed_time,
               tag: 4,
               type: :int32
             }}
          end

          def field_def("elapsed_time") do
            {:ok,
             %{
               __struct__: Protox.Field,
               json_name: "elapsedTime",
               kind: {:scalar, 0},
               label: :optional,
               name: :elapsed_time,
               tag: 4,
               type: :int32
             }}
          end
        ),
        def field_def(_) do
          {:error, :no_such_field}
        end
      ]
    )

    (
      @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
      def unknown_fields(msg) do
        msg.__uf__
      end

      @spec unknown_fields_name() :: :__uf__
      def unknown_fields_name() do
        :__uf__
      end

      @spec clear_unknown_fields(struct) :: struct
      def clear_unknown_fields(msg) do
        struct!(msg, [{unknown_fields_name(), []}])
      end
    )

    (
      @spec required_fields() :: []
      def required_fields() do
        []
      end
    )

    (
      @spec syntax() :: atom()
      def syntax() do
        :proto3
      end
    )

    [
      @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
      def default(:point_count) do
        {:ok, 0}
      end,
      def default(:feature_count) do
        {:ok, 0}
      end,
      def default(:distance) do
        {:ok, 0}
      end,
      def default(:elapsed_time) do
        {:ok, 0}
      end,
      def default(_) do
        {:error, :no_such_field}
      end
    ]
  end
]
