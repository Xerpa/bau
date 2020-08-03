defmodule Bau.Xerpa.SlackNotifier do
  use Tesla

  def notify(message, webhook_url) do
    spawn(fn ->
      Tesla.post(Tesla.client([Tesla.Middleware.JSON]), webhook_url, %{text: message})
    end)
  end
end
