defmodule ExPrettyTest.Formatter.Outcome do
  alias ExPrettyTest.Formatter.Utils
  def report_outcome(%{show_results: true} = config) do
    IO.puts ""
    IO.puts(Utils.colorize(:magenta, Utils.indent("Results:", Utils.suite_indent()), config))
    IO.puts "------------------------"
    IO.puts("#{Utils.colorize(:blue, "Total tests run:", config)} #{config.test_counter.test}")
    successes = "#{Utils.colorize(:green, "Successes:", config)} #{config.test_counter.success}"
    failures = "#{Utils.colorize(:red, "Failures:", config)} #{config.test_counter.failure}"
    skipped = "#{Utils.colorize(:yellow, "Skipped tests:", config)} #{config.test_counter.skipped}"
    excluded = "#{Utils.colorize(:cyan, "Excluded tests:", config)} #{config.test_counter.excluded}"
    invalid = "#{Utils.colorize(:light_red, "Invalid tests:", config)} #{config.test_counter.invalid}"

    "#{successes}, #{failures}, #{skipped}, #{excluded}, #{invalid}"
    |> IO.puts
  end
  def report_outcome(_config), do: nil
end
