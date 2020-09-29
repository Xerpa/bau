defmodule Bau.Xerpa.EnumTest do
  use ExUnit.Case

  alias Bau.TestSupport.EctoHelpers

  @ecto3? EctoHelpers.ecto3?()

  defmodule Const do
    use Bau.Xerpa.Enum, name: "sbrébous"
    ecto_type(:integer)

    defvalue(:v1, 1, "valor 1")
    defvalue(:v2, 2, "valor 2")
    defvalue(:v3, 3, "valor 3")
    defvalue(:v4, 4, "valor 4", hidden: true)
  end

  defmodule ConstString do
    use Bau.Xerpa.Enum
    ecto_type(:string)

    defvalue(:v1, "sou uma string", "valor 1")
  end

  defp v1, do: %Const{name: :v1, code: 1, translation: "valor 1"}
  defp v2, do: %Const{name: :v2, code: 2, translation: "valor 2"}
  defp v3, do: %Const{name: :v3, code: 3, translation: "valor 3"}
  defp v4, do: %Const{name: :v4, code: 4, translation: "valor 4"}

  test "Const definition" do
    assert v1() == Const.v1()
    assert v2() == Const.v2()
    assert v3() == Const.v3()
    assert v4() == Const.v4()

    assert "sbrébous" == Const.name()
  end

  test "Const#values/0" do
    values = Const.values()

    assert v1() in values
    assert v2() in values
    assert v3() in values
    refute v4() in values
  end

  test "Const#from_code/1" do
    assert {:ok, v1()} == Const.from_code(1)
    assert {:ok, v2()} == Const.from_code(2)
    assert {:ok, v3()} == Const.from_code(3)
    assert {:ok, v4()} == Const.from_code(4)
    assert :error = Const.from_code(0)
  end

  test "Const#from_name/1" do
    assert {:ok, v1()} == Const.from_name(:v1)
    assert {:ok, v2()} == Const.from_name(:v2)
    assert {:ok, v3()} == Const.from_name(:v3)
    assert {:ok, v4()} == Const.from_name(:v4)
    assert :error = Const.from_name(0)
  end

  test "Const#cast/1" do
    assert {:ok, v1()} == Const.cast(1)
    assert {:ok, v2()} == Const.cast(2)
    assert {:ok, v3()} == Const.cast(3)
    assert {:ok, v4()} == Const.cast(4)

    assert {:ok, v1()} == Const.cast(v1())
    assert {:ok, v2()} == Const.cast(v2())
    assert {:ok, v3()} == Const.cast(v3())
    assert {:ok, v4()} == Const.cast(v4())

    assert :error = Const.cast(0)
  end

  test "Const#load/1" do
    assert {:ok, v1()} == Const.load(1)
    assert {:ok, v2()} == Const.load(2)
    assert {:ok, v3()} == Const.load(3)
    assert {:ok, v4()} == Const.load(4)

    assert {:ok, v1()} == Const.load(v1())
    assert {:ok, v2()} == Const.load(v2())
    assert {:ok, v3()} == Const.load(v3())
    assert {:ok, v4()} == Const.load(v4())

    assert :error = Const.load(0)
  end

  test "Const#dump/1" do
    assert {:ok, 1} == Const.dump(v1())
    assert {:ok, 2} == Const.dump(v2())
    assert {:ok, 3} == Const.dump(v3())
    assert {:ok, 4} == Const.dump(v4())
  end

  test "nil handling" do
    assert {:ok, nil} == Const.cast(nil)
    assert {:ok, nil} == Const.load(nil)
    assert {:ok, nil} == Const.dump(nil)
  end

  test "Const implements Poison.Encoder" do
    audits = Enum.map([v4() | Const.values()], &Poison.encode!/1)

    assert Poison.encode!(1) in audits
    assert Poison.encode!(2) in audits
    assert Poison.encode!(3) in audits
    assert Poison.encode!(4) in audits
  end

  test "Const implements Jason.Encoder" do
    assert Jason.encode!(v1()) == "1"
    assert Jason.encode!(ConstString.v1()) == "\"sou uma string\""
  end

  test "Const implements Inspect" do
    inspects = Enum.map([v4() | Const.values()], &inspect/1)
    assert "Bau.Xerpa.EnumTest.Const<v1>" in inspects
    assert "Bau.Xerpa.EnumTest.Const<v2>" in inspects
    assert "Bau.Xerpa.EnumTest.Const<v3>" in inspects
    assert "Bau.Xerpa.EnumTest.Const<v4>" in inspects
  end

  if @ecto3? do
    test "Const implements Ecto.Type embed_as" do
      assert Const.embed_as(:format) == :self
    end

    test "Const implements Ecto.Type equal?" do
      assert Const.equal?(Const.v1(), Const.v1())
      refute Const.equal?(Const.v1(), Const.v2())
      refute Const.equal?(Const.v2(), Const.v1())
    end
  end
end
