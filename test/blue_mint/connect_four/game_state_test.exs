defmodule BlueMint.ConnectFour.GameStateTest do
  use ExUnit.Case
  alias BlueMint.ConnectFour.GameState

  setup do
    state = %GameState{
      lobby_id: "lobby1",
      users: [],
      board: for(r <- 0..5, c <- 0..6, into: %{}, do: {{r, c}, ""})
    }

    {:ok, state: state}
  end

  test "add_user/2 adds a user to an empty game", %{state: state} do
    {:ok, new_state} = GameState.add_user(state, "user1")
    assert new_state.users == ["user1"]
  end

  test "add_user/2 adds a second user to the game", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, new_state} = GameState.add_user(state, "user2")
    assert new_state.users == ["user1", "user2"]
    assert new_state.joinable? == false
  end

  test "add_user/2 does not add a third user to a full game", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {:full, _state} = GameState.add_user(state, "user3")
  end

  test "add_user/2 does not add a user who is already in the game", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:already_joined, _state} = GameState.add_user(state, "user1")
  end

  test "remove_user/2 removes a user from the game", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, new_state} = GameState.remove_user(state, "user1")
    assert new_state.users == []
  end

  test "remove_user/2 does not remove a user who is not in the game", %{state: state} do
    {:not_in_game, _state} = GameState.remove_user(state, "user1")
  end

  test "start_game/1 starts a game with two users", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, new_state} = GameState.start_game(state)
    assert new_state.started? == true
    assert new_state.joinable? == false
  end

  test "start_game/1 does not start a game that is already started", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, state} = GameState.start_game(state)
    {{:cannot_start, "Already started"}, _state} = GameState.start_game(state)
  end

  test "start_game/1 does not start a game with less than two users", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {{:cannot_start, "Cannot start"}, _state} = GameState.start_game(state)
  end

  test "move/3 makes a valid move", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, state} = GameState.start_game(state)
    {:ok, new_state} = GameState.move(state, "user1", 0)
    assert new_state.board[{0, 0}] == "red"
  end

  test "move/3 does not allow a move when it's not the user's turn", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, user_turn}, state} = GameState.start_game(state)
    other_user = Enum.find(state.users, fn user -> user != user_turn end)
    {:not_your_turn, _state} = GameState.move(state, other_user, 0)
  end

  test "move/3 does not allow a move in a full column", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, user_turn}, state} = GameState.start_game(state)
    Enum.each(0..5, fn _ -> {:ok, state} = GameState.move(state, user_turn, 0) end)
    {:invalid_move, _state} = GameState.move(state, user_turn, 0)
  end

  test "move/3 does not allow a move in an invalid column", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, _user_turn}, state} = GameState.start_game(state)
    {:invalid_move, _state} = GameState.move(state, "user1", 7)
  end

  test "move/3 detects a winning move", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, user_turn}, state} = GameState.start_game(state)
    Enum.each(0..3, fn col -> {:ok, state} = GameState.move(state, user_turn, col) end)
    {:winner, _state} = GameState.move(state, user_turn, 3)
  end

  test "move/3 detects a tie game", %{state: state} do
    {:ok, state} = GameState.add_user(state, "user1")
    {:ok, state} = GameState.add_user(state, "user2")
    {{:ok, user_turn}, state} = GameState.start_game(state)
    # Fill the board without any winning combination
    state =
      Enum.reduce(0..5, state, fn row, acc_state ->
        Enum.reduce(0..6, acc_state, fn col, acc_state ->
          {:ok, acc_state} = GameState.move(acc_state, acc_state.user_turn, col)
          acc_state
        end)
      end)

    {:tie, _state} = GameState.move(state, state.user_turn, 6)
  end
end
