defmodule Bau.Xerpa.JWT do
  @default_iss_claim "https://login.xerpa.com/"
  @default_sig_algo "HS512"
  @default_enc_algo %{"alg" => "dir", "enc" => "A128CBC-HS256"}

  @type option ::
          {:timestamp, DateTime.t()}
          | {:enc_algo, map}
          | {:sig_algo, map()}
          | {:claim_iss, String.t()}

  @spec decode(String.t(), String.t() | [String.t()], String.t() | [String.t()], [option]) ::
          {:ok, map}
          | {:error, :bad_signature}
          | {:error, :bad_encryption}
          | {:error, :bad_claim}
          | {:error, {:bad_claim, atom, map}}
  def decode(token, sig_key_or_keys, enc_key_or_keys, options \\ [])

  def decode(token, sig_key, enc_key, options)
      when is_binary(token) and is_binary(sig_key) and is_binary(enc_key) do
    iss_claim = Keyword.get(options, :claim_iss, @default_iss_claim)
    time_now = Keyword.get(options, :timestamp, DateTime.utc_now())
    sig_algo = Keyword.get(options, :sig_algo, @default_sig_algo)
    enc_algo = Keyword.get(options, :enc_algo, @default_enc_algo)

    sig_key = JOSE.JWK.from_oct(sig_key)
    enc_key = JOSE.JWK.from_oct(:base64url.decode(enc_key))
    %JOSE.JWE{alg: enc_alg, enc: enc_meth} = JOSE.JWE.from(enc_algo)

    with {:sig, {true, enc_data, %JOSE.JWS{}}} <-
           {:sig, JOSE.JWS.verify_strict(sig_key, [sig_algo], token)},
         {:enc, {data, %JOSE.JWE{alg: ^enc_alg, enc: ^enc_meth}}} <-
           {:enc, JOSE.JWE.block_decrypt(enc_key, enc_data)},
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
    sig_keys = sig_keys |> List.wrap() |> Enum.filter(&is_binary/1)
    enc_keys = enc_keys |> List.wrap() |> Enum.filter(&is_binary/1)

    case {[] == sig_keys, [] == enc_keys} do
      {true, _} ->
        {:error, :bad_signature}

      {_, true} ->
        {:error, :bad_encryption}

      {false, false} ->
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
