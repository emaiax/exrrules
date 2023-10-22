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
      |> Enum.reject(&Token.is_jibberish?/1)
      |> group_commas()
      |> group_relatives()
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

        raise "Unsupported token found: #{inspect(invalid_token)}"
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

  # Recursive: process all tokens to find the `:relative`s to group
  #
  defp group_relatives(tokens, acc \\ [])

  defp group_relatives([], acc), do: Enum.reverse(acc)

  # Recursive: when relative found, we get the next token to check if it's a valid relative group
  #
  defp group_relatives([%{rule_group: :relative} = relative | tokens], acc) do
    {absolute, tokens} =
      case Enum.at(tokens, 0) do
        %{rule_group: :month} ->
          List.pop_at(tokens, 0)

        %{rule_group: :weekday} ->
          List.pop_at(tokens, 0)

        rules when is_list(rules) ->
          List.pop_at(tokens, 0)

        unsupported_relative ->
          if relative.rule in [:last, :next] && Enum.empty?(tokens) do
            raise "Can't find valid token after #{inspect(relative.rule)}: #{inspect(unsupported_relative)})}"
          else
            {nil, tokens}
          end
      end

    if absolute do
      group_relatives(tokens, [{relative, absolute} | acc])
    else
      group_relatives([absolute | tokens], [relative | acc])
    end
  end

  defp group_relatives([token | tokens], acc), do: group_relatives(tokens, [token | acc])

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
       when group in ~w(starting until on)a do
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

  # Recursive case: token is a relative-group
  defp group_tokens([{relative, absolute} | rest], keywords, result) do
    current_group = Map.get(result, :current_group)

    group_tokens =
      result
      |> Map.get(current_group, [])
      |> Enum.reverse()

    tokens = Enum.reverse([{relative, absolute} | group_tokens])

    group_tokens(rest, keywords, Map.put(result, current_group, tokens))
  end

  # Recursive case: token is nil only when relative couldn't match a valid absolute, so we just skip it
  defp group_tokens([nil | rest], keywords, result) do
    group_tokens(rest, keywords, result)
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
        # when we open groups, we expect to find a token after it
        if Enum.empty?(rest), do: raise("Unexpected end after #{inspect(token.rule)}")

        result =
          result
          |> Map.put(token.rule, [])
          |> Map.put(:current_group, token.rule)

        group_tokens(rest, keywords, result)

      # Non-keyword tokens, add it to the current group
      false ->
        # if token is relative and there are no more tokens to process, we raise an exception
        if Token.is_relative?(token) && Enum.empty?(rest) do
          raise "Can't find matching token after #{inspect(token.rule)}"
        end

        # check for interval only on the very first token inside :every group
        token =
          if current_group == :every && Enum.empty?(group_tokens) do
            is_interval =
              case token.rule do
                # every other day | every other monday
                :other ->
                  true

                rule when rule in [:nth, :number, :number_text] ->
                  case Enum.at(rest, 0) do
                    # every 2nd | every first
                    nil -> false
                    # every 7 feb | 2nd june | every first april
                    %{rule_group: :month} -> false
                    # every 2nd day | every 3rd week | every 3 months
                    _is_interval -> true
                  end

                _not_interval ->
                  false
              end

            if is_interval, do: Token.force_interval!(token), else: token
          else
            token
          end

        tokens = Enum.reverse([token | group_tokens])

        group_tokens(rest, keywords, Map.put(result, current_group, tokens))
    end
  end
end
