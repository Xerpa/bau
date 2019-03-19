defmodule Bau.Xerpa.JWT do
  @default_iss_claim "https://login.xerpa.com/"
  @default_sig_algo "RS256"
  @default_enc_algo %{"alg" => "dir", "enc" => "A128CBC-HS256"}

  @type option ::
          {:timestamp, DateTime.t()}
          | {:enc_algo, map}
          | {:sig_algo, map()}
          | {:claim_iss, String.t()}

  @type key :: key1 | [key1]

  @type key1 :: key_map | key_string
  @type key_map :: %{}
  @type key_string :: String.t()

  @spec encode(map, key_map, key_string, [option]) :: {:ok, String.t()} | :error
  def encode(claims, sig_key, enc_key, options \\ []) do
    sig_key = JOSE.JWK.from_map(sig_key)
    enc_key = enc_key && JOSE.JWK.from_oct(:base64url.decode(enc_key))
    sig_algo = %{"alg" => Keyword.get(options, :sig_algo, @default_sig_algo)}
    enc_algo = Keyword.get(options, :enc_algo, @default_enc_algo)

    time_now = DateTime.to_unix(Keyword.get(options, :timestamp, DateTime.utc_now()))
    expires_in = Keyword.get(options, :expires_in_secs, 3600)
    iss_claim = Keyword.get(options, :claim_iss, @default_iss_claim)

    claims =
      claims
      |> Map.put_new(:iss, iss_claim)
      |> Map.put_new(:iat, time_now)
      |> Map.put_new(:exp, time_now + expires_in)
      |> Poison.encode!()

    with {:ok, enc_binary} <- try_encrypt(claims, enc_key, enc_algo),
         {%{}, sig_payload = %{}} <- JOSE.JWS.sign(sig_key, enc_binary, sig_algo),
         {%{}, sig_binary} <- JOSE.JWS.compact(sig_payload) do
      {:ok, sig_binary}
    else
      _ -> :error
    end
  end

  @spec decode(String.t(), key, key, [option]) ::
          {:ok, map}
          | {:error, :bad_signature}
          | {:error, :bad_encryption}
          | {:error, :bad_claim}
          | {:error, {:bad_claim, atom, map}}
  def decode(token, sig_key_or_keys, enc_key_or_keys, options \\ [])

  def decode(token, sig_key, enc_key, options)
      when is_binary(token) and is_map(sig_key) and (is_binary(enc_key) or is_nil(enc_key)) do
    iss_claim = Keyword.get(options, :claim_iss, @default_iss_claim)
    time_now = Keyword.get(options, :timestamp, DateTime.utc_now())
    sig_algo = Keyword.get(options, :sig_algo, @default_sig_algo)
    enc_algo = Keyword.get(options, :enc_algo, @default_enc_algo)

    sig_key = JOSE.JWK.from_map(sig_key)
    enc_key = enc_key && JOSE.JWK.from_oct(:base64url.decode(enc_key))
    %JOSE.JWE{alg: enc_alg, enc: enc_meth} = JOSE.JWE.from(enc_algo)

    with {:sig, {true, enc_data, %JOSE.JWS{}}} <-
           {:sig, JOSE.JWS.verify_strict(sig_key, [sig_algo], token)},
         {:enc, {:ok, data}} <- {:enc, try_decrypt(enc_data, enc_key, enc_alg, enc_meth)},
         {:json, {:ok, claims}} <- {:json, Poison.decode(data)},
         {_, {_, _, true}} <- {:claim, {:exp, claims, check_exp(claims, time_now)}},
         {_, {_, _, true}} <- {:claim, {:iat, claims, check_iat(claims, time_now)}},
         {_, {_, _, true}} <- {:claim, {:iss, claims, check_iss(claims, iss_claim)}} do
      {:ok, claims}
    else
      {:sig, _} -> {:error, :bad_signature}
      {:enc, _} -> {:error, :bad_encryption}
      {:json, _} -> {:error, :bad_claim}
      {:claim, {field, claims, _}} -> {:error, {:bad_claim, field, claims}}
    end
  end

  def decode(token, sig_keys, enc_keys, options) when is_binary(token) do
    sig_keys = sig_keys |> List.wrap() |> Enum.filter(&is_map/1)
    enc_keys = enc_keys |> List.wrap() |> Enum.filter(&is_binary/1)
    no_encryption = Keyword.get(options, :no_encryption, false)

    case {[] == sig_keys, [] == enc_keys, no_encryption} do
      {true, _, _} ->
        {:error, :bad_signature}

      {_, true, false} ->
        {:error, :bad_encryption}

      {false, _, true} ->
        Enum.reduce_while(sig_keys, :not_used, fn sig_key, _ ->
          case decode(token, sig_key, nil, options) do
            e = {:error, :bad_signature} ->
              {:cont, e}

            e ->
              {:halt, e}
          end
        end)

      {false, false, false} ->
        Enum.reduce_while(sig_keys, :not_used, fn sig_key, acc ->
          Enum.reduce_while(enc_keys, {:cont, acc}, fn enc_key, _acc ->
            case decode(token, sig_key, enc_key, options) do
              e = {:error, :bad_signature} ->
                {:halt, {:cont, e}}

              e = {:error, :bad_encryption} ->
                {:cont, {:halt, e}}

              e ->
                {:halt, {:halt, e}}
            end
          end)
        end)
    end
  end

  defp try_decrypt(data, nil, _, _), do: {:ok, data}

  defp try_decrypt(enc_data, enc_key, enc_alg, enc_meth) do
    case JOSE.JWE.block_decrypt(enc_key, enc_data) do
      {data, %JOSE.JWE{alg: ^enc_alg, enc: ^enc_meth}} when is_binary(data) ->
        {:ok, data}

      _ ->
        :error
    end
  end

  defp try_encrypt(claims, nil, _), do: {:ok, claims}

  defp try_encrypt(claims, enc_key, enc_algo) do
    with {%{}, enc_payload = %{}} <- JOSE.JWE.block_encrypt(enc_key, claims, enc_algo),
         {%{}, enc_binary} <- JOSE.JWE.compact(enc_payload) do
      {:ok, enc_binary}
    else
      _ -> :error
    end
  end

  defp check_exp(claims, time_now) do
    timestamp = DateTime.to_unix(time_now)

    case Map.fetch(claims, "exp") do
      {:ok, exp} when is_integer(exp) ->
        exp >= timestamp

      :error ->
        false
    end
  end

  defp check_iat(claims, time_now) do
    jitter = 300
    timestamp = DateTime.to_unix(time_now)

    case Map.fetch(claims, "iat") do
      {:ok, iat} when is_integer(iat) ->
        timestamp >= iat - jitter

      :error ->
        false
    end
  end

  defp check_iss(claims, exp_iss) do
    case Map.fetch(claims, "iss") do
      {:ok, iss} ->
        iss = URI.parse(iss)
        exp_iss = URI.parse(exp_iss)

        Enum.all?(Map.from_struct(exp_iss), fn {k, v} ->
          case Map.fetch(iss, k) do
            {:ok, v1} ->
              if k == :path do
                is_nil(v) or (not is_nil(v1) and String.starts_with?(v1, v))
              else
                is_nil(v) or v == v1
              end

            :error ->
              false
          end
        end)

      :error ->
        false
    end
  end
end
