defmodule ExPrettyTest.Formatter.Outcome do
  alias ExPrettyTest.Formatter.Utils
  def report_outcome(%{show_results: true} = config) do
    IO.puts(Utils.colorize(:magenta, Utils.indent("Results:", Utils.suite_indent()), config))
    IO.puts "------------------------"
    IO.puts("#{Utils.colorize(:blue, "Total tests run:", config)} #{config.test_counter.test}")
    IO.puts("#{Utils.colorize(:green, "Successes:", config)} #{successes(config)}")
    IO.puts("#{Utils.colorize(:red, "Failures:", config)} #{config.failure_counter}")
    IO.puts("#{Utils.colorize(:yellow, "Skipped tests:", config)} #{config.skipped_counter}")
    IO.puts("#{Utils.colorize(:cyan, "Excluded tests:", config)} #{config.excluded_counter}")
    IO.puts("#{Utils.colorize(:light_red, "Invalid tests:", config)} #{config.invalid_counter}")
  end
  def report_outcome(_config), do: nil

  defp successes(config) do
    config.test_counter.test - config.failure_counter - config.skipped_counter -
      config.excluded_counter - config.invalid_counter
  end
end
