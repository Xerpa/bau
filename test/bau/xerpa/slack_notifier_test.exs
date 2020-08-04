defmodule Bau.Xerpa.SlackNotifierTest do
  use ExUnit.Case

  alias Bau.Xerpa.SlackNotifier

  import Tesla.Mock

  test "notify a message" do
    mock(fn %{method: :post, body: body} ->
      %Tesla.Env{
        status: 200,
        body: body
      }
    end)

    message = "notifyme sir"
    webhook_url = "https://slackapi/webhook_url"

    {:ok, %{body: body}} = SlackNotifier.notify(message, webhook_url)

    assert Jason.decode!(body) == %{"text" => "notifyme sir"}
  end
end
