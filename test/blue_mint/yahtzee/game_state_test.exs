defmodule BlueMint.Yahtzee.GameStateTest do
  use ExUnit.Case, async: true
  alias BlueMint.Yahtzee.GameState
  alias BlueMint.Yahtzee.Scorecard

  setup do
    initial_state = %GameState{
      lobby_id: "lobby1",
      started?: false,
      joinable?: true,
      user_turn: nil,
      users: [],
      rolls: 0,
      dice: [1, 2, 3, 4, 5],
      scorecards: []
    }

    {:ok, initial_state: initial_state}
  end

  test "add_user/2 adds a user to the game", %{initial_state: state} do
    {:ok, new_state} = GameState.add_user(state, "user1")
    assert new_state.users == ["user1"]
  end

  test "add_user/2 does not add a user if already joined", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:already_joined, state} = GameState.add_user(state, "user1")
    assert state.users == ["user1"]
  end

  test "add_user/2 does not add a user if game is full", %{initial_state: state} do
    state = %{state | users: Enum.map(1..10, fn x -> "user#{x}" end)}

    {:full, state} = GameState.add_user(state, "user11")

    assert state.users == Enum.map(1..10, fn x -> "user#{x}" end)
  end

  test "remove_user/2 removes a user from the game", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, new_state} = GameState.remove_user(state, "user1")
    assert new_state.users == []
  end

  test "remove_user/2 does not remove a user not in the game", %{initial_state: state} do
    {:not_in_game, state} = GameState.remove_user(state, "user1")
    assert state.users == []
  end

  test "start_game/1 starts the game if conditions are met", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, new_state} = GameState.start_game(state)
    assert new_state.started? == true
    assert new_state.joinable? == false
  end

  test "start_game/1 does not start the game if already started", %{initial_state: state} do
    state = %{state | started?: true}
    {{:cannot_start, "Already started"}, state} = GameState.start_game(state)
    assert state.started? == true
  end

  test "roll/2 rolls the dice for the current user", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, state} = GameState.start_game(state)
    {:ok, new_state} = GameState.roll(state, state.user_turn)
    assert new_state.rolls == 1
  end

  test "roll/2 no more rolls for the current user hand", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, state} = GameState.start_game(state)
    {:ok, state} = GameState.roll(state, state.user_turn)
    {:ok, state} = GameState.roll(state, state.user_turn)
    {:ok, state} = GameState.roll(state, state.user_turn)
    {:no_more_rolls, new_state} = GameState.roll(state, state.user_turn)
    assert new_state.dice == state.dice
    assert new_state.rolls == 3
  end

  test "score/3 scores the current user's roll", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, state} = GameState.start_game(state)
    {:ok, state} = GameState.roll(state, state.user_turn)
    {:ok, new_state} = GameState.score(state, state.user_turn, :ones)
    assert length(new_state.scorecards) == 1
    assert new_state.user_turn != state.user_turn
  end

  test "score/3 is able to get next user by rolling over user list", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {:ok, state} = GameState.add_user(state, "user3")
    {{:ok, _user_turn}, state} = GameState.start_game(state)
    state = Map.put(state, :user_turn, "user3")
    {:ok, state} = GameState.roll(state, state.user_turn)
    {:ok, new_state} = GameState.score(state, state.user_turn, :ones)
    assert length(new_state.scorecards) == 1
    assert new_state.user_turn == "user1"
  end

  test "score/3 returns :all_scorecards_complete when all scorecards are complete", %{
    initial_state: state
  } do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, state} = GameState.start_game(state)

    complete_scorecard = %Scorecard{
      ones: 3,
      twos: 6,
      threes: 9,
      fours: 12,
      fives: 15,
      sixes: 18,
      three_of_kind: 25,
      four_of_kind: 30,
      full_house: 40,
      small_straight: 30,
      large_straight: 40,
      yahtzee: 50,
      chance: 20
    }

    state =
      Map.put(state, :scorecards, [
        complete_scorecard |> Map.put(:user_id, "user1") |> Map.put(:ones, nil),
        Map.put(complete_scorecard, :user_id, "user2")
      ])
      |> Map.put(:user_turn, "user1")

    {:ok, state} = GameState.roll(state, state.user_turn)
    {result, _state} = GameState.score(state, state.user_turn, :ones)
    assert result == :all_scorecards_complete
  end
end
