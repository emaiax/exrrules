defmodule Exrrules.Parser.Token do
  defstruct rule: nil,
            value: nil,
            token: nil

  def new(rule, token) do
    %__MODULE__{rule: rule, value: build_value(rule, token), token: String.trim(token)}
  end

  def build_value(:monday, _token), do: "MO"
  def build_value(_, token), do: token
end
