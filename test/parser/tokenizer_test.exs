defmodule Exrrules.Parser.TokenizerTest do
  use ExUnit.Case

  alias Exrrules.Parser.{Token, Tokenizer}

  @tag :skip
  test "shortcut rules" do
    assert [:every, :days] = keywords("daily")
    assert [:every, :week] = keywords("weekly")
  end

  test "empty strings" do
    assert [] = keywords("")
  end

  test "tokenizer" do
    assert %Tokenizer{tokens: %{}, keywords: []} == Tokenizer.tokenize("")

    assert %Tokenizer{
             keywords: [:every, :monday, :at, :time, :comma, :time],
             tokens: %{
               every: [%Token{rule: :monday, value: "MO", token: "monday"}],
               at: [
                 [
                   %Token{rule: :time, token: "10:45", value: %{hour: 10, minute: 45}},
                   %Token{rule: :comma, value: "and", token: "and"},
                   %Token{rule: :time, token: "6pm", value: %{hour: 18, minute: nil}}
                 ]
               ]
             }
           } = Tokenizer.tokenize("every monday at 10:45 and 6pm")
  end

  test "rule: dates" do
    # yyyy-mm-dd
    #
    assert [:date] = keywords("2032-04-20")
    assert [:date] = keywords("2032/04/20")

    # yyyy-dd-mm
    #
    assert [:date] = keywords("2032-20-04")
    assert [:date] = keywords("2032/20/04")

    # dd-mm-yyyy
    #
    assert [:date] = keywords("20-04-2032")
    assert [:date] = keywords("20/04/2032")

    # mm-dd-yyyy
    #
    assert [:date] = keywords("04-20-2032")
    assert [:date] = keywords("04/20/2032")

    # month dd yyyy
    # month ddth yyyy
    # month ddth, yyyy
    #
    assert [:date_text] = keywords("Dec 15 2049")
    assert [:date_text] = keywords("Dec 15th 2049")
    assert [:date_text] = keywords("Dec 15th, 2049")

    # dd month yyyy
    # ddth month yyyy
    # ddth month, yyyy
    #
    assert [:date_text] = keywords("15 Dec 2049")
    assert [:date_text] = keywords("15th Dec 2049")
    assert [:date_text] = keywords("15th Dec, 2049")

    # assert [:date_text] = keywords("15 dec")
    # assert [:date_text] = keywords("15, dec")
    # assert [:date_text] = keywords("15th dec")
    # assert [:date_text] = keywords("15th, dec")

    # assert [:date_text] = keywords("dec 15")
    # assert [:date_text] = keywords("dec 15th")
    # assert [:date_text] = keywords("dec, 15")
    # assert [:date_text] = keywords("dec, 15th")
  end

  test "rule: time" do
    assert [:time] = keywords("9pm")
    assert [:time] = keywords("9 am")
    assert [:time] = keywords("10 am")
    assert [:time] = keywords("12 pm")

    assert [:time] = keywords("9:20")
    assert [:time] = keywords("09:20")
    assert [:time] = keywords("19:30")
    assert [:time] = keywords("21:40")

    assert [:time] = keywords("9:20 am")
    assert [:time] = keywords("09:20 pm")

    # full format with am/pm is invalid, then we should ignore the time modified (am/pm)
    assert [:time] = keywords("19:30 am")
    assert [:time] = keywords("21:40 pm")
    assert [:time] = keywords("16 pm")
  end

  test "rule: frequences" do
    assert [:every, :days] = keywords("every day")
    assert [:every, :days] = keywords("every days")
    assert [:every, :weeks] = keywords("every week")
    assert [:every, :weeks] = keywords("every weeks")
    assert [:every, :months] = keywords("every month")
    assert [:every, :months] = keywords("every months")
    assert [:every, :years] = keywords("every year")
    assert [:every, :years] = keywords("every years")
  end

  test "rule: intervals" do
    assert [:every, :other, :days] = keywords("every other day")
    assert [:every, :number, :days] = keywords("every 2 days")
    assert [:every, :number, :weeks] = keywords("every 6 weeks")
    assert [:every, :other, :years] = keywords("every other year")
    assert [:every, :other, :weekdays] = keywords("every other work day")
  end

  test "rule: week days" do
    assert [:every, :monday] = keywords("every monday")
    assert [:every, :tuesday] = keywords("every tuesday")
    assert [:every, :wednesday] = keywords("every wednesday")
    assert [:every, :thursday] = keywords("every thursday")
    assert [:every, :friday] = keywords("every friday")
    assert [:every, :saturday] = keywords("every saturday")
    assert [:every, :sunday] = keywords("every sunday")

    assert [:every, :weekdays] = keywords("every weekday")
    assert [:every, :weekdays] = keywords("every weekdays")
    assert [:every, :weekdays] = keywords("every week day")
    assert [:every, :weekdays] = keywords("every week days")
    assert [:every, :weekdays] = keywords("every workday")
    assert [:every, :weekdays] = keywords("every workdays")
    assert [:every, :weekdays] = keywords("every work day")
    assert [:every, :weekdays] = keywords("every work days")

    assert [:every, :weekends] = keywords("every weekend")
    assert [:every, :weekends] = keywords("every weekends")
  end

  test "rule: months" do
    assert [:january, :january] = keywords("jan january")
    assert [:february, :february] = keywords("feb february")
    assert [:march, :march] = keywords("mar march")
    assert [:april, :april] = keywords("apr april")
    assert [:may] = keywords("may")
    assert [:june, :june] = keywords("jun june")
    assert [:july, :july] = keywords("jul july")
    assert [:august, :august] = keywords("aug august")
    assert [:september, :september, :september] = keywords("sep sept september")
    assert [:october, :october] = keywords("oct october")
    assert [:november, :november] = keywords("nov november")
    assert [:december, :december] = keywords("dec december")
  end

  test "rule: nth" do
    assert [:nth] = keywords("1st")
    assert [:nth, :comma, :nth] = keywords("1st, 2nd")
    assert [:nth, :comma, :nth] = keywords("3rd and 15th")
  end

  test "rule: relative positions" do
    assert [:first, :monday] = keywords("first monday")
    assert [:second, :tuesday] = keywords("second tuesday")
    assert [:third, :wednesday] = keywords("third wednesday")
    assert [:fourth, :thursday] = keywords("fourth thursday")
    assert [:last, :friday] = keywords("last friday")
  end

  test "invalid rules" do
    tokens = [
      {"every hoursx", ~r{Unsupported token found: "hoursx"}},
      {"every daysx", ~r{Unsupported token found: "daysx"}},
      {"every weeksx", ~r{Unsupported token found: "weeksx"}},
      {"every monthsx", ~r{Unsupported token found: "monthsx"}},
      {"every yearsx", ~r{Unsupported token found: "yearsx"}},
      # removed support of :next rule
      {"every next", ~r{Unsupported token found: "next"}},
      # not a real time, so it doesn't match the time rule
      {"25 pm", ~r{Unsupported token found: "pm"}}
    ]

    Enum.each(tokens, fn {text, regex} ->
      assert_raise RuntimeError, regex, fn ->
        keywords(text)
      end
    end)
  end

  test "grouped tokens" do
    assert %{
             every: [
               {
                 %{rule: :first},
                 [
                   %{rule: :monday},
                   %{rule: :comma},
                   %{rule: :friday},
                   %{rule: :comma},
                   %{rule: :sunday}
                 ]
               }
             ]
           } = tokens("every first monday, friday and sunday")

    assert %{
             every: [
               {
                 %{rule: :first},
                 [
                   %{rule: :monday},
                   %{rule: :comma},
                   %{rule: :tuesday}
                 ]
               },
               %{rule: :comma},
               {
                 %{rule: :last},
                 %{rule: :friday}
               }
             ],
             at: [
               [
                 %{rule: :number},
                 %{rule: :comma},
                 %{rule: :number}
               ]
             ]
           } = tokens("every first monday and tuesday and last friday at 10 and 19")

    assert %{
             every: [%{rule: :days}],
             at: [
               %{rule: :time},
               %{rule: :comma},
               [
                 %{rule: :number},
                 %{rule: :comma},
                 %{rule: :number}
               ]
             ]
           } = tokens("every day at 10am and 14, 18")

    assert %{
             every: [%{rule: :january}],
             on: [%{rule: :nth}]
           } = tokens("every january on the 7th")

    assert %{
             every: [%{rule: :january}],
             on: [%{rule: :nth}]
           } = tokens("every january on the 7th")
  end

  defp keywords(input) do
    input
    |> Tokenizer.tokenize()
    |> Map.get(:keywords)
  end

  defp tokens(input) do
    input
    |> Tokenizer.tokenize()
    |> Map.get(:tokens)
  end
end
