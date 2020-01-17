defmodule Bau.Xerpa.Tesla.Middleware.RequestIdForwarder do
  @behaviour Tesla.Middleware

  def call(env, next, _opts) do
    with {true, dict} <- Process.get(:logger_metadata),
         "" <> request_id <- Keyword.get(dict, :request_id) do
      env
      |> Tesla.put_header("x-request-id", request_id)
      |> Tesla.run(next)
    else
      _ -> Tesla.run(env, next)
    end
  end
end
