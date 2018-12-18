defmodule ExPrettyTest.Formatter do
  @doc false
  use GenServer

  alias ExPrettyTest.Formatter.Timings
  alias ExPrettyTest.Formatter.Utils
  alias ExPrettyTest.Formatter.Errors
  alias ExPrettyTest.Formatter.Outcome

  def init(opts) do
    Utils.print_filters(Keyword.take(opts, [:include, :exclude]))

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
      invalid_counter: 0,
      show_results: Keyword.get(opts, :show_results, true),
      show_timings: Keyword.get(opts, :show_timings, true)
    }

    {:ok, config}
  end

  def handle_cast({:suite_started, _opts}, config) do
    IO.puts(
      Utils.colorize(:green, Utils.indent("Test suite started", Utils.suite_indent()), config)
    )

    {:noreply, config}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, config) do
    IO.puts(
      Utils.colorize(:green, Utils.indent("Test suite finished", Utils.suite_indent()), config)
    )

    Timings.report_times(config)
    IO.puts("")
    Errors.report_errors(config)
    IO.puts("")
    Outcome.report_outcome(config)

    {:noreply, config}
  end

  def handle_cast({:module_started, %ExUnit.TestModule{name: name}}, config) do
    IO.puts(
      Utils.colorize(:green, Utils.indent(Atom.to_string(name), Utils.module_indent()), config)
    )

    {:noreply, config}
  end

  def handle_cast({:module_finished, %ExUnit.TestModule{state: nil}}, config) do
    {:noreply, config}
  end

  def handle_cast({:case_started, %ExUnit.TestCase{} = test_case}, config) do
    output =
      Utils.indent("Test case started: #{length(test_case.tests)} tests", Utils.case_indent())

    IO.puts(Utils.colorize(:green, output, config))
    {:noreply, config}
  end

  def handle_cast({:case_finished, %ExUnit.TestCase{name: _name} = _test}, config) do
    {:noreply, config}
  end

  def handle_cast({:test_started, %ExUnit.Test{}}, config) do
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, config) do
    IO.puts(Utils.colorize(:green, test_message(test.name), config))
    test_counter = update_test_counter(config.test_counter, test)
    test_timings = update_test_timings(config.test_timings, test)
    config = %{config | test_counter: test_counter, test_timings: test_timings}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, _}} = test}, config) do
    IO.puts(Utils.colorize(:cyan, test_message(test.name), config))
    test_counter = update_test_counter(config.test_counter, test)
    config = %{config | test_counter: test_counter, excluded_counter: config.excluded_counter + 1}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skipped, _}} = test}, config) do
    IO.puts(Utils.colorize(:yellow, test_message(test.name), config))
    test_counter = update_test_counter(config.test_counter, test)
    config = %{config | test_counter: test_counter, skipped_counter: config.skipped_counter + 1}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, _}} = test}, config) do
    IO.puts(Utils.colorize(:orange, test_message(test.name), config))
    test_counter = update_test_counter(config.test_counter, test)
    config = %{config | test_counter: test_counter, invalid_counter: config.invalid_counter + 1}
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, failures}} = test}, config) do
    {test_name, path, line_number} = deconstruct_failures(failures)
    IO.puts(Utils.colorize(:red, test_message(test_name), config))

    IO.puts(
      Utils.colorize(:red, Utils.indent("#{path}:#{line_number}", Utils.failure_indent()), config)
    )

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
    Utils.indent("* #{Atom.to_string(message)}", Utils.test_indent())
  end

  defp test_message(message) do
    Utils.indent("* #{message}", Utils.test_indent())
  end

  defp get_terminal_width do
    case :io.columns() do
      {:ok, width} -> max(40, width)
      _ -> 80
    end
  end
end
