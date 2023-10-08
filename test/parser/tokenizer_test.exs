defmodule Exrrules.Parser.TokenizerTest do
  use ExUnit.Case

  alias Exrrules.Parser.{Token, Tokenizer}

  @tag :skip
  test "shortcut rules" do
    assert [:every, :days] = tokenize("daily")
  end

  test "empty strings" do
    assert [] = tokenize("")
  end

  test "tokenizer" do
    assert %Tokenizer{tokens: %{}, keywords: []} == Tokenizer.tokenize("")

    assert %Tokenizer{
             keywords: [:every, :monday, :at, :time, :comma, :number],
             tokens: %{
               at: [
                 %Token{rule: :time, value: "10am", token: "10am"},
                 %Token{rule: :comma, value: "and", token: "and"},
                 %Token{rule: :number, value: "18", token: "18"}
               ],
               every: [%Token{rule: :monday, value: "MO", token: "monday"}]
             }
           } == Tokenizer.tokenize("every monday at 10am and 18")
  end

  test "rule: dates" do
    assert [:date] = tokenize("2032-04-20")
    assert [:date] = tokenize("2032/04/20")

    assert [:date] = tokenize("20-04-2032")
    assert [:date] = tokenize("20/04/2032")

    assert [:date_text] = tokenize("Dec 15 2049")
    assert [:date_text] = tokenize("Dec 15th 2049")
    assert [:date_text] = tokenize("Dec 15th, 2049")

    # pending
    assert [:date_text] = tokenize("15 Dec 2049")
    assert [:date_text] = tokenize("15th Dec 2049")
    assert [:date_text] = tokenize("15th Dec, 2049")
  end

  test "rule: time" do
    assert [:time] = tokenize("9pm")
    assert [:time] = tokenize("9 am")
    assert [:time] = tokenize("10 am")
    assert [:time] = tokenize("12 pm")

    assert [:time] = tokenize("9:20")
    assert [:time] = tokenize("09:20")
    assert [:time] = tokenize("19:30")
    assert [:time] = tokenize("21:40")

    assert [:time] = tokenize("9:20 am")
    assert [:time] = tokenize("09:20 pm")

    # not valid, but still :time
    assert [:time] = tokenize("19:30 am")
    assert [:time] = tokenize("21:40 pm")
    assert [:time] = tokenize("16 pm")
  end

  test "rule: frequences" do
    assert [:every, :days] = tokenize("every day")
    assert [:every, :days] = tokenize("every days")
    assert [:every, :weeks] = tokenize("every week")
    assert [:every, :weeks] = tokenize("every weeks")
    assert [:every, :months] = tokenize("every month")
    assert [:every, :months] = tokenize("every months")
    assert [:every, :years] = tokenize("every year")
    assert [:every, :years] = tokenize("every years")
  end

  test "rule: intervals" do
    assert [:every, :other, :days] = tokenize("every other day")
    assert [:every, :number, :days] = tokenize("every 2 days")
    assert [:every, :number, :weeks] = tokenize("every 6 weeks")
    assert [:every, :other, :years] = tokenize("every other year")
    assert [:every, :other, :weekdays] = tokenize("every other work day")
  end

  test "rule: week days" do
    assert [:every, :monday] = tokenize("every monday")
    assert [:every, :tuesday] = tokenize("every tuesday")
    assert [:every, :wednesday] = tokenize("every wednesday")
    assert [:every, :thursday] = tokenize("every thursday")
    assert [:every, :friday] = tokenize("every friday")
    assert [:every, :saturday] = tokenize("every saturday")
    assert [:every, :sunday] = tokenize("every sunday")

    assert [:every, :weekdays] = tokenize("every weekday")
    assert [:every, :weekdays] = tokenize("every weekdays")
    assert [:every, :weekdays] = tokenize("every week day")
    assert [:every, :weekdays] = tokenize("every week days")
    assert [:every, :weekdays] = tokenize("every workday")
    assert [:every, :weekdays] = tokenize("every workdays")
    assert [:every, :weekdays] = tokenize("every work day")
    assert [:every, :weekdays] = tokenize("every work days")

    assert [:every, :weekends] = tokenize("every weekend")
    assert [:every, :weekends] = tokenize("every weekends")
  end

  test "rule: months" do
    assert [:january, :january] = tokenize("jan january")
    assert [:february, :february] = tokenize("feb february")
    assert [:march, :march] = tokenize("mar march")
    assert [:april, :april] = tokenize("apr april")
    assert [:may] = tokenize("may")
    assert [:june, :june] = tokenize("jun june")
    assert [:july, :july] = tokenize("jul july")
    assert [:august, :august] = tokenize("aug august")
    assert [:september, :september, :september] = tokenize("sep sept september")
    assert [:october, :october] = tokenize("oct october")
    assert [:november, :november] = tokenize("nov november")
    assert [:december, :december] = tokenize("dec december")
  end

  test "rule: nth" do
    assert [:nth] = tokenize("1st")
    assert [:nth, :comma, :nth] = tokenize("1st, 2nd")
    assert [:nth, :comma, :nth] = tokenize("3rd and 15th")
  end

  test "rule: relative positions" do
    assert [:first] = tokenize("first")
    assert [:second] = tokenize("second")
    assert [:third] = tokenize("third")
    assert [:next] = tokenize("next")
    assert [:last] = tokenize("last")
  end

  test "invalid rules" do
    tokens = [
      {"every hoursx", ~r{Unsupported rule "hoursx"}},
      {"every daysx", ~r{Unsupported rule "daysx"}},
      {"every weeksx", ~r{Unsupported rule "weeksx"}},
      {"every monthsx", ~r{Unsupported rule "monthsx"}},
      {"every yearsx", ~r{Unsupported rule "yearsx"}},
      # not a real time, so it doesn't match the time rule
      {"25 pm", ~r{Unsupported rule "pm"}}
    ]

    Enum.each(tokens, fn {text, regex} ->
      assert_raise RuntimeError, regex, fn -> tokenize(text) |> dbg() end
    end)
  end

  test "group tokens by keywords" do
    assert %{
             every: [%{rule: :days}],
             at: [%{rule: :number}, %{rule: :comma}, %{rule: :number}]
           } =
             "every day at 10 and 15"
             |> Tokenizer.tokenize()
             |> Map.get(:tokens)

    assert %{
             every: [%{rule: :days}],
             at: [%{rule: :number}],
             starting: [%{rule: :on}, %{rule: :the}, %{rule: :nth}]
           } =
             "every day at 10 starting on the 15th"
             |> Tokenizer.tokenize()
             |> Map.get(:tokens)
  end

  defp tokenize(input, _opts \\ []) do
    input
    |> Tokenizer.tokenize()
    |> Map.get(:keywords)
  end
end
