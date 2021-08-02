defmodule Bau.Xerpa.TokenTest do
  use ExUnit.Case, async: true

  alias Bau.Xerpa.Token

  describe "token_config/0" do
    test "returns custom iss and aud config" do
      %{"iss" => iss, "aud" => aud} = Token.token_config()

      assert true == iss.validate().("Teste ISS", %{}, %{})
      assert true == aud.validate().("Teste AUD", %{}, %{})
    end
  end
end
