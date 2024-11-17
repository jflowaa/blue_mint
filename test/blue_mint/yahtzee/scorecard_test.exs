defmodule BlueMint.Yahtzee.ScorecardTests do
  use ExUnit.Case, async: true
  alias BlueMint.Yahtzee.Scorecard

  setup do
    scorecard = %Scorecard{
      user_id: "user1"
    }

    {:ok, scorecard: scorecard}
  end

  test "score_scorecard_roll/3 scores a roll correctly", %{scorecard: scorecard} do
    roll = [1, 1, 1, 1, 1]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :ones, roll)
    assert updated_scorecard.ones == 5
  end

  test "score_scorecard_roll/3 does not allow scoring a category that has already been scored", %{
    scorecard: scorecard
  } do
    scorecard = %{scorecard | ones: 3}
    roll = [1, 1, 1, 1, 1]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :ones, roll)
    assert updated_scorecard == :cannot_score
  end

  test "score_scorecard_roll/3 scores three of a kind correctly", %{scorecard: scorecard} do
    roll = [1, 1, 1, 2, 3]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :three_of_kind, roll)
    assert updated_scorecard.three_of_kind == 8
  end

  test "score_scorecard_roll/3 scores four of a kind correctly", %{scorecard: scorecard} do
    roll = [1, 1, 1, 1, 3]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :four_of_kind, roll)
    assert updated_scorecard.four_of_kind == 7
  end

  test "score_scorecard_roll/3 scores full house correctly", %{scorecard: scorecard} do
    roll = [1, 1, 1, 2, 2]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :full_house, roll)
    assert updated_scorecard.full_house == 25
  end

  test "score_scorecard_roll/3 scores small straight correctly", %{scorecard: scorecard} do
    roll = [1, 2, 3, 4, 6]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :small_straight, roll)
    assert updated_scorecard.small_straight == 30
  end

  test "score_scorecard_roll/3 score large straight correctly", %{scorecard: scorecard} do
    roll = [1, 2, 3, 4, 5]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :large_straight, roll)
    assert updated_scorecard.large_straight == 40
  end

  test "score_scorecard_roll/3 scores chance correctly", %{scorecard: scorecard} do
    roll = [1, 2, 3, 4, 5]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :chance, roll)
    assert updated_scorecard.chance == 15
  end

  test "score_scorecard_roll/3 scores yahtzee correctly", %{scorecard: scorecard} do
    roll = [6, 6, 6, 6, 6]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :yahtzee, roll)
    assert updated_scorecard.yahtzee == 50
  end

  test "score_scorecard_roll/3 does not allow yahtzee bonus if no yahtzee", %{
    scorecard: scorecard
  } do
    scorecard = %{scorecard | yahtzee: 0}
    roll = [6, 6, 6, 6, 6]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :yahtzee, roll)
    assert updated_scorecard == :cannot_score
  end

  test "score_scorecard_roll/3 handles yahtzee bonus correctly", %{scorecard: scorecard} do
    scorecard = %{scorecard | yahtzee: 50}
    roll = [6, 6, 6, 6, 6]
    updated_scorecard = Scorecard.score_scorecard_roll(scorecard, :yahtzee, roll)
    assert updated_scorecard.yahtzee_bonus == 100
  end

  test "update_totals/1 updates the totals correctly", %{scorecard: scorecard} do
    scorecard = %{scorecard | ones: 3, twos: 4, threes: 3, fours: 8, fives: 5, sixes: 12}
    updated_scorecard = Scorecard.update_totals(scorecard)
    assert updated_scorecard.upper_section == 35
    assert updated_scorecard.grand_total == 35
  end

  test "update_totals/1 includes upper section bonus if threshold is met", %{scorecard: scorecard} do
    scorecard = %{scorecard | ones: 3, twos: 6, threes: 9, fours: 12, fives: 15, sixes: 18}
    updated_scorecard = Scorecard.update_totals(scorecard)
    assert updated_scorecard.upper_section_bonus == 25
    assert updated_scorecard.grand_total == 88
  end

  test "update_totals/1 calculates lower section correctly", %{scorecard: scorecard} do
    scorecard = %{
      scorecard
      | three_of_kind: 15,
        four_of_kind: 20,
        full_house: 25,
        small_straight: 30,
        large_straight: 40,
        chance: 22,
        yahtzee: 50
    }

    updated_scorecard = Scorecard.update_totals(scorecard)
    assert updated_scorecard.lower_section == 202
    assert updated_scorecard.grand_total == 202
  end
end
