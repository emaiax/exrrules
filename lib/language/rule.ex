defmodule Exrrules.Language.Rule do
  @moduledoc """
  Base module for language rules.

  Options:
    - allow_comma: boolean, default: false
    - keyword: boolean, default: false
    - group: group this rule belongs, default: nil
    - patterns: list of "regex" strings, default: []
  """
  defstruct [:allow_comma, :name, :group, :keyword, :patterns]

  def new(opts) when is_list(opts) do
    name = opts[:name] || raise ":name is required"
    patterns = opts[:patterns] || raise ":patterns is required"

    allow_comma = Keyword.get(opts, :allow_comma, false)
    keyword = Keyword.get(opts, :keyword, false)
    group = Keyword.get(opts, :group, nil)

    patterns =
      patterns
      |> List.wrap()
      |> Enum.map(fn pattern -> process_regex_rule(pattern, allow_comma) end)

    %__MODULE__{
      allow_comma: allow_comma,
      name: name,
      group: group,
      keyword: keyword,
      patterns: patterns
    }
  end

  def match?(%__MODULE__{patterns: patterns}, input) do
    Enum.any?(patterns, &Regex.match?(&1, input))
  end

  def split(%__MODULE__{patterns: patterns}, input) do
    Enum.reduce_while(patterns, {nil, nil}, fn pattern, {nil, nil} ->
      case Regex.split(pattern, input, include_captures: true, trim: true) do
        # last match, nothing else to process
        [match] ->
          {:halt, {match, nil}}

        # found match and there's more input to process
        [match | rest] ->
          {:halt, {match, rest |> Enum.join() |> String.trim()}}

        other ->
          raise "Can't capture #{inspect(other)} from #{inspect(input)}"
      end
    end)
  end

  defp process_regex_rule(pattern, allow_comma) when is_binary(pattern) do
    prefix = "^"
    pattern = String.replace(pattern, ~r{\n*}, "")
    suffix = get_suffix(allow_comma)

    ~r(#{prefix}#{pattern}#{suffix})
  end

  # ?= is a positive lookahead assertion that matches the suffix and does not includes it in the match
  defp get_suffix(true), do: "(?=,|\\s|$)"

  # ?: is a non-capturing group that matches the suffix but does not include it in the match
  defp get_suffix(false), do: "(?:\\s|$)"
end
