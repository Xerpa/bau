if Code.ensure_loaded?(Joken) &&
     Code.ensure_loaded?(JokenJwks) do
  defmodule Bau.Xerpa.TokenStrategy do
    use JokenJwks.DefaultStrategyTemplate

    @moduledoc """
    Custom JWKs URL (Xerpay Auth Platform)
    """

    def init_opts(opts) do
      url = "#{fetch_auth_iss()}/.well-known/jwks.json"
      Keyword.merge(opts, jwks_url: url)
    end

    defp fetch_auth_iss, do: Application.get_env(:bau, :jwt_config)[:iss]
  end
end
