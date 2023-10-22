defmodule Exrrules.Parser.TimeParser do
  @regex ~r/(?<hours>\d{1,2})(?::(?<minutes>\d{2}))?\s*(?<period>am|pm)?/i

  def extract_time_components(time_str) do
    case Regex.named_captures(@regex, time_str) do
      %{"hours" => hours, "minutes" => minutes, "period" => period} ->
        %{
          hour: hour_to_integer(hours, period),
          minute: convert(minutes)
        }

      _ ->
        raise "Invalid time format"
    end
  end

  defp convert(""), do: nil
  defp convert("00"), do: nil
  defp convert(value), do: String.to_integer(value)

  defp hour_to_integer(hours, "pm"), do: String.to_integer(hours) + 12
  defp hour_to_integer(hours, _period), do: String.to_integer(hours)
end
