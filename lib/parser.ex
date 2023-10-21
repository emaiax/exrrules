defmodule Exrrules.Parser do
  @moduledoc false

  alias Exrrules.Parser.Tokenizer
  alias Exrrules.RRULE

  require Logger

  defstruct text: nil,
            lang: nil,
            rrule: %RRULE{},
            rules: [],
            tokenizer: []

  @months_rules Exrrules.Language.English.months()
  @weekdays_rules Exrrules.Language.English.weekdays()

  def to_rrule(text, lang \\ "en") do
    text
    |> parse(lang)
    |> Map.get(:rrule)
    |> RRULE.to_string()
  end

  def parse(text, lang \\ "en") do
    parser = %__MODULE__{
      text: text,
      lang: Exrrules.Language.new(lang),
      tokenizer: Tokenizer.tokenize(text)
    }

    Enum.reduce(parser.tokenizer.tokens, parser, &process_rule_group/2)
  end

  # no more tokens
  defp process_rule_group({_rule_group, []}, parser), do: parser

  # TODO: maybe process inside the `process_token(rule_group, token)`?
  # process a comma group
  defp process_rule_group({rule_group, [comma_group | tokens]}, parser)
       when is_list(comma_group) do
    # ensure there's nothing else besides the same one rule group
    comma_group
    |> Enum.reject(&is_comma?/1)
    |> Enum.map(& &1.rule_group)
    |> Enum.uniq()
    |> case do
      [_] -> :ok
      invalid -> raise "Invalid rule group: #{inspect(invalid)}"
    end

    # process each token inside the comma group according to the rule_group it belongs
    parser =
      comma_group
      |> Enum.reject(&is_comma?/1)
      |> Enum.reduce(parser, fn token, parser ->
        %{parser | rrule: process_token({rule_group, token}, parser.rrule)}
      end)

    # continue processing the rest with the updated parser
    process_rule_group({rule_group, tokens}, parser)
  end

  defp process_rule_group({rule_group, [token | tokens]}, %{rrule: rrule} = parser) do
    parser = %{parser | rrule: process_token({rule_group, token}, rrule)}

    process_rule_group({rule_group, tokens}, parser)
  end

  # process a single token inside :every rule group
  defp process_token({:every, token}, rrule) do
    case token.rule do
      # ingest other/number tokens that denotes an interval
      #
      rule when rule in [:other, :number, :number_text] ->
        RRULE.add_interval(rrule, token.value)

      :hours ->
        RRULE.add_freq(rrule, :hourly)

      :days ->
        RRULE.add_freq(rrule, :daily)

      :weeks ->
        RRULE.add_freq(rrule, :weekly)

      :months ->
        RRULE.add_freq(rrule, :monthly)

      :years ->
        RRULE.add_freq(rrule, :yearly)

      :weekdays ->
        rrule
        |> RRULE.add_freq(:weekly)
        |> RRULE.add_weekdays()

      rule when rule in @weekdays_rules ->
        rrule
        |> RRULE.add_freq(:weekly)
        |> RRULE.add_weekday(rule)

      rule when rule in [:nth, :number] ->
        rrule
        |> RRULE.add_freq(:monthly)
        |> RRULE.add_month_day(token.value)

      rule when rule in @months_rules ->
        rrule
        |> RRULE.add_freq(:yearly)
        |> RRULE.add_month(rule)

      unsupported ->
        raise "Unsupported rule inside :every group: #{inspect(unsupported)}"
    end
  end

  # process a single token inside :at rule group
  defp process_token({:at, token}, rrule) do
    case token.rule do
      rule when rule in [:other, :number, :number_text] ->
        RRULE.add_hour(rrule, token.value)

      unsupported ->
        raise "Unsupported rule inside :at group: #{inspect(unsupported)}"
    end
  end

  # process a single token inside :on rule group
  defp process_token({:on, token}, rrule) do
    case token do
      %{rule: :weekdays} ->
        rrule
        |> RRULE.add_freq(:weekly, lazy: true)
        |> RRULE.add_weekdays()

      %{rule_group: :weekday, rule: rule} ->
        rrule
        |> RRULE.add_freq(:weekly)
        |> RRULE.add_weekday(rule)

      %{rule_group: :month, rule: rule} ->
        rrule
        |> RRULE.add_freq(:yearly, lazy: true)
        |> RRULE.add_month(rule)

      # jibberish
      %{rule: rule} when rule in ~w(of on)a ->
        rrule

      unsupported ->
        raise "Unsupported rule inside :on group: #{inspect(unsupported.rule)}"
    end
  end

  def is_comma?(:comma), do: true
  def is_comma?(%{rule: :comma}), do: true
  def is_comma?(_not_comma), do: false
end
