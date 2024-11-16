defmodule BlueMint.ConnectFour.GameState do
  use Ecto.Schema
  import Ecto.Changeset

  @rows 5
  @columns 6
  @primary_key {:id, :string, autogenerate: false}

  @derive {Jason.Encoder, only: [:lobby_id, :started?, :joinable?, :board, :user_turn, :users]}
  schema "game_state" do
    field(:lobby_id, :string)
    field(:started?, :boolean, default: false)
    field(:joinable?, :boolean, default: true)
    field(:winning_combination, {:array, {:map, :integer}}, default: [])

    field(:user_turn, :string)
    field(:users, {:array, :string}, default: [])

    field(:board, {:map, :string},
      default: for(r <- 0..@rows, c <- 0..@columns, into: %{}, do: {{r, c}, ""})
    )
  end

  def changeset(%BlueMint.ConnectFour.GameState{} = game_state, attrs) do
    game_state
    |> cast(attrs, [:board, :user_turn])
    |> validate_required([:board, :user_turn])
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

  def move(state, user_id, column) do
    row = landed_row(state.board, column)

    cond do
      user_id not in state.users ->
        {:not_in_game, state}

      state.started? == false ->
        {:not_started, state}

      state.user_turn != user_id ->
        {:not_your_turn, state}

      row == 7 ->
        {:invalid_move, state}

      column < 0 or column > @columns ->
        {:invalid_move, state}

      true ->
        new_state =
          Map.put(
            state,
            :board,
            Map.put(state.board, {row, column}, get_current_token(state.board))
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
          {:winner, line} ->
            {:winner,
             new_state
             |> Map.put(:started?, false)
             |> Map.put(:user_turn, user_id)
             |> Map.put(:winning_combination, line)}

          :tie ->
            {:tie, new_state |> Map.put(:started?, false) |> Map.put(:user_turn, user_id)}

          _ ->
            {:ok, new_state}
        end
    end
  end

  defp landed_row(board, column),
    do:
      Enum.take_while(0..@rows, fn x ->
        Map.get(board, {x, column}) != ""
      end)
      |> Enum.count()

  defp get_current_token(board) do
    case rem(Enum.count(board, &(elem(&1, 1) == "")), 2) do
      x when x == 0 -> "red"
      _ -> "black"
    end
  end

  defp is_over?(state, current_token) do
    board = Map.get(state, :board)

    case find_winning_combination(board, current_token) do
      {:ok, combination} ->
        {:winner, combination}

      :not_found ->
        cond do
          Enum.all?(list_rows(board) |> List.flatten(), &(&1 != "")) ->
            :tie

          true ->
            :ongoing
        end
    end
  end

  defp find_winning_combination(board, token) do
    rows = list_rows_with_coords(board)
    columns = list_columns_with_coords(board)
    diagonals = list_diagonals_with_coords(board)

    Enum.find_value(rows ++ columns ++ diagonals, :not_found, fn {line, coords} ->
      if is_group_of_four?(line, token) do
        {:ok, coords}
      else
        false
      end
    end)
  end

  defp is_group_of_four?(list, token) do
    Enum.chunk_every(list, 4, 1, :discard)
    |> Enum.any?(fn chunk -> Enum.all?(chunk, &(&1 == token)) end)
  end

  defp list_rows(board) do
    for row <- 0..@rows do
      for column <- 0..@columns do
        Map.get(board, {row, column})
      end
    end
  end

  defp list_rows_with_coords(board) do
    for row <- 0..@rows do
      line =
        for column <- 0..@columns do
          {Map.get(board, {row, column}), {row, column}}
        end

      {Enum.map(line, &elem(&1, 0)), Enum.map(line, &elem(&1, 1))}
    end
  end

  defp list_columns_with_coords(board) do
    for column <- 0..@columns do
      line =
        for row <- 0..@rows do
          {Map.get(board, {row, column}), {row, column}}
        end

      {Enum.map(line, &elem(&1, 0)), Enum.map(line, &elem(&1, 1))}
    end
  end

  defp list_diagonals_with_coords(board) do
    Enum.reduce(0..@rows, [], fn row, acc ->
      Enum.reduce(0..@columns, acc, fn column, acc ->
        acc ++
          [get_diagonal_with_coords(board, {row, column}, 1, 1)] ++
          [get_diagonal_with_coords(board, {row, column}, 1, -1)]
      end)
    end)
  end

  defp get_diagonal_with_coords(board, {row, column}, row_inc, col_inc) do
    get_diagonal_with_coords(board, {row, column}, row_inc, col_inc, [])
  end

  defp get_diagonal_with_coords(board, {row, column}, row_inc, col_inc, acc)
       when row >= 0 and row <= @rows and column >= 0 and column <= @columns do
    get_diagonal_with_coords(
      board,
      {row + row_inc, column + col_inc},
      row_inc,
      col_inc,
      acc ++ [{Map.get(board, {row, column}), {row, column}}]
    )
  end

  defp get_diagonal_with_coords(_board, _pos, _row_inc, _col_inc, acc) do
    {Enum.map(acc, &elem(&1, 0)), Enum.map(acc, &elem(&1, 1))}
  end
end
