defmodule BlueMint.TicTacToe.GameStateTest do
  use ExUnit.Case, async: true
  alias BlueMint.TicTacToe.GameState

  setup do
    initial_state = %GameState{
      lobby_id: "lobby1",
      started?: false,
      joinable?: true,
      board: ["", "", "", "", "", "", "", "", ""],
      user_turn: nil,
      users: []
    }

    {:ok, initial_state: initial_state}
  end

  test "add_user/2 adds a user to an empty game", %{initial_state: state} do
    {:ok, new_state} = GameState.add_user(state, "user1")
    assert new_state.users == ["user1"]
  end

  test "add_user/2 adds a user to a game with one user", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, new_state} = GameState.add_user(state, "user2")
    assert new_state.users == ["user1", "user2"]
    assert new_state.joinable? == false
  end

  test "add_user/2 does not add a user who is already in the game", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:already_joined, _state} = GameState.add_user(state, "user1")
  end

  test "add_user/2 does not add a user to a full game", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {:full, _state} = GameState.add_user(state, "user3")
  end

  test "remove_user/2 removes a user who is in the game", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, new_state} = GameState.remove_user(state, "user1")
    assert new_state.users == []
    assert new_state.joinable? == true
  end

  test "remove_user/2 does not remove a user who is not in the game", %{initial_state: state} do
    {:not_in_game, _state} = GameState.remove_user(state, "user1")
  end

  test "start_game/1 returns :cannot_start if the game is already started", %{
    initial_state: state
  } do
    state = Map.put(state, :started?, true)
    {{:cannot_start, "Already started"}, _state} = GameState.start_game(state)
  end

  test "start_game/1 returns :cannot_start if the game is still joinable", %{initial_state: state} do
    state = Map.put(state, :joinable?, true)

    {{:cannot_start, "Still open for users to join"}, _state} = GameState.start_game(state)
  end

  test "start_game/1 starts the game if there are exactly two users", %{initial_state: state} do
    state = Map.put(state, :users, ["user1", "user2"]) |> Map.put(:joinable?, false)
    {{:ok, user_turn}, new_state} = GameState.start_game(state)
    assert new_state.started? == true
    assert new_state.joinable? == false
    assert new_state.user_turn in ["user1", "user2"]
    assert new_state.user_turn == user_turn
    assert new_state.board == ["", "", "", "", "", "", "", "", ""]
  end

  test "start_game/1 returns :cannot_start if there are less than two users", %{
    initial_state: state
  } do
    state = Map.put(state, :users, ["user1"])
    {{:cannot_start, "Still open for users to join"}, _state} = GameState.start_game(state)
  end

  test "move/3 returns :not_started if the game is not started", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {:not_started, _state} = GameState.move(state, "user1", 0)
  end

  test "move/3 returns :not_your_turn if it's not the user's turn", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    state = Map.put(state, :started?, true) |> Map.put(:user_turn, "user1")
    {:not_your_turn, _state} = GameState.move(state, "user2", 0)
  end

  test "move/3 returns :invalid_move if the position is occupied", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    state = Map.put(state, :started?, true) |> Map.put(:user_turn, "user1")
    {:ok, state} = GameState.move(state, "user1", 0)
    {:invalid_move, _state} = GameState.move(state, "user2", 0)
  end

  test "move/3 makes a valid move", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    state = Map.put(state, :started?, true) |> Map.put(:user_turn, "user1")
    {:ok, new_state} = GameState.move(state, "user1", 0)
    assert new_state.board == ["x", "", "", "", "", "", "", "", ""]
  end

  test "move/3 returns :winner if the move wins the game", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    state = Map.put(state, :started?, true) |> Map.put(:user_turn, "user1")
    state = Map.put(state, :board, ["x", "x", "", "", "", "", "", "", ""])
    {:winner, new_state} = GameState.move(state, "user1", 2)
    assert new_state.board == ["x", "x", "x", "", "", "", "", "", ""]
  end

  test "move/3 returns :tie if the move ties the game", %{initial_state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    state = Map.put(state, :started?, true) |> Map.put(:user_turn, "user1")
    state = Map.put(state, :board, ["o", "x", "o", "o", "x", "x", "x", "o", ""])
    {:tie, new_state} = GameState.move(state, "user1", 8)
    assert new_state.board == ["o", "x", "o", "o", "x", "x", "x", "o", "x"]
  end
end
