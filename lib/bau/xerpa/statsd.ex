defmodule Bau.Xerpa.StatsD do
  @moduledoc """
  Formats and sends metrics for StatsD.

  To configure, add this to `config.exs` or similar:

  ```
  config :bau, :statsd,
    host: "127.0.0.1",
    port: 8125
  ```
  """

  def send_metrics(metrics, config \\ Application.get_env(:bau, :statsd))

  def send_metrics(metrics, config) when is_list(metrics) do
    to_send = Enum.join(metrics, "\n")

    with {:ok, address} <- Keyword.fetch(config, :host),
         true <- is_binary(address) || {:error, :invalid_host},
         {:ok, port} <- Keyword.fetch(config, :port),
         true <- is_integer(port) || {:error, :invalid_port},
         {:ok, socket} <- :gen_udp.open(0) do
      try do
        :gen_udp.send(socket, to_charlist(address), port, to_send)
      after
        :gen_udp.close(socket)
      end
    end
  end

  def send_metrics("" <> metric, config) do
    send_metrics([metric], config)
  end

  def counter("" <> bucket, count, opts \\ []) when is_integer(count) and count >= 0 do
    sampling_freq = get_sampling_freq(opts)

    "#{bucket}:#{count}|c#{sampling_freq}"
  end

  def gauge("" <> bucket, opts \\ []) do
    inc = Keyword.get(opts, :inc)
    dec = Keyword.get(opts, :dec)
    now = Keyword.get(opts, :now)

    defined = Enum.count([inc, dec, now], &(not is_nil(&1)))

    cond do
      defined != 1 ->
        nil

      now && now >= 0 ->
        "#{bucket}:#{now}|g"

      now && now < 0 ->
        "#{bucket}:0|g\n#{bucket}:#{now}|g"

      inc && inc >= 0 ->
        "#{bucket}:+#{inc}|g"

      dec && dec >= 0 ->
        "#{bucket}:-#{dec}|g"

      :otherwise ->
        nil
    end
  end

  def timing("" <> bucket, value, unit, opts \\ [])
      when unit in [:ms, :h] and is_integer(value) and value >= 0 do
    sampling_freq = get_sampling_freq(opts)

    "#{bucket}:#{value}|#{unit}#{sampling_freq}"
  end

  def sets("" <> bucket, value) when is_binary(value) or is_integer(value) do
    "#{bucket}:#{value}|s"
  end

  defp get_sampling_freq(opts) do
    sampling = Keyword.get(opts, :sampling_frequency)

    if sampling && is_float(sampling) do
      "|@#{sampling}"
    else
      ""
    end
  end
end
