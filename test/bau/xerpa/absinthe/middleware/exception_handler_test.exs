defmodule Bau.Xerpa.Absinthe.Middleware.ExceptionHandlerTest do
  use ExUnit.Case, async: true

  defmodule TestSchema do
    use Absinthe.Schema

    alias Bau.Xerpa.Absinthe.Middleware.ExceptionHandler

    defp on_error_fn(resolution = %{context: %{echo_fn: echo_fn}}, exception, stacktrace) do
      echo_fn.(resolution, exception, stacktrace)

      resolution
    end

    def middleware(middleware, _field, %Absinthe.Type.Object{identifier: :query}) do
      Enum.map(middleware, fn m -> ExceptionHandler.wrap(m, on_error: &on_error_fn/3) end)
    end

    def middleware(middleware, _field, _object), do: middleware

    query do
      field :success, :boolean do
        resolve(fn _, _, _ ->
          {:ok, true}
        end)
      end

      field :failure, :boolean do
        resolve(fn _, _, _ ->
          {:error, :some_error}
        end)
      end

      field :exception, :boolean do
        resolve(fn _, _, _ ->
          raise "boom"
        end)
      end
    end
  end

  alias Bau.Xerpa.Absinthe.Middleware.ExceptionHandlerTest.TestSchema

  setup do
    this = self()

    echo_fn = fn resolution, exception, stacktrace ->
      send(
        this,
        {:called,
         %{
           resolution: resolution,
           exception: exception,
           stacktrace: stacktrace
         }}
      )
    end

    {:ok, %{echo_fn: echo_fn}}
  end

  test "does not call handler on success response", %{echo_fn: echo_fn} do
    assert Absinthe.run!("query { success }", TestSchema, context: %{echo_fn: echo_fn}) == %{
             data: %{"success" => true}
           }

    refute_receive {:called, _}
  end

  test "does not call handler on error response", %{echo_fn: echo_fn} do
    assert %{
             data: %{"failure" => nil},
             errors: [error]
           } = Absinthe.run!("query { failure }", TestSchema, context: %{echo_fn: echo_fn})

    assert %{locations: [%{column: _, line: _}], message: "some_error", path: ["failure"]} = error

    refute_receive {:called, _}
  end

  test "calls handler on unhandled exceptions", %{echo_fn: echo_fn} do
    assert %{
             data: %{"exception" => nil},
             errors: [error]
           } = Absinthe.run!("query { exception }", TestSchema, context: %{echo_fn: echo_fn})

    assert %{
             locations: [%{column: _, line: _}],
             message: "internal server error",
             path: ["exception"]
           } = error

    assert_receive {:called,
                    %{
                      resolution: %Absinthe.Resolution{},
                      exception: %RuntimeError{},
                      stacktrace: stacktrace
                    }}

    assert "" <> _ = Exception.format_stacktrace(stacktrace)
  end
end
