defmodule Exrrules.Parser.Token do
  defstruct rule: nil,
            rule_group: nil,
            value: nil,
            token: nil

  @months Exrrules.Language.English.months()
  @weekdays Exrrules.Language.English.weekdays()
  @relatives ~w(first second third next last)a

  def new(rule, token) do
    %__MODULE__{
      rule: rule,
      rule_group: build_rule_group(rule),
      value: build_value(rule, token),
      token: String.trim(token)
    }
  end

  # numbers
  def build_value(:other, _token), do: 2
  def build_value(:number_text, "one"), do: 1
  def build_value(:number_text, "two"), do: 2
  def build_value(:number_text, "three"), do: 3
  def build_value(:number, token), do: String.to_integer(token)

  def build_value(:nth, token) do
    token
    |> String.replace(~r/(st|nd|rd|th)$/, "")
    |> String.to_integer()
  end

  # weekdays
  def build_value(:monday, _token), do: "MO"
  def build_value(:tuesday, _token), do: "TU"
  def build_value(:wednesday, _token), do: "WE"
  def build_value(:thursday, _token), do: "TH"
  def build_value(:friday, _token), do: "FR"
  def build_value(:saturday, _token), do: "SA"
  def build_value(:sunday, _token), do: "SU"

  # months
  def build_value(:january, _token), do: 1
  def build_value(:february, _token), do: 2
  def build_value(:march, _token), do: 3
  def build_value(:april, _token), do: 4
  def build_value(:may, _token), do: 5
  def build_value(:june, _token), do: 6
  def build_value(:july, _token), do: 7
  def build_value(:august, _token), do: 8
  def build_value(:september, _token), do: 9
  def build_value(:october, _token), do: 10
  def build_value(:november, _token), do: 11
  def build_value(:december, _token), do: 12

  # relatives
  def build_value(:nth, "first"), do: 1
  def build_value(:nth, "second"), do: 2
  def build_value(:nth, "third"), do: 3
  def build_value(:nth, "last"), do: -1

  # base case
  def build_value(_, token), do: token

  defp build_rule_group(rule) when rule in @months, do: :month
  defp build_rule_group(rule) when rule in @weekdays, do: :weekday
  defp build_rule_group(rule) when rule in @relatives, do: :relative
  defp build_rule_group(_), do: nil
end
