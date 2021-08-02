use Mix.Config

config :tesla, adapter: Tesla.Mock

config :joken,
  default_signer: [
    signer_alg: "RS256",
    key_map: %{
      "p" =>
        "3vCEQtaa74YLVLeMrvTCqSHOcsxiYhW1WGHnKuPmBbexcGGcZDSI0FtEezePEL87GlN5H85LLgOUakDKkV65EA4lLG7qjAxA53q8JkMxJsl5bRrP0RZEK_xbfmke1632QeDoKcYeEP95gFANb6iA1kTNlZ3dsvVKSzwZfx9R7oU",
      "kty" => "RSA",
      "q" =>
        "x5tS8Ujmd4DMa2l2KgIOECxMCfY9DeV4hXxkSaf_IGkubDBOIlVosuIU-MP2xoziiHvPKlFmyDtAqUs5wO_HS2R2mgDBGmY-EkLPswWlnZOlWVtJqq4x8Zd-SkrA2wzYT0mAwQCQdSA6YbHjnFabaV70yoSt3oGU5hC-yG3Sf-0",
      "d" =>
        "Mm6ujtkpEBekloQGzoUDQcHne3k2kTCJklOSFC6yA6I3FVrSpc4YcNzOjBU5TWao4-uLcuQBJZigLPbDwqm-eVCO4lVoZ4Y6_IsXeImvBlKHPPwQ1zYiYh_lH66pQTWg7LIgAMpG-d3RBHNRZ5A5p7N1GOkUsNsoFQ0xlyLlScDjRRZOa_RDyElvQ21D6LHfHeBtAJ1YCgtptu51QftHtRs9zSZSLVwVm2XJMwAf3vxhRZXJ_UXhgZPEJhMVZCuGet9W175IVAFCw7w0M1L3cqxgoLAL6PfCGUPIYEiGIGdEgakkykOSa3RHafuDX6VG7f3X9beem6lvhGDDSp9-IQ",
      "e" => "AQAB",
      "use" => "sig",
      "kid" => "aoUwbBcYUrDqllbsX5UQHXHr5s5Ph0Whj9caybcsZ_c",
      "qi" =>
        "UP3St84fE0aNZSic9nyQCNbKSrfgW4r8IeTD74cDZ0jatYuA1pIco4W5bzWzqeS1cVtV-N_2Z13TLCmvW5oSESnr0dYhYg3NJ0cs9-xKA6admT4efHLY-ZxOP5-5vC328P_LY7P8eeD_sfsWp3rmb0LidirUO4BJYqlFUBmKdLI",
      "dp" =>
        "gDAFrLTfA4isrTqZHuRHpZ51qZaRn1piGn64v_WohnMYCMlndkqqvDsuRjctAPEkF8AVbk9c9QlD5lB46Vtwx6WKhGEGZh6Jl1AALXQHKAlC05ROGChYbH4_UZE6FcPGTBz5AUQUd6ud_kSJZUGbSxjmqPfLySG3ZUkaU_j7UE0",
      "alg" => "RS256",
      "dq" =>
        "PdiggGZIEmrz66wHksiENvqirMuA61dYWnPKVxAYeqBcY-UrsHOqNxLZ0KJXSfnJDuTdsYz7PbsuM8Y9JMymgXOlU9479sQLI3lUBXIQeJyQtPkWAC5tByAbX0V-L-Dw_NAXdrWIDOJpdG-7yGsFSEbFriIiBTk9O3OgyVVNzZk",
      "n" =>
        "rdQ6qzOQpQV5tu1NnMvrTZgFx_I9lrOJO_ukqJOlcnjVXjD0S4PJYH-FVIW9oc6Xh2yk4hN-_B6PRp3b4epPzO6wMuWe9zrsn2KU9UV-eoqJRR0UUg-xe5nhdV_LOGXsKKXUQU2TNvhBu9Lyw3ZBUz96myHDAiAOb5rXiElo_8sb8y7K0CHjD_XuIfzVb6LdHYUh1wndIxr11qZPsEgMr-Y6jWTZJfAnAYIfJPtrFy38BSbW_vn6AgwPBV5w1Rj22g_GbIIaGtdjlDm-8WvEd3P26xTw1cV1WR7EedSHXKj9DMIGvu51hfuaP859fBb6gcKeAiwx_yAvQEzl7kfMIQ"
    }
  ]

config :bau, :jwt_config,
  iss: "Teste ISS",
  aud: "Teste AUD"
