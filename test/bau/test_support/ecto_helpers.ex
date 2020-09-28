defmodule Bau.TestSupport.EctoHelpers do
  def ecto3?() do
    with {:ok, vsn} <- :application.get_key(:ecto, :vsn) do
      vsn = List.to_string(vsn)
      Version.match?(vsn, "~> 3.0")
    else
      _ -> false
    end
  end
end
