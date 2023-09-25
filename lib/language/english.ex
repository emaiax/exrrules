defmodule Exrrules.Language.English do
  @moduledoc false

  def day_names do
    [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ]
  end

  def month_names do
    [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ]
  end

  def months_rules do
    [
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
  end

  def rules do
    [
      skip: ~r/^[ \r\n\t]+|^\.$/,
      other: ~r/^other$/,
      number: ~r/^[1-9][0-9]*/,
      numberAsText: ~r/^(one|two|three)/i,
      every: ~r/^every/i,
      days: ~r/^days?/i,
      weekdays: ~r/^weekdays?/i,
      workdays: ~r/^work\s?days?/i,
      weeks: ~r/^weeks?/i,
      hours: ~r/^hours?/i,
      minutes: ~r/^minutes?/i,
      months: ~r/^months?/i,
      years: ~r/^years?/i,
      on: ~r/^(on|in)/i,
      at: ~r/^(at)/i,
      the: ~r/^the/i,
      first: ~r/^first/i,
      second: ~r/^second/i,
      third: ~r/^third/i,
      nth: ~r/^([1-9][0-9]*)(\.|th|nd|rd|st)/i,
      last: ~r/^last/i,
      for: ~r/^for/i,
      times: ~r/^times?/i,
      until: ~r/^(un)?til/i,
      monday: ~r/^mo(n(day)?)?/i,
      tuesday: ~r/^tu(e(s(day)?)?)?/i,
      wednesday: ~r/^we(d(n(esday)?)?)?/i,
      thursday: ~r/^th(u(r(sday)?)?)?/i,
      friday: ~r/^fr(i(day)?)?/i,
      saturday: ~r/^sa(t(urday)?)?/i,
      sunday: ~r/^su(n(day)?)?/i,
      january: ~r/^jan(uary)?/i,
      february: ~r/^feb(ruary)?/i,
      march: ~r/^mar(ch)?/i,
      april: ~r/^apr(il)?/i,
      may: ~r/^may/i,
      june: ~r/^june?/i,
      july: ~r/^july?/i,
      august: ~r/^aug(ust)?/i,
      september: ~r/^sep(t(ember)?)?/i,
      october: ~r/^oct(ober)?/i,
      november: ~r/^nov(ember)?/i,
      december: ~r/^dec(ember)?/i,
      comma: ~r/^(,\s*|(and|or)\s*)+/i
    ]
  end
end
