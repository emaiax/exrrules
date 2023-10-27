defmodule Exrrules.Language.Rule do
  @moduledoc """
  Base module for language rules.

  Options:
    - allow_comma: boolean, default: false
    - keyword: boolean, default: false
    - group: group this rule belongs, default: nil
    - patterns: list of "regex" strings, default: []
  """
  defstruct [:allow_comma, :name, :group, :keyword, :patterns]
end
