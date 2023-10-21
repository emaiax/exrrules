defmodule Exrrules.Parser.Tokenizer do
  @moduledoc false

  defstruct tokens: %{}, keywords: []

  alias Exrrules.Parser.Token

  @base_rules Exrrules.Language.English.rules()
  @group_rules ~w(every on at for starting until)a

  def tokenize(input) when input in [nil, ""], do: struct(__MODULE__)

  # Function to tokenize the input string
  def tokenize(input) when is_binary(input) do
    {:ok, tokens} =
      input
      |> String.downcase()
      |> tokenize([], @base_rules)

    grouped_tokens =
      tokens
      |> group_commas()
      |> group_tokens()

    %__MODULE__{
      keywords: Enum.map(tokens, & &1.rule),
      tokens: grouped_tokens
    }
  end

  # Base case: when the input string is finished
  defp tokenize(nil, tokens, _keywords) do
    {:ok, Enum.reverse(tokens)}
  end

  # Match keywords at the beginning of the input string
  defp tokenize(input, tokens, keywords) do
    case find_matching_keyword(input, keywords) do
      {nil, nil} -> {:ok, Enum.reverse(tokens), input}
      {keyword, rest} -> tokenize(rest, [keyword | tokens], keywords)
    end
  end

  # Helper function to find a matching keyword at the beginning of the string
  defp find_matching_keyword(nil, _keywords), do: {nil, nil}

  # Helper function to find a matching keyword at the beginning of the string
  defp find_matching_keyword(input, keywords) do
    case Enum.find(keywords, fn {_rule, regex} -> input =~ regex end) do
      {rule, regex} ->
        {match, rest} =
          case Regex.split(regex, input, include_captures: true, trim: true) do
            # last match, no more tokens
            [match] ->
              {match, nil}

            [match | [rest]] ->
              {match, String.trim(rest)}

            other ->
              raise "Can't tokenize #{inspect(other)} from #{inspect(input)}"
          end

        {Token.new(rule, String.trim(match)), rest}

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

  # Recursive case: token is a comma-group
  defp group_tokens([comma_group | rest], keywords, result) when is_list(comma_group) do
    current_group = Map.get(result, :current_group)

    group_tokens =
      result
      |> Map.get(current_group, [])
      |> Enum.reverse()

    tokens = Enum.reverse([comma_group | group_tokens])

    group_tokens(rest, keywords, Map.put(result, current_group, tokens))
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
      # token group found, close the current group and start a new one
      true ->
        result =
          result
          |> Map.put(token.rule, [])
          |> Map.put(:current_group, token.rule)

        group_tokens(rest, keywords, result)

      # Non-keyword tokens, add it to the current group
      false ->
        # if token is relative, but input is empty, we need to raise an error
        if token.rule in Exrrules.Language.English.relatives() && Enum.empty?(rest) do
          raise "Can't find matching token after #{inspect(token.rule)}"
        end

        tokens = Enum.reverse([token | group_tokens])

        group_tokens(rest, keywords, Map.put(result, current_group, tokens))
    end
  end

  # Recursive: process all tokens to find the `:comma`s to group
  #
  defp group_commas(tokens, acc \\ [])

  defp group_commas([], acc), do: Enum.reverse(acc)

  # Recursive: when comma found, we get the boundaries to check if it's a valid comma group
  #
  # - `friday and monday`: [:friday, :comma, :monday]
  # - `first friday and monday`: [:first, [:friday, :comma, :monday]]
  # - `first monday and last sunday`: [:first, :monday, :comma, :last, :sunday]
  # - `first monday and tuesday and last saturday and sunday`: [:first, [:monday, :comma, :tuesday], :comma, :last, [:saturday, :comma, :sunday]]
  #
  defp group_commas([%{rule: :comma} = comma | tokens], acc) do
    # previous_token is in the head of the `acc`
    {prev_token, acc} = List.pop_at(acc, 0)
    # next_token is the next after comma in the `tokens`
    {next_token, tokens} = List.pop_at(tokens, 0)

    if comma_group?(prev_token, next_token) do
      group_commas(tokens, [List.flatten([prev_token, comma, next_token]) | acc])
    else
      # if it's not a comma group, then we must add prev_token and comma to the `acc`
      # as they'll be processed individually
      acc =
        acc
        |> List.insert_at(0, prev_token)
        |> List.insert_at(0, comma)

      # add next_token to the `tokens` as it'll be processed in the next iteration
      group_commas([next_token | tokens], acc)
    end
  end

  defp group_commas([token | tokens], acc), do: group_commas(tokens, [token | acc])

  defp comma_group?([prev_token, _comma, next_token], token) do
    comma_group?(prev_token, token) || comma_group?(next_token, token)
  end

  defp comma_group?(%{rule: rule}, %{rule: rule}), do: true

  defp comma_group?(%{rule_group: rule_group}, %{rule_group: rule_group})
       when not is_nil(rule_group),
       do: true

  defp comma_group?(_prev_token, _next_token), do: false
end
