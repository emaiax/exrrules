defmodule Exrrules.Parser do
  @moduledoc false

  defstruct text: nil,
            lang: nil,
            rules: [],
            tokens: []

  def parse_date(text) do
    formats = [
      # 2032-03-15
      "%Y-%m-%d",
      # Mar 15 2032
      "%b %d %Y",
      # Mar 15, 2032
      "%b %d, %Y"
    ]

    formats
    |> Enum.reduce_while(
      nil,
      fn format, acc ->
        case Timex.parse(text, format, :strftime) do
          {:ok, date} -> {:halt, Timex.to_date(date)}
          {:error, _error} -> {:cont, acc}
        end
      end
    )
  end

  def to_rrules(text, lang \\ "en") do
    text
    |> parse(lang)
    |> Map.get(:rules)
    |> Enum.reverse()
    |> Enum.map_join(";", fn {k, v} -> "#{String.upcase(to_string(k))}=#{v}" end)
  end

  def parse(text, lang \\ "en") do
    %__MODULE__{text: text, lang: Exrrules.Language.init(lang)}
    |> build_tokens()
    |> build_rules()
  end

  defp build_tokens(%__MODULE__{text: text, lang: lang} = parser) do
    tokens =
      text
      |> String.split(" ")
      |> Enum.reduce([], fn token, acc ->
        case find_rule_name_for_token(lang.rules, token) do
          :other ->
            [%{token: "2", rule: :other} | acc]

          rule ->
            if has_more?(token) do
              acc
              |> List.insert_at(0, %{token: String.replace(token, ~r{,$}, ""), rule: rule})
              |> List.insert_at(0, %{token: ",", rule: :comma})
            else
              [%{token: token, rule: rule} | acc]
            end
        end
      end)

    %{parser | tokens: Enum.reverse(tokens)}
  end

  defp find_rule_name_for_token(rules, token) do
    case Enum.find(rules, fn {_name, rule} -> token =~ rule end) do
      {rule, _rule_regex} -> rule
      _ -> raise "Invalid token found #{inspect(token)}"
    end
  end

  defp build_rules(%__MODULE__{rules: rules, tokens: tokens} = parser) do
    tokens = expect!(tokens, :every)

    {_tokens, rules} =
      {tokens, rules}
      |> build_intervals()
      |> build_frequency()
      |> build_at()
      |> build_until()

    %{parser | rules: rules}
  end

  defp build_intervals({tokens, rules}) do
    if accepts?(tokens, [:number, :other]) do
      {tokens, rules}
      |> build_interval(:other)
      |> build_interval(:number)
    else
      {tokens, rules}
    end
  end

  defp build_interval({tokens, rules}, rule) do
    case accept!(tokens, rule) do
      {nil, tokens} -> {tokens, rules}
      {token, tokens} -> {tokens, Keyword.put(rules, :interval, token.token)}
    end
  end

  defp build_frequency({tokens, rules}) do
    case List.pop_at(tokens, 0) do
      {%{rule: rule}, tokens} ->
        {tokens, Keyword.put(rules, :freq, frequency_for(rule))}

      {token, tokens} ->
        {[token | tokens], rules}
    end
  end

  @months_rules Exrrules.Language.English.months_rules()
  @weekdays_rules Exrrules.Language.English.weekdays_rules()

  defp frequency_for(rule) do
    case rule do
      :days -> "DAILY"
      :weeks -> "WEEKLY"
      :months -> "MONTHLY"
      :years -> "YEARLY"
      :weekends -> "WEEKLY;BYDAY=SA"
      :weekdays -> "WEEKLY;BYDAY=MO,TU,WE,TH,FR"
      :workdays -> "WEEKLY;BYDAY=MO,TU,WE,TH,FR"
      custom -> build_custom_frequency(custom)
    end
  end

  defp build_custom_frequency(rule) when rule in @months_rules do
    "YEARLY;BYMONTH=#{build_month_index(rule)}"
  end

  defp build_custom_frequency(rule) when rule in @weekdays_rules do
    "WEEKLY;BYDAY=#{build_weekday(rule)}"
  end

  defp build_custom_frequency(rule) do
    raise "Invalid rule #{inspect(rule)}"
  end

  defp build_weekday(weekday) when is_atom(weekday) do
    weekday
    |> to_string()
    |> String.slice(0..1)
    |> String.upcase()
  end

  defp build_month_index(month) when is_atom(month) do
    Enum.find_index(@months_rules, &(&1 == month)) + 1
  end

  def build_at({tokens, rules}) do
    {token_at, tokens} = accept!(tokens, :at)

    if token_at do
      expect!(tokens, :number)

      {tokens, found_rules} = Enum.reduce_while(tokens, {tokens, []}, &build_number_list/2)

      byhours =
        found_rules
        |> Enum.reverse()
        |> Enum.join(",")

      {tokens, Keyword.put(rules, :byhours, byhours)}
    else
      {tokens, rules}
    end
  end

  # skips when comma
  defp build_number_list(%{rule: :comma}, {[_token | tokens], acc}), do: {:cont, {tokens, acc}}

  defp build_number_list(%{rule: :number}, {tokens, acc}) do
    {token, tokens} = accept!(tokens, :number)

    # if has comma then continue
    if has_more?(token, tokens) do
      case Regex.scan(~r{[1-9][0-9]*}, token.token) do
        [] -> {:halt, {tokens, acc}}
        [value | _] -> {:cont, {tokens, [value | acc]}}
      end
    else
      {:halt, {tokens, [token.token | acc]}}
    end
  end

  defp build_number_list(_, {tokens, acc}), do: {:halt, {tokens, acc}}

  defp build_until({tokens, rules}) do
    {token_at, tokens} = accept!(tokens, :until)

    if token_at do
      if is_date?(tokens) do
        until =
          tokens
          |> Enum.reject(&is_comma?/1)
          |> Enum.map_join(" ", & &1.token)
          |> parse_date()
          |> Timex.format!("{ISO:Basic:Z}")

        {[], Keyword.put(rules, :until, until)}
      else
        {[], Keyword.put(rules, :until, :invalid)}
      end
    else
      {tokens, rules}
    end
  end

  defp is_date?(tokens) do
    tokens_rules =
      tokens
      |> Enum.reject(&is_comma?/1)
      |> Enum.take(3)
      |> Enum.map(& &1.rule)

    months = [
      :january,
      :february,
      :march,
      :april,
      :may,
      :june,
      :july,
      :august,
      :september,
      :october,
      :november,
      :december
    ]

    # dd-mm-yyyy and all other variations
    #
    [:number, :number, :number] == tokens_rules or
      MapSet.intersection(MapSet.new(tokens_rules), MapSet.new(months))
  end

  defp expect!(tokens, rule) do
    case List.pop_at(tokens, 0) do
      {%{rule: ^rule}, rest} ->
        rest

      {%{rule: token_rule}, _rest} ->
        raise "Invalid token, expected #{inspect(rule)}, got #{inspect(token_rule)}"

      {nil, _} ->
        raise "Unexpected end"
    end
  end

  defp accept!(tokens, rule) do
    case Enum.at(tokens, 0) do
      %{rule: ^rule} -> List.pop_at(tokens, 0)
      _ -> {nil, tokens}
    end
  end

  defp accepts?([token | _tokens], accepted_rules) when is_list(accepted_rules) do
    token.rule in accepted_rules
  end

  defp has_more?(token) when is_bitstring(token), do: token =~ ~r{,$}

  defp has_more?(%{token: token}), do: has_more?(token)

  defp has_more?(token, []), do: has_more?(token.token)

  defp has_more?(token, [next_token | _tokens]) do
    next_token.rule == :comma or has_more?(token)
  end

  defp is_comma?(:comma), do: true
  defp is_comma?(%{rule: :comma}), do: true
  defp is_comma?(_not_comma), do: false
end
