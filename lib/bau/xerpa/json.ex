defmodule Bau.Xerpa.JSON do
  cond do
    Code.ensure_loaded?(Jason) ->
      @json_provider Jason

    Code.ensure_loaded?(Poison) ->
      @json_provider Poison
  end

  def encode!(json_node), do: apply(@json_provider, :encode!, [json_node])
  def encode(json_node), do: apply(@json_provider, :encode, [json_node])

  def decode!(text), do: apply(@json_provider, :decode!, [text])
  def decode(text), do: apply(@json_provider, :decode, [text])
end
