defmodule Exrrules.Parser.BatchTest do
  use ExUnit.Case

  @moduletag :batch

  alias Exrrules.Parser

  @text_cases [
    # {"daily at 10 and 17", "FREQ=DAILY;BYHOUR=10,17"},
    # {"daily at 10", "FREQ=DAILY;BYHOUR=10"},
    {"every week day at 8", "FREQ=WEEKLY;BYHOUR=8;BYDAY=MO,TU,WE,TH,FR"},
    {"every week day", "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"},
    {"every work day at 8", "FREQ=WEEKLY;BYHOUR=8;BYDAY=MO,TU,WE,TH,FR"},
    {"every work day", "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"},
    # {"weekly on mondays and fridays", "FREQ=WEEKLY;BYDAY=MO,FR"},
    # {"weekly on mondays", "FREQ=WEEKLY;BYDAY=MO"},
    {"every 16th april", "FREQ=YEARLY;BYMONTHDAY=16;BYMONTH=4"},
    {"every 2 days", "INTERVAL=2;FREQ=DAILY"},
    {"every 2 months at 8", "INTERVAL=2;FREQ=MONTHLY;BYHOUR=8"},
    {"every 2 months", "INTERVAL=2;FREQ=MONTHLY"},
    {"every 2 weeks at 8", "INTERVAL=2;FREQ=WEEKLY;BYHOUR=8"},
    {"every 2 weeks", "INTERVAL=2;FREQ=WEEKLY"},
    {"every 4 days", "INTERVAL=4;FREQ=DAILY"},
    {"every 4 hours", "INTERVAL=4;FREQ=HOURLY"},
    {"every 5 days at 8", "INTERVAL=5;FREQ=DAILY;BYHOUR=8"},
    {"every 6 months", "INTERVAL=6;FREQ=MONTHLY"},
    {"every 7 feb", "INTERVAL=7;FREQ=YEARLY;BYMONTH=2"},
    {"every apr", "FREQ=YEARLY;BYMONTH=4"},
    {"every april 16th", "FREQ=YEARLY;BYMONTHDAY=16;BYMONTH=4"},
    {"every august", "FREQ=YEARLY;BYMONTH=8"},
    {"every day at 10 until Dec 15 2049", "UNTIL=20491215T000000Z;FREQ=DAILY;BYHOUR=10"},
    {"every day at 10, 12 and 17", "FREQ=DAILY;BYHOUR=10,12,17"},
    {"every day at 9 and 15", "FREQ=DAILY;BYHOUR=9,15"},
    {"every day at 9 or 20", "FREQ=DAILY;BYHOUR=9,20"},
    {"every day at 9, 12 and 15", "FREQ=DAILY;BYHOUR=9,12,15"},
    {"every day at 9, 15, 20", "FREQ=DAILY;BYHOUR=9,15,20"},
    {"every day at 9", "FREQ=DAILY;BYHOUR=9"},
    {"every day for 10 times", "FREQ=DAILY;COUNT=10"},
    {"every day until 2032-02-07", "UNTIL=20320207T000000Z;FREQ=DAILY"},
    {"every day", "FREQ=DAILY"},
    {"every december", "FREQ=YEARLY;BYMONTH=12"},
    {"every feb 7", "FREQ=YEARLY;BYMONTHDAY=7;BYMONTH=2"},
    {"every feb", "FREQ=YEARLY;BYMONTH=2"},
    {"every fr", "FREQ=WEEKLY;BYDAY=FR"},
    {"every fri", "FREQ=WEEKLY;BYDAY=FR"},
    {"every friday at 16", "FREQ=WEEKLY;BYHOUR=16;BYDAY=FR"},
    {"every friday", "FREQ=WEEKLY;BYDAY=FR"},
    {"every hour", "FREQ=HOURLY"},
    {"every jan", "FREQ=YEARLY;BYMONTH=1"},
    {"every january, april and november", "FREQ=YEARLY;BYMONTH=1,4,11"},
    {"every july", "FREQ=YEARLY;BYMONTH=7"},
    {"every june", "FREQ=YEARLY;BYMONTH=6"},
    {"every mar", "FREQ=YEARLY;BYMONTH=3"},
    {"every may on the 4th", "FREQ=YEARLY;BYMONTHDAY=4;BYMONTH=5"},
    {"every may", "FREQ=YEARLY;BYMONTH=5"},
    {"every mo", "FREQ=WEEKLY;BYDAY=MO"},
    {"every mon", "FREQ=WEEKLY;BYDAY=MO"},
    {"every monday and tuesday at 10", "FREQ=WEEKLY;BYHOUR=10;BYDAY=MO,TU"},
    {"every monday and tuesday", "FREQ=WEEKLY;BYDAY=MO,TU"},
    {"every monday and wednesday on january", "FREQ=WEEKLY;BYMONTH=1;BYDAY=MO,WE"},
    {"every monday at 8", "FREQ=WEEKLY;BYHOUR=8;BYDAY=MO"},
    {"every monday on january", "FREQ=WEEKLY;BYMONTH=1;BYDAY=MO"},
    {"every monday, wednesday and friday at 12 and 20",
     "FREQ=WEEKLY;BYHOUR=12,20;BYDAY=MO,WE,FR"},
    {"every monday, wednesday and friday", "FREQ=WEEKLY;BYDAY=MO,WE,FR"},
    {"every monday", "FREQ=WEEKLY;BYDAY=MO"},
    {"every month at 9", "FREQ=MONTHLY;BYHOUR=9"},
    {"every month on the 2nd last friday", "FREQ=MONTHLY;BYDAY=-2FR"},
    {"every month on the 3rd last tuesday", "FREQ=MONTHLY;BYDAY=-3TU"},
    {"every month on the 3rd tuesday", "FREQ=MONTHLY;BYDAY=+3TU"},
    {"every month on the 4th last", "FREQ=MONTHLY;BYMONTHDAY=-4"},
    {"every month on the first monday", "FREQ=MONTHLY;BYDAY=+1MO"},
    {"every month on the last monday", "FREQ=MONTHLY;BYDAY=-1MO"},
    {"every month on the weekdays", "FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR"},
    {"every month", "FREQ=MONTHLY"},
    {"every november", "FREQ=YEARLY;BYMONTH=11"},
    {"every october", "FREQ=YEARLY;BYMONTH=10"},
    {"every other day at 10", "INTERVAL=2;FREQ=DAILY;BYHOUR=10"},
    {"every other day at 3 until Dec 15, 2049",
     "UNTIL=20491215T000000Z;INTERVAL=2;FREQ=DAILY;BYHOUR=3"},
    {"every other day", "INTERVAL=2;FREQ=DAILY"},
    {"every other friday", "INTERVAL=2;FREQ=WEEKLY;BYDAY=FR"},
    {"every other monday and wednesday on january and april",
     "INTERVAL=2;FREQ=WEEKLY;BYMONTH=1,4;BYDAY=MO,WE"},
    {"every other monday", "INTERVAL=2;FREQ=WEEKLY;BYDAY=MO"},
    {"every other month at 10", "INTERVAL=2;FREQ=MONTHLY;BYHOUR=10"},
    {"every other month", "INTERVAL=2;FREQ=MONTHLY"},
    {"every other thursday", "INTERVAL=2;FREQ=WEEKLY;BYDAY=TH"},
    {"every other tuesday", "INTERVAL=2;FREQ=WEEKLY;BYDAY=TU"},
    {"every other wednesday", "INTERVAL=2;FREQ=WEEKLY;BYDAY=WE"},
    {"every other week at 10", "INTERVAL=2;FREQ=WEEKLY;BYHOUR=10"},
    {"every other week on monday", "INTERVAL=2;FREQ=WEEKLY;BYDAY=MO"},
    {"every other week", "INTERVAL=2;FREQ=WEEKLY"},
    {"every september", "FREQ=YEARLY;BYMONTH=9"},
    {"every thu", "FREQ=WEEKLY;BYDAY=TH"},
    {"every thur", "FREQ=WEEKLY;BYDAY=TH"},
    {"every thursday at 14", "FREQ=WEEKLY;BYHOUR=14;BYDAY=TH"},
    {"every thursday", "FREQ=WEEKLY;BYDAY=TH"},
    {"every tu", "FREQ=WEEKLY;BYDAY=TU"},
    {"every tue", "FREQ=WEEKLY;BYDAY=TU"},
    {"every tuesday at 10", "FREQ=WEEKLY;BYHOUR=10;BYDAY=TU"},
    {"every tuesday", "FREQ=WEEKLY;BYDAY=TU"},
    {"every we", "FREQ=WEEKLY;BYDAY=WE"},
    {"every wed", "FREQ=WEEKLY;BYDAY=WE"},
    {"every wednesday at 12", "FREQ=WEEKLY;BYHOUR=12;BYDAY=WE"},
    {"every wednesday", "FREQ=WEEKLY;BYDAY=WE"},
    {"every week at 9", "FREQ=WEEKLY;BYHOUR=9"},
    {"every week for 20 times", "FREQ=WEEKLY;COUNT=20"},
    {"every week for 3 times", "FREQ=WEEKLY;COUNT=3"},
    {"every week on friday", "FREQ=WEEKLY;BYDAY=FR"},
    {"every week on monday, wednesday", "FREQ=WEEKLY;BYDAY=MO,WE"},
    {"every week on saturdays and sundays", "FREQ=WEEKLY;BYDAY=SA,SU"},
    {"every week on tuesday", "FREQ=WEEKLY;BYDAY=TU"},
    {"every week until dec 31, 2023", "UNTIL=20231231T000000Z;FREQ=WEEKLY"},
    {"every week until january 1, 2007", "UNTIL=20070101T000000Z;FREQ=WEEKLY"},
    {"every week", "FREQ=WEEKLY"},
    {"every weekday at 8", "FREQ=WEEKLY;BYHOUR=8;BYDAY=MO,TU,WE,TH,FR"},
    {"every weekday", "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"},
    {"every workday at 8", "FREQ=WEEKLY;BYHOUR=8;BYDAY=MO,TU,WE,TH,FR"},
    {"every workday", "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"},
    {"every year on the 13th friday", "FREQ=YEARLY;BYDAY=+13FR"},
    {"every year on the 1st friday", "FREQ=YEARLY;BYDAY=+1FR"},
    {"every year on the first friday", "FREQ=YEARLY;BYDAY=+1FR"}
  ]

  @error_cases [
    {"every", "Unexpected end"},
    {"every day at", "Unexpected end"},
    {"every day at nope", "Invalid token found \"nope\""},
    {"every day for 10", "Invalid token, expected :times, got :number. Maybe :times is missing?"},
    {"every day for day times", quote(do: ~r{^Invalid :for rules found: .* :days})},
    {"every day for 2 weeks times", quote(do: ~r{^Invalid :for rules found: .* :weeks})}
  ]

  describe "[batch]" do
    for {text, rrule} <- @text_cases do
      test text do
        assert Parser.to_rrule(unquote(text)) == unquote(rrule)
      end
    end
  end

  describe "[batch: exceptions]" do
    for {text, error} <- @error_cases do
      test text do
        assert_raise RuntimeError, unquote(error), fn -> Parser.to_rrule(unquote(text)) end
      end
    end
  end

  test "lang no supported" do
    assert_raise RuntimeError, "Language not supported: \"xpto\"", fn ->
      Parser.parse("every day", "xpto")
    end
  end
end
