defmodule Exrrules.Language do
  @moduledoc false

  defstruct rules: [],
            day_names: [],
            month_names: []

  def init(lang \\ "en") do
    language =
      case lang do
        "en" -> Exrrules.Language.English
        _ -> raise "Language not supported"
      end

    %__MODULE__{
      rules: language.rules(),
      day_names: language.day_names(),
      month_names: language.month_names()
    }
  end
end
