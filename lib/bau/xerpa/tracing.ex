defmodule Bau.Xerpa.Tracing do
  require Logger

  def get_request_id() do
    Logger.metadata()[:request_id]
  end

  def put_request_id(request_id) do
    Logger.metadata(request_id: request_id)
  end
end
