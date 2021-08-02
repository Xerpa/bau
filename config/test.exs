use Mix.Config

config :tesla, adapter: Tesla.Mock

config :bau, :jwt_config,
  iss: "Teste ISS",
  aud: "Teste AUD"
