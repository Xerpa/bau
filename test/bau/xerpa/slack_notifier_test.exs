defmodule Bau.Xerpa.SlackNotifierTest do
  use ExUnit.Case

  alias Bau.Xerpa.SlackNotifier

  import Tesla.Mock

  test "notify a message" do
    parent = self()

    mock_global(fn %{method: :post, body: body} ->
      send(parent, {:ok, body})

      %Tesla.Env{
        status: 200
      }
    end)

    message = "notifyme sir"
    webhook_url = "https://slackapi/webhook_url"

    SlackNotifier.notify(message, webhook_url)
    assert_receive {:ok, body}

    assert Jason.decode!(body) == %{"text" => "notifyme sir"}
  end
end
