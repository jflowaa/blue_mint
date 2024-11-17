defmodule BlueMint.Yahtzee.Scorecard do
  use Ecto.Schema

  @upper_section [:ones, :twos, :threes, :fours, :fives, :sixes]
  @upper_section_bonus_threshold 62
  @upper_section_bonus 25
  @lower_section [
    :three_of_kind,
    :four_of_kind,
    :full_house,
    :small_straight,
    :large_straight,
    :chance,
    :yahtzee
  ]
  @yahtzee_bonus 100

  @primary_key {:id, :string, autogenerate: false}

  schema "scorecard" do
    field(:user_id, :string)
    field(:ones, :integer)
    field(:twos, :integer)
    field(:threes, :integer)
    field(:fours, :integer)
    field(:fives, :integer)
    field(:sixes, :integer)
    field(:upper_section, :integer, default: 0)
    field(:upper_section_bonus, :integer, default: 0)
    field(:upper_section_total, :integer, default: 0)
    field(:three_of_kind, :integer)
    field(:four_of_kind, :integer)
    field(:full_house, :integer)
    field(:small_straight, :integer)
    field(:large_straight, :integer)
    field(:chance, :integer)
    field(:yahtzee, :integer)
    field(:yahtzee_bonus, :integer, default: 0)
    field(:lower_section, :integer, default: 0)
    field(:grand_total, :integer, default: 0)
  end

  def score_scorecard_roll(scorecard, category, roll) do
    cond do
      Map.get(scorecard, category, nil) != nil ->
        if category == :yahtzee and scorecard.yahtzee == 50 do
          if yahtzee(roll) == 50 do
            Map.put(scorecard, :yahtzee_bonus, scorecard.yahtzee_bonus + @yahtzee_bonus)
          else
            :cannot_score
          end
        else
          :cannot_score
        end

      true ->
        Map.put(scorecard, category, determine_score(roll, category))
    end
  end

  def update_totals(scorecard) do
    scorecard
    |> Map.put(:upper_section, get_upper_section_score(scorecard))
    |> Map.put(
      :upper_section_bonus,
      if(has_upper_section_bonus?(scorecard),
        do: @upper_section_bonus,
        else: 0
      )
    )
    |> Map.put(
      :upper_section_total,
      get_upper_section_score(scorecard) + Map.get(scorecard, :upper_section_bonus, 0)
    )
    |> Map.put(:lower_section, get_lower_section_score(scorecard))
    |> Map.put(:grand_total, get_grand_total(scorecard))
  end

  defp determine_score(roll, category) do
    case category do
      :ones -> count_dice(roll, 1) * 1
      :twos -> count_dice(roll, 2) * 2
      :threes -> count_dice(roll, 3) * 3
      :fours -> count_dice(roll, 4) * 4
      :fives -> count_dice(roll, 5) * 5
      :sixes -> count_dice(roll, 6) * 6
      :three_of_kind -> score_of_kind(roll, 3)
      :four_of_kind -> score_of_kind(roll, 4)
      :full_house -> full_house(roll)
      :small_straight -> small_straight(roll)
      :large_straight -> large_straight(roll)
      :chance -> total_dice(roll)
      :yahtzee -> yahtzee(roll)
    end
  end

  defp total_dice(roll), do: Enum.reduce(roll, 0, fn x, acc -> acc + x end)

  defp count_dice(roll, number),
    do: Enum.reduce(roll, 0, fn x, acc -> if x == number, do: acc + x, else: acc end)

  defp score_of_kind(roll, kind),
    do:
      if(Enum.any?(Enum.uniq(roll), fn x -> count_dice(roll, x) >= kind end),
        do: Enum.reduce(roll, 0, fn x, acc -> acc + x end),
        else: 0
      )

  defp full_house(roll), do: if(Enum.uniq(roll) |> Enum.count() == 2, do: 25, else: 0)

  defp small_straight(roll) do
    sorted_roll = Enum.sort(Enum.uniq(roll))

    has_straight =
      Enum.any?([[1, 2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]], fn seq ->
        Enum.all?(seq, &Enum.member?(sorted_roll, &1))
      end)

    if has_straight, do: 30, else: 0
  end

  defp large_straight(roll), do: if(Enum.uniq(roll) |> Enum.count() == 5, do: 40, else: 0)

  defp yahtzee(roll), do: if(Enum.uniq(roll) |> Enum.count() == 1, do: 50, else: 0)

  defp get_upper_section_score(scorecard),
    do:
      Enum.reduce(@upper_section, 0, fn x, acc ->
        score = Map.get(scorecard, x, 0)
        if score == nil, do: acc, else: acc + score
      end)

  defp get_lower_section_score(scorecard),
    do:
      Enum.reduce(@lower_section, 0, fn x, acc ->
        score = Map.get(scorecard, x, 0)
        if score == nil, do: acc, else: acc + score
      end)

  defp has_upper_section_bonus?(scorecard),
    do: get_upper_section_score(scorecard) >= @upper_section_bonus_threshold

  defp get_grand_total(scorecard) do
    upper_section_score = get_upper_section_score(scorecard)
    lower_section_score = get_lower_section_score(scorecard)
    grand_total = upper_section_score + lower_section_score + scorecard.yahtzee_bonus

    if has_upper_section_bonus?(scorecard) do
      grand_total + @upper_section_bonus
    else
      grand_total
    end
  end
end
