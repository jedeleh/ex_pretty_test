defmodule ExPrettyTest.Formatter do
  @doc false
  use GenServer

  import ExUnit.Formatter,
    only: [
      #format_time: 2,
      format_filters: 2,
      #format_test_all_failure: 5,
      format_test_failure: 5
    ]

  @suite_indent ""
  @module_indent "  "
  @case_indent "    "
  @test_indent "      "
  @failure_indent "          "

  def handle_cast() do
  end

  def init(opts) do
    print_filters(Keyword.take(opts, [:include, :exclude]))

    config = %{
      seed: opts[:seed],
      trace: opts[:trace],
      colors: Keyword.put_new(opts[:colors], :enabled, IO.ANSI.enabled?()),
      width: get_terminal_width(),
      slowest: opts[:slowest],
      test_counter: %{},
      test_timings: [],
      failures: [],
      failure_counter: 0,
      skipped_counter: 0,
      excluded_counter: 0,
      invalid_counter: 0
    }

    {:ok, config}
  end

  defp indent(msg, indent) do
    "#{indent}#{msg}"
  end

  def handle_cast({:suite_started, _opts}, config) do
    IO.puts(colorize(:green, indent("Test suite started", @suite_indent), config))
    {:noreply, config}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, config) do
    IO.puts(colorize(:green, indent("Test suite finished", @suite_indent), config))
    IO.puts ""
    report_errors(config)
    IO.puts ""
    report_outcome(config)

    {:noreply, config}
  end

  def handle_cast({:module_started, %ExUnit.TestModule{name: name}}, config) do
    IO.puts(colorize(:green, indent(Atom.to_string(name), @module_indent), config))

    {:noreply, config}
  end

  def handle_cast({:module_finished, %ExUnit.TestModule{state: nil}}, config) do
    {:noreply, config}
  end

  def handle_cast({:case_started, %ExUnit.TestCase{} = test_case}, config) do
    output = indent("Test case started: #{length(test_case.tests)} tests", @case_indent)
    IO.puts(colorize(:green, output, config))
    {:noreply, config}
  end

  def handle_cast({:case_finished, %ExUnit.TestCase{name: _name} = _test}, config) do
    {:noreply, config}
  end

  def handle_cast({:test_started, %ExUnit.Test{}}, config) do
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, config) do
    IO.puts(colorize(:green, test_message(test.name), config))
    test_counter = update_test_counter(config.test_counter, test)
    test_timings = update_test_timings(config.test_timings, test)
    config = %{config | test_counter: test_counter, test_timings: test_timings}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, _}} = test}, config) do
    IO.puts(colorize(:cyan, test_message(test.name), config))
    test_counter = update_test_counter(config.test_counter, test)
    config = %{config | test_counter: test_counter, excluded_counter: config.excluded_counter + 1}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skipped, _}} = test}, config) do
    IO.puts(colorize(:yellow, test_message(test.name), config))
    test_counter = update_test_counter(config.test_counter, test)
    config = %{config | test_counter: test_counter, skipped_counter: config.skipped_counter + 1}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, _}} = test}, config) do
    IO.puts(colorize(:orange, test_message(test.name), config))
    test_counter = update_test_counter(config.test_counter, test)
    config = %{config | test_counter: test_counter, invalid_counter: config.invalid_counter + 1}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, failures}} = test}, config) do
    {test_name, path, line_number} = deconstruct_failures(failures)
    IO.puts(colorize(:red, test_message(test_name), config))
    IO.puts(colorize(:red, indent("#{path}:#{line_number}", @failure_indent), config))

    test_counter = update_test_counter(config.test_counter, test)
    test_timings = update_test_timings(config.test_timings, test)
    failures = update_failures(config.failures, test)
    failure_counter = config.failure_counter + 1

    config = %{
      config
      | test_counter: test_counter,
        failures: failures,
        failure_counter: failure_counter,
        test_timings: test_timings
    }

    {:noreply, config}
  end

  defp update_test_counter(test_counter, %{tags: %{test_type: test_type}}) do
    Map.update(test_counter, test_type, 1, &(&1 + 1))
  end

  defp update_test_timings(timings, %ExUnit.Test{} = test) do
    [test | timings]
  end

  defp update_failures(failures, %ExUnit.Test{} = test) do
    [test | failures]
  end

  defp deconstruct_failures(failures) do
    [
      {
        :error,
        _error,
        [
          {
            _module,
            test_name,
            _number,
            [
              file: path,
              line: line_number
            ]
          }
          | _rest
        ]
      }
      | _more
    ] = failures

    {test_name, path, line_number}
  end

  defp test_message(message) when is_atom(message) do
    indent("* #{Atom.to_string(message)}", @test_indent)
  end

  defp test_message(message) do
    indent("* #{message}", @test_indent)
  end

  defp colorize(escape, string, %{colors: colors}) do
    if colors[:enabled] do
      [escape, string, :reset]
      |> IO.ANSI.format_fragment(true)
      |> IO.iodata_to_binary()
    else
      string
    end
  end

  defp get_terminal_width do
    case :io.columns() do
      {:ok, width} -> max(40, width)
      _ -> 80
    end
  end

  defp print_filters(include: [], exclude: []) do
    :ok
  end

  defp print_filters(include: include, exclude: exclude) do
    if exclude != [], do: IO.puts(format_filters(exclude, :exclude))
    if include != [], do: IO.puts(format_filters(include, :include))
    IO.puts("")
    :ok
  end

  defp formatter(_atom, msg, config) when is_atom(msg) do
    IO.puts("IS ATOM: #{msg}")
    colorize(:red, Atom.to_string(msg), config)
  end

  defp formatter(:location_info, msg, config), do: colorize(:magenta, "  location: #{msg}", config)

  defp formatter(:test_info, msg, config), do: colorize(:red, msg, config)

  defp formatter(:stacktrace_info, msg, config), do: colorize(:light_magenta, msg, config)

  defp formatter(_, msg, config), do: colorize(:red, msg, config)

  defp report_outcome(config) do
    IO.puts "Results:"
    config
  end

  defp report_errors(%{failures: failures}) when length(failures) == 0, do: nil

  defp report_errors(config) do
    IO.puts(colorize(:red, indent("Errors Found:", @suite_indent), config))
    IO.puts ""

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
end
