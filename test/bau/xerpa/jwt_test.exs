defmodule Bau.Xerpa.JWTTest do
  use ExUnit.Case

  import Bau.Xerpa.JWT

  describe "jwt" do
    setup [:default_setup]

    test "encode . decode", %{options: options, enc_key: enc_key, sig_key: sig_key} do
      assert {:ok, jwt} = encode(%{}, sig_key, enc_key, options)

      timestamp = DateTime.to_unix(options[:timestamp])

      assert {:ok,
              %{
                "exp" => timestamp + options[:expires_in_secs],
                "iat" => timestamp,
                "iss" => options[:claim_iss]
              }} == decode(jwt, sig_key, enc_key, options)
    end

    test "iss validation", %{options: options, enc_key: enc_key, sig_key: sig_key} do
      assert {:ok, jwt} = encode(%{}, sig_key, enc_key, options)

      new_options = Keyword.put(options, :claim_iss, "https://iss.invalid")
      assert {:error, {:bad_claim, :iss, %{}}} = decode(jwt, sig_key, enc_key, new_options)

      new_options = Keyword.put(options, :claim_iss, "https://localhost.localdomain/bad-prefix")
      assert {:error, {:bad_claim, :iss, %{}}} = decode(jwt, sig_key, enc_key, new_options)
    end

    test "exp validation", %{options: options, enc_key: enc_key, sig_key: sig_key} do
      new_options = Keyword.put(options, :expires_in_secs, -300)
      assert {:ok, jwt} = encode(%{}, sig_key, enc_key, new_options)

      assert {:error, {:bad_claim, :exp, %{}}} = decode(jwt, sig_key, enc_key, options)
    end

    test "iat validation", %{options: options, enc_key: enc_key, sig_key: sig_key} do
      expires_in_secs = 600 + DateTime.to_unix(DateTime.utc_now())

      new_options =
        options
        |> Keyword.put(:timestamp, DateTime.from_unix!(expires_in_secs))
        |> Keyword.put(:expires_in_secs, expires_in_secs)

      assert {:ok, jwt} = encode(%{}, sig_key, enc_key, new_options)

      assert {:error, {:bad_claim, :iat, %{}}} = decode(jwt, sig_key, enc_key, options)
    end

    test "bad signature/encryption", %{options: options, enc_key: enc_key, sig_key: sig_key} do
      assert {:ok, jwt} = encode(%{}, sig_key, enc_key, options)
      assert {:error, :bad_signature} == decode(jwt, new_sig_key(), enc_key, options)
      assert {:error, :bad_encryption} == decode(jwt, sig_key, new_enc_key(), options)
    end

    test "key rotation", %{options: options, enc_key: enc_key, sig_key: sig_key} do
      assert {:ok, jwt} = encode(%{}, sig_key, enc_key, options)
      assert {:ok, jwt1} = decode(jwt, sig_key, enc_key, options)
      assert {:ok, ^jwt1} = decode(jwt, [sig_key, new_sig_key()], enc_key, options)
      assert {:ok, ^jwt1} = decode(jwt, [new_sig_key(), sig_key], enc_key, options)
      assert {:ok, ^jwt1} = decode(jwt, sig_key, [enc_key, new_enc_key()], options)
      assert {:ok, ^jwt1} = decode(jwt, sig_key, [new_enc_key(), enc_key], options)
    end
  end

  defp default_setup(_env) do
    options = [
      claim_iss: "https://localhost.localdomain",
      timestamp: DateTime.utc_now(),
      expires_in_secs: 3600
    ]

    {:ok,
     [
       options: options,
       sig_key: new_sig_key(),
       enc_key: new_enc_key()
     ]}
  end

  defp new_sig_key do
    :base64url.encode(:crypto.strong_rand_bytes(64))
  end

  defp new_enc_key do
    :base64url.encode(:crypto.strong_rand_bytes(32))
  end
end
