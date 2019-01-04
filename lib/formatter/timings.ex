defmodule ExPrettyTest.Formatter.Timings do
  alias ExPrettyTest.Formatter.Utils

  # TODO: format the time
  def report_times(%{slowest: 0}), do: nil
  def report_times(config) do
    IO.puts("")
    IO.puts(Utils.colorize(:magenta, Utils.indent("Timings:", Utils.suite_indent()), config))

    timings =
      config.test_timings
      |> Enum.sort(fn first, second ->
        first.time > second.time
      end)

    IO.puts(
      Utils.colorize(:yellow, Utils.indent("#{config.slowest} slowest tests:", Utils.module_indent()), config)
    )

    print_test_time(timings, 0, config.slowest, config)
  end

  defp print_test_time(_tests, current, max, _config) when current >= max, do: nil

  defp print_test_time(tests, current, max, config) do
    test = List.first(tests)
    IO.puts(Utils.short_name(test, current + 1, config))

    remaining_tests = Enum.slice(tests, 1, max - current)

    print_test_time(remaining_tests, current + 1, max, config)
  end
end
