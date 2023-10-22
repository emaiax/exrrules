defmodule Exrrules.Parser.Token do
  alias Exrrules.Parser.TimeParser

  defstruct rule: nil,
            rule_group: nil,
            value: nil,
            token: nil

  @months Exrrules.Language.English.months()
  @weekdays Exrrules.Language.English.weekdays()

  @relatives ~w(first second third fourth next last nth)a
  @jibberish ~w(of the)a

  def is_relative?(%__MODULE__{rule: rule}), do: rule in @relatives
  def is_jibberish?(%__MODULE__{rule: rule}), do: rule in @jibberish

  def force_interval!(%__MODULE__{} = token), do: %{token | rule_group: :interval}

  def new(rule, token) do
    token = String.trim(token)
    rule_group = build_rule_group(rule)

    %__MODULE__{
      rule: rule,
      rule_group: rule_group,
      token: token,
      value: build_value(rule, rule_group, token)
    }
  end

  # numbers
  def build_value(:other, _rule_group, _token), do: 2
  def build_value(:number_text, _rule_group, "one"), do: 1
  def build_value(:number_text, _rule_group, "two"), do: 2
  def build_value(:number_text, _rule_group, "three"), do: 3
  def build_value(:number_text, _rule_group, "four"), do: 4

  def build_value(:number, _rule_group, token), do: String.to_integer(token)

  # relatives
  def build_value(:first, _rule_group, _token), do: 1
  def build_value(:second, _rule_group, _tokend), do: 2
  def build_value(:third, _rule_group, _token), do: 3
  def build_value(:fourth, _rule_group, _tokenh), do: 4
  def build_value(:next, _rule_group, _token), do: 1
  def build_value(:last, _rule_group, _token), do: -1

  def build_value(:nth, _rule_group, token) do
    token
    |> String.replace(~r/(st|nd|rd|th)$/, "")
    |> String.to_integer()
  end

  # weekdays
  def build_value(:monday, _rule_group, _token), do: "MO"
  def build_value(:tuesday, _rule_group, _token), do: "TU"
  def build_value(:wednesday, _rule_group, _token), do: "WE"
  def build_value(:thursday, _rule_group, _token), do: "TH"
  def build_value(:friday, _rule_group, _token), do: "FR"
  def build_value(:saturday, _rule_group, _token), do: "SA"
  def build_value(:sunday, _rule_group, _token), do: "SU"

  # months
  def build_value(:january, _rule_group, _token), do: 1
  def build_value(:february, _rule_group, _token), do: 2
  def build_value(:march, _rule_group, _token), do: 3
  def build_value(:april, _rule_group, _token), do: 4
  def build_value(:may, _rule_group, _token), do: 5
  def build_value(:june, _rule_group, _token), do: 6
  def build_value(:july, _rule_group, _token), do: 7
  def build_value(:august, _rule_group, _token), do: 8
  def build_value(:september, _rule_group, _token), do: 9
  def build_value(:october, _rule_group, _token), do: 10
  def build_value(:november, _rule_group, _token), do: 11
  def build_value(:december, _rule_group, _token), do: 12

  # date and time
  #
  # - %{hour: 12, minute: nil}
  # - %{hour: 6, minute: 15}
  # - %{hour: 18, minute: 30}
  #
  def build_value(:time, _rule_group, token) do
    TimeParser.extract_time_components(token)
  end

  # base case
  def build_value(_rule, _rule_group, token), do: token

  defp build_rule_group(rule) when rule in @months, do: :month
  defp build_rule_group(rule) when rule in @weekdays, do: :weekday
  defp build_rule_group(rule) when rule in @relatives, do: :relative
  defp build_rule_group(_), do: nil
end
