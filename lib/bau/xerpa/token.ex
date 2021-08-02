defmodule Bau.Xerpa.Token do
  use Joken.Config

  @moduledoc """
  Custom JWT Config
  """

  if Mix.env() != :test do
    add_hook(JokenJwks, strategy: Bau.Xerpa.TokenStrategy)
  end

  @impl true
  def token_config do
    [iss: iss, aud: aud] = fetch_auth_config()

    default_claims(skip: [:aud, :iss])
    |> add_claim("iss", nil, &(&1 == iss))
    |> add_claim("aud", nil, &(&1 == aud))
  end

  defp fetch_auth_config, do: Application.get_env(:bau, :jwt_config)
end
