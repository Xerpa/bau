defmodule Bau.Xerpa.CeeLogFormatTest do
  use ExUnit.Case

  alias Bau.Xerpa.CeeLogFormat

  test "log levels" do
    for {lvl_input, lvl_expected} <- [debug: "<7>", info: "<6>", warn: "<4>", error: "<3>"] do
      {lvl, _msg} = logmsg(lvl_input, "foobar", :unused, [])
      assert lvl_expected == lvl
    end
  end

  describe "log message" do
    test "binary value" do
      {_, msg} = logmsg(:debug, "foobar")
      assert %{"msg" => "foobar"} = msg
    end

    test "iodata value" do
      {_, msg} = logmsg(:debug, ["foo", "bar"])
      assert %{"msg" => "foobar"} = msg
    end
  end

  describe "log metadata" do
    test "empty case" do
      {_, msg} = logmsg(:debug, "")
      assert %{} == msg["meta"]
    end

    test "simple types" do
      {_, msg} = logmsg(:debug, "", atom: :bar, int: 42, float: 4.2, bool: true, bin: "meh")

      assert %{
               "atom" => "bar",
               "int" => 42,
               "float" => 4.2,
               "bool" => true,
               "bin" => "meh"
             } == msg["meta"]
    end

    test "complex types" do
      {_, msg} = logmsg(:debug, "", map: %{}, list: [])

      assert %{"map" => "%{}", "list" => "[]"} == msg["meta"]
    end
  end

  describe "xerpa metadata" do
    test "empty case" do
      {_, msg} = logmsg(:debug, "")
      assert %{} == msg["xerpa"]
    end

    test "simple types" do
      {_, msg} = logmsg(:debug, "", [], atom: :bar, int: 42, float: 4.2, bool: true, bin: "meh")

      assert %{"atom" => "bar", "bin" => "meh", "bool" => true, "float" => 4.2, "int" => 42} ==
               msg["xerpa"]
    end

    test "complex types" do
      {_, msg} = logmsg(:debug, "", [], map: %{}, list: [])
      assert %{"map" => "%{}", "list" => "[]"} == msg["xerpa"]
    end
  end

  describe "error case" do
    test "handle exceptions" do
      assert "<2>ERROR FORMATTING MESSAGE: {\"message\", []}" == logmsg(:invalid, "message")

      assert "<2>ERROR FORMATTING MESSAGE: {\"message\", [foo: :bar]}" ==
               logmsg(:invalid, "message", foo: :bar)
    end
  end

  defp logmsg(level, msg, meta_data \\ [], xerpa_meta \\ []) do
    Process.put({CeeLogFormat, :metadata}, xerpa_meta)
    log_entry = CeeLogFormat.format(level, msg, :unused, meta_data)
    [level, "cee: " <> json] = String.split(log_entry, ["@"], parts: 2)
    {level, Poison.decode!(json)}
  rescue
    _ -> CeeLogFormat.format(level, msg, :unused, meta_data)
  end
end
