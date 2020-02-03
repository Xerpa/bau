defmodule Bau.Xerpa.Tesla.Middleware.RequestIdForwarder do
  @behaviour Tesla.Middleware

  alias Bau.Xerpa.Tracing

  def call(env, next, _opts) do
    with "" <> request_id <- Tracing.get_request_id() do
      env
      |> Tesla.put_header("x-request-id", request_id)
      |> Tesla.run(next)
    else
      _ -> Tesla.run(env, next)
    end
  end
end
