defmodule Exrrules.RRULE do
  @moduledoc """
  RULE is a recurrence rule, a component of a recurrence set.
  """

  @months Exrrules.Language.English.months()

  defstruct freq: nil,
            interval: nil,
            count: nil,
            byday: [],
            byhour: [],
            byminute: [],
            bymonthday: [],
            byyearday: [],
            byweekno: [],
            bymonth: [],
            bysetpos: nil,
            wkst: nil,
            until: nil

  def to_string(%__MODULE__{} = attrs, prefix \\ "") do
    attrs
    |> Map.drop([:bydaypos])
    |> Map.from_struct()
    |> Enum.reject(&empty?/1)
    |> Enum.reverse()
    |> Enum.map_join(";", &stringify_options/1)
    |> then(&"#{prefix}#{&1}")
  end

  def add_freq(%__MODULE__{} = rrule, value, opts \\ [lazy: false]) do
    if opts[:lazy] do
      %{rrule | freq: rrule.freq || value}
    else
      %{rrule | freq: value}
    end
  end

  def add_count(%__MODULE__{} = rrule, value), do: %{rrule | count: value}
  def add_interval(%__MODULE__{} = rrule, value), do: %{rrule | interval: value}
  def add_until(%__MODULE__{} = rrule, value), do: %{rrule | until: value}

  def add_hour(%__MODULE__{} = rrule, value), do: update_rrule(rrule, :byhour, value)
  def add_minute(%__MODULE__{} = rrule, value), do: update_rrule(rrule, :byminute, value)

  def add_month_day(%__MODULE__{} = rrule, value), do: update_rrule(rrule, :bymonthday, value)

  def add_weekday(%__MODULE__{} = rrule, weekday, pos \\ "") do
    value =
      weekday
      |> Kernel.to_string()
      |> String.upcase()
      |> String.slice(0, 2)

    update_rrule(rrule, :byday, "#{pos}#{value}")
  end

  def add_weekdays(%__MODULE__{} = rrule) do
    rrule
    |> update_rrule(:byday, "MO")
    |> update_rrule(:byday, "TU")
    |> update_rrule(:byday, "WE")
    |> update_rrule(:byday, "TH")
    |> update_rrule(:byday, "FR")
  end

  def add_month(%__MODULE__{} = rrule, month) when is_integer(month) do
    update_rrule(rrule, :bymonth, month)
  end

  def add_month(%__MODULE__{} = rrule, month) do
    value = Enum.find_index(@months, &(&1 == month)) + 1

    add_month(rrule, value)
  end

  defp update_rrule(rrule, _key, nil), do: rrule

  defp update_rrule(rrule, key, value) do
    case Map.fetch(rrule, key) do
      :error ->
        raise "Invalid #{__MODULE__} rule: #{inspect(key)}"

      {:ok, rules} when is_list(rules) ->
        %{rrule | key => Enum.reverse([value | Enum.reverse(rules)])}

      {:ok, _rule} ->
        %{rrule | key => value}
    end
  end

  defp empty?({_key, []}), do: true
  defp empty?({_key, nil}), do: true
  defp empty?({_key, _value}), do: false

  defp stringify_options({key, value}) do
    key = key |> Kernel.to_string() |> String.upcase()
    value = value |> List.wrap() |> Enum.join(",") |> String.upcase()

    "#{key}=#{value}"
  end
end
