defmodule Exrrules.ParserTest do
  use ExUnit.Case

  alias Exrrules.Parser

  test "rule: interval" do
    assert %{rrule: %{freq: :daily, interval: 5}} = Parser.parse("every 5 days")
    assert %{rrule: %{freq: :daily, interval: 2}} = Parser.parse("every other day")
    assert %{rrule: %{freq: :hourly, interval: 2}} = Parser.parse("every other hour")
    assert %{rrule: %{freq: :weekly, interval: 2}} = Parser.parse("every other week")
    assert %{rrule: %{freq: :weekly, interval: 2}} = Parser.parse("every two weeks")
    assert %{rrule: %{freq: :monthly, interval: 3}} = Parser.parse("every three months")
  end

  test "rule: every" do
    assert %{rrule: %{freq: :hourly}} = Parser.parse("every hour")
    assert %{rrule: %{freq: :daily}} = Parser.parse("every day")
    assert %{rrule: %{freq: :weekly}} = Parser.parse("every week")
    assert %{rrule: %{freq: :monthly}} = Parser.parse("every month")
    assert %{rrule: %{freq: :yearly}} = Parser.parse("every year")

    assert %{rrule: %{freq: :weekly, byday: ~w(FR SA)}} =
             Parser.parse("every friday and saturday")

    assert %{rrule: %{freq: :weekly, byday: ~w(FR SA SU)}} =
             Parser.parse("every friday, saturday and sunday")

    assert %{rrule: %{freq: :weekly, byday: ~w(MO TU WE TH FR)}} =
             Parser.parse("every weekday")

    assert %{rrule: %{freq: :monthly, bymonthday: [1, 15]}} =
             Parser.parse("every 1st and 15th")

    assert %{rrule: %{freq: :yearly, bymonth: [1, 4, 9]}} =
             Parser.parse("every january, april and september")

    # TODO: support dates:
    # - we need to change the English.rules() to support simple dates as `month day`
    # - we need to convert rules to structs so we can hold more configurations or
    #   multiples regexes only to void very long regex lines, allowing commas and such
    #
    # assert %{rrule: %{freq: :yearly, bymonth: [1, 4, 9]}} =
    #          Parser.parse("every january 1st, april 15th and september 30th")
  end

  test "rule: at" do
    assert %{rrule: %{freq: :weekly, byhour: [10, 17], byday: ~w(MO TU WE TH FR)}} =
             Parser.parse("every weekday at 10 and 17")

    assert %{rrule: %{freq: :daily, byhour: [10], byminute: []}} =
             Parser.parse("every day at 10")

    assert %{rrule: %{freq: :daily, byhour: [10], byminute: []}} =
             Parser.parse("every day at 10am")

    assert %{rrule: %{freq: :daily, byhour: [22], byminute: []}} =
             Parser.parse("every day at 10 pm")

    assert %{rrule: %{freq: :daily, byhour: [10], byminute: [30]}} =
             Parser.parse("every day at 10:30")

    assert %{rrule: %{freq: :daily, byhour: [10], byminute: [30]}} =
             Parser.parse("every day at 10:30am")

    assert %{rrule: %{freq: :daily, byhour: [22], byminute: [30]}} =
             Parser.parse("every day at 10:30 pm")

    assert_raise RuntimeError, ~r{:at group: .* :monday}, fn ->
      Parser.parse("every weekday at mondays")
    end

    assert_raise RuntimeError, ~r{:at group: .* :april}, fn ->
      Parser.parse("every weekday at april")
    end
  end

  test "rule: (on|in)" do
    assert %{rrule: %{freq: :weekly, byday: ~w(MO)}} = Parser.parse("every day on mondays")

    assert %{rrule: %{freq: :weekly, byday: ~w(MO WE FR)}} =
             Parser.parse("every week on monday, wednesday and friday")

    assert %{rrule: %{freq: :weekly, byday: ~w(MO), interval: 2}} =
             Parser.parse("every week on other mondays")

    assert %{rrule: %{freq: :hourly, byday: ~w(MO TU WE TH FR), bymonth: [4, 12]}} =
             Parser.parse("every hour on april and december on weekdays")

    assert %{rrule: %{freq: :hourly, byday: ~w(MO TU WE TH FR), bymonth: [4, 12]}} =
             Parser.parse("every hour in april and december on weekdays")

    assert %{rrule: %{freq: :hourly, byday: ~w(MO TU WE TH FR), bymonth: [4, 12]}} =
             Parser.parse("every hour on weekdays in april and december")

    assert %{rrule: %{freq: :hourly, byday: ~w(MO TU WE TH FR), bymonth: [4, 12]}} =
             Parser.parse("every hour on weekdays of april and december")
  end

  test "rule: for" do
    assert %{rrule: %{freq: :daily, count: 20}} = Parser.parse("every day for 20 times")
    assert %{rrule: %{freq: :monthly, count: 12}} = Parser.parse("every month for 12 times")
  end

  test "mixed rules" do
    assert %{
             rrule: %{
               count: 3,
               interval: 2,
               freq: :hourly,
               byday: ~w(MO TU WE TH FR),
               byhour: [9, 18],
               bymonth: [4, 12]
             }
           } =
             Parser.parse(
               "every other hour on weekdays of april and december at 9 and 18 for 3 times"
             )
  end

  test "rule: relatives" do
    assert %{rrule: %{freq: :monthly, bymonthday: [1]}} = Parser.parse("every 1st day")
    assert %{rrule: %{freq: :monthly, bymonthday: [1]}} = Parser.parse("every first day")
    assert %{rrule: %{freq: :monthly, bymonthday: [2]}} = Parser.parse("every second day")
    assert %{rrule: %{freq: :monthly, bymonthday: [-1]}} = Parser.parse("every last day")

    assert %{rrule: %{freq: :monthly, byday: ["+1FR"]}} = Parser.parse("every 1st friday")

    assert %{rrule: %{freq: :monthly, bymonthday: [15]}} =
             Parser.parse("every month on the 15th")

    assert %{rrule: %{freq: :yearly, byday: ["+1FR"]}} =
             Parser.parse("every year on the 1st friday")

    assert %{rrule: %{freq: :monthly, byday: ["+1FR", "-1TU"]}} =
             Parser.parse("every month on the first friday and last tuesday")

    assert %{rrule: %{freq: :monthly, byday: ["+1FR", "+1SA", "-1TU"]}} =
             Parser.parse("every month on the first friday and saturday and last tuesday")

    assert %{rrule: %{freq: :yearly, bymonth: [1], bymonthday: [1]}} =
             Parser.parse("every january on the first day")

    assert %{rrule: %{freq: :yearly, bymonth: [1], bymonthday: [-1]}} =
             Parser.parse("every january on the last day")

    assert %{rrule: %{freq: :yearly, bymonth: [1], bymonthday: [15]}} =
             Parser.parse("every january on the 15th")

    assert %{rrule: %{freq: :yearly, bymonth: [4], byday: ["+4FR"]}} =
             Parser.parse("every april on the fourth friday")
  end
end
