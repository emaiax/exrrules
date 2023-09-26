defmodule Exrrules.ParserTest do
  use ExUnit.Case

  alias Exrrules.Parser

  test "error handling" do
    assert_raise RuntimeError, "Unexpected end", fn -> Parser.to_rrules("every day at") end

    assert_raise RuntimeError, "Invalid token found \"nope\"", fn ->
      Parser.to_rrules("every day at nope")
    end
  end

  test "parse text date" do
    assert ~D[2048-07-13] == Parser.parse_date("2048-07-13")
    assert ~D[2049-12-15] == Parser.parse_date("Dec 15 2049")
    assert ~D[2049-12-15] == Parser.parse_date("Dec 15, 2049")
  end

  test "days" do
    assert Parser.to_rrules("every day") == "FREQ=DAILY"
    assert Parser.to_rrules("every day at 9") == "FREQ=DAILY;BYHOURS=9"
    assert Parser.to_rrules("every 4 days") == "INTERVAL=4;FREQ=DAILY"
    assert Parser.to_rrules("every 5 days at 8") == "INTERVAL=5;FREQ=DAILY;BYHOURS=8"
    assert Parser.to_rrules("every other day") == "INTERVAL=2;FREQ=DAILY"
    assert Parser.to_rrules("every other day at 10") == "INTERVAL=2;FREQ=DAILY;BYHOURS=10"
  end

  test "multiple times" do
    assert Parser.to_rrules("every day at 9, 15, 20") == "FREQ=DAILY;BYHOURS=9,15,20"
    assert Parser.to_rrules("every day at 9 and 15") == "FREQ=DAILY;BYHOURS=9,15"
    assert Parser.to_rrules("every day at 9 or 20") == "FREQ=DAILY;BYHOURS=9,20"
    assert Parser.to_rrules("every day at 9, 12 and 15") == "FREQ=DAILY;BYHOURS=9,12,15"
  end

  test "special week days" do
    assert Parser.to_rrules("every weekday") == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
    assert Parser.to_rrules("every weekday at 8") == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOURS=8"

    assert Parser.to_rrules("every workday") == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
    assert Parser.to_rrules("every workday at 8") == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOURS=8"

    # assert Parser.to_rrules("every work day") == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
    # assert Parser.to_rrules("every work day at 8") == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOURS=8"
    # assert Parser.to_rrules("every week day") == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
    # assert Parser.to_rrules("every week day at 8") == "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOURS=8"
  end

  test "week days" do
    assert Parser.to_rrules("every mo") == "FREQ=WEEKLY;BYDAY=MO"
    assert Parser.to_rrules("every mon") == "FREQ=WEEKLY;BYDAY=MO"
    assert Parser.to_rrules("every monday") == "FREQ=WEEKLY;BYDAY=MO"
    assert Parser.to_rrules("every monday at 8") == "FREQ=WEEKLY;BYDAY=MO;BYHOURS=8"
    assert Parser.to_rrules("every other monday") == "INTERVAL=2;FREQ=WEEKLY;BYDAY=MO"

    assert Parser.to_rrules("every tu") == "FREQ=WEEKLY;BYDAY=TU"
    assert Parser.to_rrules("every tue") == "FREQ=WEEKLY;BYDAY=TU"
    assert Parser.to_rrules("every tuesday") == "FREQ=WEEKLY;BYDAY=TU"
    assert Parser.to_rrules("every tuesday at 10") == "FREQ=WEEKLY;BYDAY=TU;BYHOURS=10"
    assert Parser.to_rrules("every other tuesday") == "INTERVAL=2;FREQ=WEEKLY;BYDAY=TU"

    assert Parser.to_rrules("every we") == "FREQ=WEEKLY;BYDAY=WE"
    assert Parser.to_rrules("every wed") == "FREQ=WEEKLY;BYDAY=WE"
    assert Parser.to_rrules("every wednesday") == "FREQ=WEEKLY;BYDAY=WE"
    assert Parser.to_rrules("every other wednesday") == "INTERVAL=2;FREQ=WEEKLY;BYDAY=WE"
    assert Parser.to_rrules("every wednesday at 12") == "FREQ=WEEKLY;BYDAY=WE;BYHOURS=12"

    assert Parser.to_rrules("every thu") == "FREQ=WEEKLY;BYDAY=TH"
    assert Parser.to_rrules("every thur") == "FREQ=WEEKLY;BYDAY=TH"
    assert Parser.to_rrules("every thursday") == "FREQ=WEEKLY;BYDAY=TH"
    assert Parser.to_rrules("every thursday at 14") == "FREQ=WEEKLY;BYDAY=TH;BYHOURS=14"
    assert Parser.to_rrules("every other thursday") == "INTERVAL=2;FREQ=WEEKLY;BYDAY=TH"

    assert Parser.to_rrules("every fr") == "FREQ=WEEKLY;BYDAY=FR"
    assert Parser.to_rrules("every fri") == "FREQ=WEEKLY;BYDAY=FR"
    assert Parser.to_rrules("every friday") == "FREQ=WEEKLY;BYDAY=FR"
    assert Parser.to_rrules("every friday at 16") == "FREQ=WEEKLY;BYDAY=FR;BYHOURS=16"
    assert Parser.to_rrules("every other friday") == "INTERVAL=2;FREQ=WEEKLY;BYDAY=FR"
  end

  test "month names" do
    assert Parser.to_rrules("every jan") == "FREQ=YEARLY;BYMONTH=1"
    assert Parser.to_rrules("every feb") == "FREQ=YEARLY;BYMONTH=2"
    assert Parser.to_rrules("every mar") == "FREQ=YEARLY;BYMONTH=3"
    assert Parser.to_rrules("every apr") == "FREQ=YEARLY;BYMONTH=4"
    assert Parser.to_rrules("every may") == "FREQ=YEARLY;BYMONTH=5"
    assert Parser.to_rrules("every june") == "FREQ=YEARLY;BYMONTH=6"
    assert Parser.to_rrules("every july") == "FREQ=YEARLY;BYMONTH=7"
    assert Parser.to_rrules("every august") == "FREQ=YEARLY;BYMONTH=8"
    assert Parser.to_rrules("every september") == "FREQ=YEARLY;BYMONTH=9"
    assert Parser.to_rrules("every october") == "FREQ=YEARLY;BYMONTH=10"
    assert Parser.to_rrules("every november") == "FREQ=YEARLY;BYMONTH=11"
    assert Parser.to_rrules("every december") == "FREQ=YEARLY;BYMONTH=12"
  end

  test "multiple week days" do
    assert Parser.to_rrules("every monday and tuesday") == "FREQ=WEEKLY;BYDAY=MO,TU"

    # assert Parser.to_rrules("every monday, wednesday and friday") == "FREQ=WEEKLY;BYDAY=MO,WE,FR"

    # assert Parser.to_rrules("every monday and tuesday at 10") ==
    #          "FREQ=WEEKLY;BYDAY=MO,TU;BYHOUR=10"

    # assert Parser.to_rrules("every monday, wednesday and friday at 12 and 20") ==
    #          "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=12,20"
  end

  test "weeks" do
    assert Parser.to_rrules("every week") == "FREQ=WEEKLY"
    # assert Parser.to_rrules("every week on friday") == "FREQ=WEEKLY;BYDAY=FR"
    # assert Parser.to_rrules("every other week on monday") == "INTERVAL=2;FREQ=WEEKLY;BYDAY=MO"
    assert Parser.to_rrules("every week at 9") == "FREQ=WEEKLY;BYHOURS=9"
    assert Parser.to_rrules("every 2 weeks") == "INTERVAL=2;FREQ=WEEKLY"
    assert Parser.to_rrules("every 2 weeks at 8") == "INTERVAL=2;FREQ=WEEKLY;BYHOURS=8"
    assert Parser.to_rrules("every other week") == "INTERVAL=2;FREQ=WEEKLY"
    assert Parser.to_rrules("every other week at 10") == "INTERVAL=2;FREQ=WEEKLY;BYHOURS=10"
  end

  test "months" do
    assert Parser.to_rrules("every month") == "FREQ=MONTHLY"
    assert Parser.to_rrules("every month at 9") == "FREQ=MONTHLY;BYHOURS=9"
    assert Parser.to_rrules("every 2 months") == "INTERVAL=2;FREQ=MONTHLY"
    assert Parser.to_rrules("every 2 months at 8") == "INTERVAL=2;FREQ=MONTHLY;BYHOURS=8"
    assert Parser.to_rrules("every other month") == "INTERVAL=2;FREQ=MONTHLY"
    assert Parser.to_rrules("every other month at 10") == "INTERVAL=2;FREQ=MONTHLY;BYHOURS=10"
  end

  test "until" do
    # assert Parser.to_rrules("every day until 2032-02-07") == "FREQ=DAILY;UNTIL=20320207T000000Z"

    # assert Parser.to_rrules("every day at 10 until Dec 15 2049") ==
    # "FREQ=DAILY;BYHOURS=10;UNTIL=20491215T000000Z"

    assert Parser.to_rrules("every other day at 3 until Dec 15, 2049") ==
             "INTERVAL=2;FREQ=DAILY;BYHOURS=3;UNTIL=20491215T000000Z"
  end
end
