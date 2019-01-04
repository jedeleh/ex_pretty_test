defmodule ExPrettyTest.Formatter.Errors do
  import ExUnit.Formatter,
    only: [format_test_failure: 5]

  alias ExPrettyTest.Formatter.Utils

  def report_errors(%{failures: failures}) when length(failures) == 0, do: nil

  def report_errors(config) do
    IO.puts ""
    IO.puts(Utils.colorize(:red, Utils.indent("Errors Found:", Utils.suite_indent()), config))
    IO.puts("")

    config.failures
    |> Enum.with_index()
    |> Enum.map(fn {failure, counter} ->
      %ExUnit.Test{state: {:failed, failures}} = failure

      formatted =
        format_test_failure(
          failure,
          failures,
          counter + 1,
          config.width,
          &formatter(&1, &2, config)
        )

      IO.puts(formatted)
    end)
  end

  defp formatter(_atom, msg, config) when is_atom(msg) do
    IO.puts("IS ATOM: #{msg}")
    Utils.colorize(:red, Atom.to_string(msg), config)
  end

  defp formatter(:location_info, msg, config),
    do: Utils.colorize(:magenta, "  location: #{msg}", config)

  defp formatter(:test_info, msg, config), do: Utils.colorize(:red, msg, config)

  defp formatter(:stacktrace_info, msg, config), do: Utils.colorize(:light_magenta, msg, config)

  defp formatter(_, msg, config), do: Utils.colorize(:red, msg, config)
end
