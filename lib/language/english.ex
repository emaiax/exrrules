defmodule Exrrules.Language.English do
  @moduledoc false

  alias Exrrules.Language.Rule

  @month_names "jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|june?|july?|aug(ust)?|sep(t(ember)?)?|oct(ober)?|nov(ember)?|dec(ember)?"

  def rules do
    [
      # keywords
      #
      Rule.new(name: :every, patterns: ~w(every), keyword: true),
      Rule.new(name: :on, patterns: ~w(on|in), keyword: true),
      Rule.new(name: :at, patterns: ~w(at), keyword: true),
      Rule.new(name: :until, patterns: ~w(until), keyword: true),
      Rule.new(name: :starting, patterns: ~w(starting), keyword: true),
      # times is optional, but if exists, it can only exist inside a :for group
      Rule.new(name: :for, patterns: ~w(for), keyword: true),
      Rule.new(name: :times, patterns: ~w(times?), keyword: true),

      # maybe remove all garbage and ensure :skip can catch-all?
      Rule.new(name: :of, patterns: ~w(of)),
      Rule.new(name: :the, patterns: ~w(the)),

      # todo: support different date formats
      #
      # date:
      #
      #   - yyyy-mm-dd, yyyy/mm/dd
      #   - yyyy-dd-mm, yyyy/dd/mm
      #   - dd-mm-yyyy, dd/mm/yyyy
      #   - mm-dd-yyyy, mm/dd/yyyy
      #
      Rule.new(
        name: :date,
        patterns: ["(\\d{4}(-|/)\\d{2}(-|/)\\d{2})|(\\d{2}(-|/)\\d{2}(-|/)\\d{4})"]
      ),
      #
      # date_text:
      #
      #   - month day year
      #   - month day, year
      #   - day month year
      #   - day month, year
      #
      Rule.new(
        name: :date_text,
        patterns: [
          "(?:#{@month_names})\\s+(\\d{1,2})(?:st|nd|rd|th)?,?\\s+(\\d{4})",
          "(\\d{1,2})(?:st|nd|rd|th)?\\s+(?:#{@month_names}),?\\s+(\\d{4})"
        ]
      ),
      #
      # time: (with and without am/pm space)
      #
      #   - h am
      #   - hh pm
      #   - hh:mm
      #   - hh:mm am
      #   - hh:mm pm
      #
      Rule.new(
        name: :time,
        patterns: [
          "(?:1[0-2]|0?[1-9]|2[0-3]|[01]?[0-9])(?:(:[0-5][0-9](?:\\s*(am|pm))?)|(?:\\s*(am|pm)))"
        ]
      ),
      #
      # numbers
      #
      Rule.new(name: :other, patterns: ~w(other)),
      Rule.new(name: :nth, patterns: ["([1-9][0-9]*)(th|nd|rd|st)"], allow_comma: true),
      Rule.new(name: :number, patterns: ["[1-9][0-9]*"], allow_comma: true),
      Rule.new(name: :number_text, patterns: ["(one|two|three|four)"], allow_comma: true),

      # relative positions
      #
      # next: "next", do we really want to support next/past?
      Rule.new(name: :first, patterns: ~w(first)),
      Rule.new(name: :second, patterns: ~w(second)),
      Rule.new(name: :third, patterns: ~w(third)),
      Rule.new(name: :fourth, patterns: ~w(fourth)),
      Rule.new(name: :last, patterns: ~w(last)),

      # frequence
      #
      Rule.new(name: :weekdays, patterns: ["(week|work)\\s?days?"]),
      Rule.new(name: :weekends, patterns: ["weekends?"]),
      Rule.new(name: :minutes, patterns: ["minutes?"]),
      Rule.new(name: :hours, patterns: ["hours?"]),
      Rule.new(name: :days, patterns: ["days?"]),
      Rule.new(name: :weeks, patterns: ["weeks?"]),
      Rule.new(name: :months, patterns: ["months?"]),
      Rule.new(name: :years, patterns: ["years?"]),

      # weekdays
      #
      Rule.new(name: :monday, patterns: ["mo(n(days?)?)?"], allow_comma: true),
      Rule.new(name: :tuesday, patterns: ["^tu(e(s(days?)?)?)?"], allow_comma: true),
      Rule.new(name: :wednesday, patterns: ["^we(d(n(esdays?)?)?)?"], allow_comma: true),
      Rule.new(name: :thursday, patterns: ["^th(u(r(sdays?)?)?)?"], allow_comma: true),
      Rule.new(name: :friday, patterns: ["^fr(i(days?)?)?"], allow_comma: true),
      Rule.new(name: :saturday, patterns: ["^sa(t(urdays?)?)?"], allow_comma: true),
      Rule.new(name: :sunday, patterns: ["^su(n(days?)?)?"], allow_comma: true),

      # months
      #
      Rule.new(name: :january, patterns: ["jan(uary)?"], allow_comma: true),
      Rule.new(name: :february, patterns: ["feb(ruary)?"], allow_comma: true),
      Rule.new(name: :march, patterns: ["mar(ch)?"], allow_comma: true),
      Rule.new(name: :april, patterns: ["apr(il)?"], allow_comma: true),
      Rule.new(name: :may, patterns: ["may"], allow_comma: true),
      Rule.new(name: :june, patterns: ["june?"], allow_comma: true),
      Rule.new(name: :july, patterns: ["july?"], allow_comma: true),
      Rule.new(name: :august, patterns: ["aug(ust)?"], allow_comma: true),
      Rule.new(name: :september, patterns: ["sep(t(ember)?)?"], allow_comma: true),
      Rule.new(name: :october, patterns: ["oct(ober)?"], allow_comma: true),
      Rule.new(name: :november, patterns: ["nov(ember)?"], allow_comma: true),
      Rule.new(name: :december, patterns: ["dec(ember)?"], allow_comma: true),

      # separators
      #
      Rule.new(name: :comma, patterns: ["(,\\s*|(and|or)\\s*)+"])
    ]
  end
end
