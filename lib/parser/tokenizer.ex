defmodule Exrrules.Parser.Tokenizer do
  @moduledoc false

  defstruct tokens: %{}, keywords: []

  alias Exrrules.Parser.Token

  @base_rules Exrrules.Language.English.rules()
  @group_rules ~w(every on at for starting until)a

  # Function to tokenize the input string
  def tokenize(input) when is_binary(input) do
    {:ok, tokens} = tokenize(String.downcase(input), [], @base_rules)

    %__MODULE__{
      keywords: Enum.map(tokens, & &1.rule),
      tokens: group_tokens(tokens)
    }
  end

  # Base case: when the input string is empty
  defp tokenize("", tokens, _keywords) do
    {:ok, Enum.reverse(tokens)}
  end

  # Match keywords at the beginning of the input string
  defp tokenize(input, tokens, keywords) do
    case find_matching_keyword(input, keywords) do
      {keyword, rest} ->
        tokenize(rest, [keyword | tokens], keywords)

      _ ->
        {:ok, Enum.reverse(tokens), input}
    end
  end

  # Helper function to find a matching keyword at the beginning of the string
  defp find_matching_keyword(input, keywords) do
    case Enum.find(keywords, fn {_rule, regex} -> input =~ regex end) do
      {rule, regex} ->
        {match, rest} =
          case Regex.split(regex, input, include_captures: true, trim: true) do
            # last match, no more tokens
            [match] ->
              {match, ""}

            [match | [rest]] ->
              {match, String.trim(rest)}

            other ->
              raise "Can't tokenize #{inspect(other)} from #{inspect(input)}"
          end

        {%Token{rule: rule, token: String.trim(match)}, rest}

      _ ->
        invalid_token =
          input
          |> String.split(" ")
          |> List.first()

        raise "Unsupported rule #{inspect(invalid_token)}"
    end
  end

  # Function to group tokens by keywords
  def group_tokens(tokens, keywords \\ @group_rules) do
    group_tokens(tokens, keywords, %{current_group: nil})
  end

  # Base case: when there are no more tokens
  defp group_tokens([], _keywords, result) do
    Map.drop(result, [:current_group])
  end

  # Recursive case: `:on` is a special case, it can be used in multiple ways:
  #
  # - `every day until on 10th`, denotes an ending date
  # - `every day until on the 10th`, denotes an ending date
  # - `every day starting on the 10th`, denotes a starting date
  # - `every day starting on the 10th`, denotes a starting date
  #
  # Any other variation other then these denotes a change in frequency.
  #
  # Whenever we capture an `:on` that denotes a starting or ending dates,
  # we must not close the current group.
  defp group_tokens([%{rule: :on} = token | rest], keywords, %{current_group: group} = result)
       when group in ~w(starting until)a do
    tokens = Enum.reverse([token | Enum.reverse(result[group])])

    group_tokens(rest, keywords, Map.put(result, group, tokens))
  end

  # Recursive case: process the next token
  defp group_tokens([token | rest], keywords, result) do
    current_group = Map.get(result, :current_group)

    group_tokens =
      result
      |> Map.get(current_group, [])
      |> Enum.reverse()

    # token is a group?
    case Enum.member?(keywords, token.rule) do
      true ->
        # token group found, close the current group and start a new one
        result =
          result
          |> Map.put(token.rule, [])
          |> Map.put(:current_group, token.rule)

        group_tokens(rest, keywords, result)

      false ->
        # Non-keyword tokens, add it to the current group
        tokens = Enum.reverse([token | group_tokens])

        group_tokens(rest, keywords, Map.put(result, current_group, tokens))
    end
  end
end
