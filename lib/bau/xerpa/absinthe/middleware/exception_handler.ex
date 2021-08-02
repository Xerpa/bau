if Code.ensure_loaded?(Absinthe) do
  defmodule Bau.Xerpa.Absinthe.Middleware.ExceptionHandler do
    @behaviour Absinthe.Middleware

    @moduledoc """
    Absinthe does not call middlewares further down the chain when one
    middleware call raises an exception. This hinders instrumentation such
    as terminating an Appsignal transaction or sending timing metrics to
    StatsD.

    With this handler, exceptions are caught and arbitrary handling can be
    provided. Also, the middleware pipeline continues, allowing clean up
    functions to be called.

    How to use:

    ```elixir
    def middleware(middleware, _field, %Absinthe.Type.Object{identifier:
    identifier}) when identifier in [:query, :mutation, :subscription] do
    Enum.map(middleware, fn m -> ExceptionHandler.wrap(m, on_error: &your_error_handler/2) end)
    end

    def middleware(middleware, _field, _object), do: middleware
    ```

    ... where `your_error_handler/2` has type `(%Absinthe.Resolution{}, term()) -> %Absinthe.Resolution{}`.
    """

    defmacrop get_stacktrace() do
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

    @impl true
    def call(resolution, opts) do
      spec = Keyword.fetch!(opts, :spec)

      on_error_fn =
        Keyword.get(opts, :on_error, fn resolution, _error, _stacktrace ->
          resolution
        end)

      try do
        execute(spec, resolution)
      rescue
        error ->
          stacktrace = get_stacktrace()

          resolution
          |> on_error_fn.(error, stacktrace)
          |> Absinthe.Resolution.put_result({:error, "internal server error"})
      end
    end

    def wrap(spec) do
      {__MODULE__, spec: spec}
    end

    def wrap(spec, on_error: on_error_fn) when is_function(on_error_fn, 3) do
      {__MODULE__, spec: spec, on_error: on_error_fn}
    end

    defp execute({{module, function}, config}, resolution) do
      apply(module, function, [resolution, config])
    end

    defp execute({module, config}, resolution) do
      apply(module, :call, [resolution, config])
    end

    defp execute(module, resolution) when is_atom(module) do
      apply(module, :call, [resolution, []])
    end

    defp execute(function, resolution) when is_function(function, 2) do
      function.(resolution, [])
    end
  end
end
