defmodule Exrrules.Language.English do
  @moduledoc false

  def months do
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

  def weekdays do
    [
      :monday,
      :tuesday,
      :wednesday,
      :thursday,
      :friday,
      :saturday,
      :sunday
    ]
  end

  def rules do
    month_names =
      "jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|june?|july?|aug(ust)?|sep(t(ember)?)?|oct(ober)?|nov(ember)?|dec(ember)?"

    [
      # todo: support different date formats
      #
      # date:
      #
      #   - yyyy-mm-dd, yyyy/mm/dd
      #   - yyyy-dd-mm, yyyy/dd/mm
      #   - dd-mm-yyyy, dd/mm/yyyy
      #   - mm-dd-yyyy, mm/dd/yyyy
      #
      date: "(\\d{4}(-|/)\\d{2}(-|/)\\d{2})|(\\d{2}(-|/)\\d{2}(-|/)\\d{4})",
      #
      # date_text:
      #
      #   - month day year
      #   - month day, year
      #   - day month year
      #   - day month, year
      #
      date_text: """
      (?:#{month_names})\\s+(\\d{1,2})(?:st|nd|rd|th)?,?\\s+(\\d{4})
      |
      (\\d{1,2})(?:st|nd|rd|th)?\\s+(?:#{month_names}),?\\s+(\\d{4})
      """,
      #
      # time: (with and without am/pm space)
      #
      #   - h am
      #   - hh pm
      #   - hh:mm
      #   - hh:mm am
      #   - hh:mm pm
      #
      time:
        "(?:1[0-2]|0?[1-9]|2[0-3]|[01]?[0-9])(?:(:[0-5][0-9](?:\\s*(am|pm))?)|(?:\\s*(am|pm)))",
      #
      # numbers
      #
      other: "other",
      nth: {"([1-9][0-9]*)(th|nd|rd|st)", allow_comma: true},
      number: {"[1-9][0-9]*", allow_comma: true},
      number_text: {"(one|two|three|four)", allow_comma: true},

      # relative positions
      #
      first: "first",
      second: "second",
      third: "third",
      fourth: "fourth",
      next: "next",
      last: "last",

      # keywords
      #
      every: "every",
      on: "(on|in)",
      at: "(at)",
      of: "of",
      the: "the",
      for: "for",
      times: "times?",
      until: "until",
      starting: "starting",

      # frequence
      #
      weekdays: "(week|work)\\s?days?",
      weekends: "weekends?",
      days: "days?",
      weeks: "weeks?",
      hours: "hours?",
      minutes: "minutes?",
      months: "months?",
      years: "years?",

      # weekdays
      #
      monday: {"mo(n(days?)?)?", allow_comma: true},
      tuesday: {"^tu(e(s(days?)?)?)?", allow_comma: true},
      wednesday: {"^we(d(n(esdays?)?)?)?", allow_comma: true},
      thursday: {"^th(u(r(sdays?)?)?)?", allow_comma: true},
      friday: {"^fr(i(days?)?)?", allow_comma: true},
      saturday: {"^sa(t(urdays?)?)?", allow_comma: true},
      sunday: {"^su(n(days?)?)?", allow_comma: true},

      # months
      #
      january: {"jan(uary)?", allow_comma: true},
      february: {"feb(ruary)?", allow_comma: true},
      march: {"mar(ch)?", allow_comma: true},
      april: {"apr(il)?", allow_comma: true},
      may: {"may", allow_comma: true},
      june: {"june?", allow_comma: true},
      july: {"july?", allow_comma: true},
      august: {"aug(ust)?", allow_comma: true},
      september: {"sep(t(ember)?)?", allow_comma: true},
      october: {"oct(ober)?", allow_comma: true},
      november: {"nov(ember)?", allow_comma: true},
      december: {"dec(ember)?", allow_comma: true},

      # separators
      #
      comma: "(,\\s*|(and|or)\\s*)+"
    ]
    |> Enum.map(&process_rule_regex/1)
  end

  defp process_rule_regex(rule, opts \\ [])

  defp process_rule_regex({rule, {pattern, opts}}, _opts),
    do: process_rule_regex({rule, pattern}, opts)

  defp process_rule_regex({rule, pattern}, opts) do
    suffix =
      case opts[:allow_comma] do
        # ?= is a positive lookahead assertion that matches the suffix and does not includes it in the match
        true -> "(?=,|\\s|$)"
        # ?: is a non-capturing group that matches the suffix but does not include it in the match
        _ -> "(?:\\s|$)"
      end

    pattern = String.replace(pattern, ~r{\n*}, "")
    # if rule == :date_text, do: dbg(~r(^#{pattern}#{suffix}))

    {rule, ~r(^#{pattern}#{suffix})}
  end
end
