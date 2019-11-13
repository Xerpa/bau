defmodule Bau.Xerpa.StatsDTest do
  use ExUnit.Case, async: true

  alias Bau.Xerpa.StatsD

  describe "send_metrics" do
    setup do
      {:ok, port} = spawn_udp_server()
      config = [host: "localhost", port: port]

      {:ok, %{config: config}}
    end

    test "sends single metric", %{config: config} do
      metric = StatsD.counter("foobar", 123)
      assert StatsD.send_metrics(metric, config) == :ok

      assert_receive {:udp, _erl_port, _addr, _port, 'foobar:123|c'}
    end

    test "sends multiple metrics", %{config: config} do
      metrics = [
        StatsD.counter("counter", 123),
        StatsD.gauge("gauge", now: 321),
        StatsD.timing("timing", 200, :ms),
        StatsD.sets("sets", "value")
      ]

      assert StatsD.send_metrics(metrics, config) == :ok

      assert_receive {:udp, _erl_port, _addr, _port,
                      'counter:123|c\ngauge:321|g\ntiming:200|ms\nsets:value|s'}
    end
  end

  describe "counter" do
    test "simple counter" do
      assert StatsD.counter("foobar", 123) == "foobar:123|c"
    end

    test "with sampling freq" do
      assert StatsD.counter("foobar", 123, sampling_frequency: 0.2) == "foobar:123|c|@0.2"
    end
  end

  describe "gauge" do
    test "simple gauge : now positive" do
      assert StatsD.gauge("foobar", now: 123) == "foobar:123|g"
    end

    test "simple gauge : now negative" do
      assert StatsD.gauge("foobar", now: -123) == "foobar:0|g\nfoobar:-123|g"
    end

    test "simple gauge : inc" do
      assert StatsD.gauge("foobar", inc: 123) == "foobar:+123|g"
    end

    test "simple gauge : dec" do
      assert StatsD.gauge("foobar", dec: 123) == "foobar:-123|g"
    end

    test "no arguments" do
      assert is_nil(StatsD.gauge("foobar"))
    end

    test "multiple arguments" do
      assert is_nil(StatsD.gauge("foobar", dec: 123, inc: 123))
      assert is_nil(StatsD.gauge("foobar", now: 123, inc: 123))
      assert is_nil(StatsD.gauge("foobar", now: 123, dec: 123))
      assert is_nil(StatsD.gauge("foobar", now: 123, dec: 123, inc: 123))
    end
  end

  describe "timing" do
    test "simple timing : ms" do
      assert StatsD.timing("foobar", 200, :ms) == "foobar:200|ms"
    end

    test "simple timing : h" do
      assert StatsD.timing("foobar", 200, :h) == "foobar:200|h"
    end

    test "with sampling freq" do
      assert StatsD.timing("foobar", 200, :ms, sampling_frequency: 0.25) == "foobar:200|ms|@0.25"
    end
  end

  describe "sets" do
    test "integer" do
      assert StatsD.sets("foobar", 123) == "foobar:123|s"
    end

    test "string" do
      assert StatsD.sets("foobar", "value") == "foobar:value|s"
    end
  end

  defp spawn_udp_server() do
    spawn_udp_server(32_000)
  end

  defp spawn_udp_server(port) when port > 65_535, do: :error

  defp spawn_udp_server(port) do
    case :gen_udp.open(port) do
      {:ok, socket} ->
        on_exit(fn -> :gen_udp.close(socket) end)
        this = self()
        spawn(fn -> listen(socket, this) end)
        {:ok, port}

      {:error, :eaddrinuse} ->
        spawn_udp_server(port + 1)
    end
  end

  defp listen(socket, destination) do
    :gen_udp.recv(socket, 4096)

    listen(socket, destination)
  end
end
