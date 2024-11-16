defmodule BlueMint.TicTacToe.GameState do
  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}

  @derive {Jason.Encoder, only: [:lobby_id, :started?, :joinable?, :board, :user_turn, :users]}
  schema "game_state" do
    field(:lobby_id, :string)
    field(:started?, :boolean, default: false)
    field(:joinable?, :boolean, default: true)
    field(:board, {:array, :string}, default: ["", "", "", "", "", "", "", "", ""])
    field(:user_turn, :string)
    field(:users, {:array, :string}, default: [])
  end

  def add_user(state, user_id) do
    case Enum.count(state.users) < 2 do
      true ->
        case Enum.any?(state.users, fn x -> x == user_id end) do
          true ->
            {:already_joined, state}

          false ->
            new_state = Map.put(state, :users, state.users ++ [user_id])

            if Enum.count(new_state.users) == 2 do
              {:ok, Map.put(new_state, :joinable?, false)}
            else
              {:ok, new_state}
            end
        end

      false ->
        {:full, state}
    end
  end

  def remove_user(state, user_id) do
    case Enum.any?(state.users, fn x -> x == user_id end) do
      true ->
        new_state =
          state
          |> Map.put(:users, Enum.reject(state.users, fn x -> x == user_id end))
          |> Map.put(:started?, false)
          |> Map.put(:joinable?, true)

        {:ok, new_state}

      false ->
        {:not_in_game, state}
    end
  end

  def start_game(state) do
    cond do
      state.started? ->
        {{:cannot_start, "Already started"}, state}

      state.joinable? ->
        {{:cannot_start, "Still open for users to join joinable"}, state}

      Enum.count(state.users) == 2 ->
        new_state =
          state
          |> Map.put(:started?, true)
          |> Map.put(:joinable?, false)
          |> Map.put(:user_turn, Enum.shuffle(state.users) |> hd)
          |> Map.put(:board, ["", "", "", "", "", "", "", "", ""])

        {{:ok, new_state.user_turn}, new_state}

      true ->
        {{:cannot_start, "Cannot start"}, state}
    end
  end

  def move(state, user_id, position) do
    cond do
      user_id not in state.users ->
        {:not_in_game, state}

      state.started? == false ->
        {:not_started, state}

      state.user_turn != user_id ->
        {:not_your_turn, state}

      Enum.at(state.board, position) != "" ->
        {:invalid_move, state}

      true ->
        new_state =
          state
          |> Map.put(
            :board,
            List.replace_at(state.board, position, get_current_token(state.board))
          )
          |> Map.put(
            :user_turn,
            Enum.at(
              state.users,
              Enum.find_index(state.users, fn x -> x == user_id end) + 1,
              hd(state.users)
            )
          )

        case is_over?(new_state, get_current_token(state.board)) do
          :winner ->
            {:winner, new_state |> Map.put(:started?, false) |> Map.put(:user_turn, user_id)}

          :tie ->
            {:tie, new_state |> Map.put(:started?, false) |> Map.put(:user_turn, user_id)}

          _ ->
            {:ok, new_state}
        end
    end
  end

  defp get_current_token(board) do
    case rem(Enum.count(board, &(&1 == "")), 2) do
      x when x == 0 -> "o"
      _ -> "x"
    end
  end

  def is_over?(state, current_token) do
    case state.board do
      [x, x, x, _, _, _, _, _, _] when x == current_token ->
        :winner

      [_, _, _, x, x, x, _, _, _] when x == current_token ->
        :winner

      [_, _, _, _, _, _, x, x, x] when x == current_token ->
        :winner

      [x, _, _, x, _, _, x, _, _] when x == current_token ->
        :winner

      [_, x, _, _, x, _, _, x, _] when x == current_token ->
        :winner

      [_, _, x, _, _, x, _, _, x] when x == current_token ->
        :winner

      [x, _, _, _, x, _, _, _, x] when x == current_token ->
        :winner

      [_, _, x, _, x, _, x, _, _] when x == current_token ->
        :winner

      _ ->
        case Enum.all?(state.board, &(&1 != "")) do
          true -> :tie
          false -> :ongoing
        end
    end
  end
end
