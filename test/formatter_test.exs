defmodule FormatterTest do
  use ExUnit.Case

  describe "a couple tests together" do
    test "first test" do
      assert true
    end

    test "second test" do
      assert true
    end
  end

  describe "this test should" do
    test "be a failure" do
      assert false
    end
  end
end
