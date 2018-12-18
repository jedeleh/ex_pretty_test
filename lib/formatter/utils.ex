defmodule ExPrettyTest.Formatter.Utils do
  import ExUnit.Formatter,
    only: [format_filters: 2]

  def colorize(escape, string, %{colors: colors}) do
    if colors[:enabled] do
      [escape, string, :reset]
      |> IO.ANSI.format_fragment(true)
      |> IO.iodata_to_binary()
    else
      string
    end
  end

  def indent(msg, indent) do
    "#{indent}#{msg}"
  end

  def short_name(test, index, config) do
    current = colorize(:yellow, "#{index}", config)

    "#{case_indent()}#{current}. " <>
      "#{test.module}.#{Atom.to_string(test.name)}\n" <>
      "#{test_indent()}#{test.tags.file}:#{test.tags.line}\n" <>
      "#{test_indent()}Time: #{test.time}\n"
  end

  def short_name(test) do
    "#{case_indent()}#{test.module}.#{Atom.to_string(test.name)}\n" <>
      "#{case_indent()}#{test.tags.file}:#{test.tags.line}"
  end

  def suite_indent(), do: ""
  def module_indent(), do: "  "
  def case_indent(), do: "    "
  def test_indent(), do: "      "
  def failure_indent(), do: "        "

  def print_filters(include: [], exclude: []) do
    :ok
  end

  def print_filters(include: include, exclude: exclude) do
    if exclude != [], do: IO.puts(format_filters(exclude, :exclude))
    if include != [], do: IO.puts(format_filters(include, :include))
    IO.puts("")
    :ok
  end
end
