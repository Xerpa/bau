defmodule Bau.Xerpa.Stacktrace do
  defmacro get do
    current_elixir_version = Version.parse!(System.version())
    stacktrace_macro_version = Version.parse!("1.7.0")

    if Version.compare(current_elixir_version, stacktrace_macro_version) == :lt do
      quote do
        System.stacktrace()
      end
    else
      quote do
        __STACKTRACE__
      end
    end
  end
end
