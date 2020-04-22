defmodule Bau.Xerpa.Enum do
  @doc false
  defmacro __using__(opts) do
    type_name = Keyword.get(opts, :name)
    struct_def = Keyword.get(opts, :struct, ~w(code name translation)a)

    import_only =
      case Keyword.get(opts, :import_only, []) do
        [] -> []
        imports -> [only: imports]
      end

    quote do
      import Bau.Xerpa.Enum, unquote(import_only)

      @type t :: %__MODULE__{}

      defstruct unquote(struct_def)

      Module.eval_quoted(__ENV__, [
        Bau.Xerpa.Enum.__derive_protocols__(__MODULE__),
        Bau.Xerpa.Enum.__define_name__(__MODULE__, unquote(type_name))
      ])

      Module.register_attribute(__MODULE__, :enum_values, accumulate: true)
      @before_compile Bau.Xerpa.Enum
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    escaped_values = Module.get_attribute(env.module, :enum_values)

    quote do
      @spec values :: [t]
      def values, do: unquote(escaped_values)
      def from_code(_), do: :error
      def from_name(_), do: :error
      def codes, do: unquote(env.module).values() |> Enum.map(fn enum -> enum.code end)
    end
  end

  defmacro defvalue(name, code, translation \\ nil, opts \\ [])

  defmacro defvalue(:name, _code, _translation, _opts),
    do: raise(ArgumentError, message: "Enum value cannot be called :name")

  defmacro defvalue(name, code, translation, opts) do
    quote do
      value_definition =
        Bau.Xerpa.Enum.__def_value__(
          __MODULE__,
          unquote(name),
          unquote(code),
          unquote(translation),
          unquote(opts)
        )

      Module.eval_quoted(__ENV__, value_definition)
    end
  end

  @doc false
  def __def_value__(mod, name, code, translation, opts) do
    struct_definition = %{__struct__: mod, name: name, code: code, translation: translation}

    create_value(mod, code, name, struct_definition, opts)
  end

  def create_value(mod, code, name, struct_definition, opts) do
    escaped_value = Macro.escape(struct_definition)

    unless opts[:hidden] do
      Module.put_attribute(mod, :enum_values, escaped_value)
    end

    [
      quote do
        def unquote(name)(), do: unquote(escaped_value)
      end,
      quote_with_string_arg(:from_code, code, escaped_value),
      quote_with_string_arg(:from_name, name, escaped_value)
    ]
  end

  def quote_with_string_arg(name, arg, value) when is_binary(arg) do
    quote do
      def unquote(name)(unquote(arg)), do: {:ok, unquote(value)}
    end
  end

  def quote_with_string_arg(name, arg, value) do
    str_arg = to_string(arg)

    quote do
      def unquote(name)(unquote(arg)), do: {:ok, unquote(value)}
      def unquote(name)(unquote(str_arg)), do: {:ok, unquote(value)}
    end
  end

  defmacro ecto_type(type \\ :integer) do
    quote do
      ecto_type_definition = Bau.Xerpa.Enum.__define_ecto_type__(__MODULE__, unquote(type))

      Module.eval_quoted(__ENV__, ecto_type_definition)
    end
  end

  @doc false
  def __define_ecto_type__(mod, type) do
    unless type in [:string, :integer] do
      raise "Only `:string` and `:integer` are supported by our crazy macro"
    end

    quote do
      use Ecto.Type

      @type code_t :: String.t() | integer | nil
      @type ok_of(y) :: {:ok, y} | :error

      @spec type :: atom
      def type, do: unquote(type)

      @spec cast(t | code_t) :: ok_of(t)
      def cast(value = %unquote(mod){}), do: {:ok, value}
      def cast(nil), do: {:ok, nil}
      def cast(code), do: from_code(code)

      @spec dump(t | nil) :: ok_of(code_t)
      def dump(nil), do: {:ok, nil}

      def dump(value) do
        with {:ok, _} <- from_code(value.code) do
          {:ok, value.code}
        end
      end

      @spec load(code_t) :: ok_of(t)
      def load(code), do: cast(code)
    end
  end

  @doc false
  def __derive_protocols__(mod) do
    quote do
      defimpl Poison.Encoder, for: unquote(mod) do
        def encode(value, opts), do: Poison.Encoder.encode(value.code, opts)
      end

      defimpl Inspect, for: unquote(mod) do
        def inspect(value, _) do
          "#{unquote(mod)}<#{value.name}>" |> String.trim_leading("Elixir.")
        end
      end
    end
  end

  @doc false
  def __define_name__(mod, nil) do
    default_name =
      mod |> Macro.underscore() |> String.split("/") |> List.last() |> String.downcase()

    quote do: def(name, do: unquote(default_name))
  end

  def __define_name__(_, name) do
    quote do: def(name, do: unquote(name))
  end
end
