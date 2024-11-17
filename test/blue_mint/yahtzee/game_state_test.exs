defmodule BlueMint.Yahtzee.GameStateTest do
  use ExUnit.Case, async: true
  alias BlueMint.Yahtzee.GameState

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
    state = %{state | users: ["user1", "user2"]}
    {:full, state} = GameState.add_user(state, "user3")
    assert state.users == ["user1", "user2"]
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

  test "score/3 scores the current user's roll", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, state} = GameState.start_game(state)
    {:ok, state} = GameState.roll(state, state.user_turn)
    {:ok, new_state} = GameState.score(state, state.user_turn, :ones)
    assert length(new_state.scorecards) == 1
  end
end
