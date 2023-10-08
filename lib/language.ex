defmodule Exrrules.Language do
  @moduledoc false

  def new(lang \\ "en") do
    case lang do
      "en" -> Exrrules.Language.English
      _ -> raise "Language not supported: #{inspect(lang)}"
    end
  end
end
