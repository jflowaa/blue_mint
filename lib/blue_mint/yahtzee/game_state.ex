defmodule BlueMint.Yahtzee.GameState do
  use Ecto.Schema
  alias BlueMint.Yahtzee.Scorecard

  @primary_key {:id, :string, autogenerate: false}

  schema "game_state" do
    field(:lobby_id, :string)
    field(:started?, :boolean, default: false)
    field(:joinable?, :boolean, default: true)
    field(:user_turn, :string)
    field(:users, {:array, :string}, default: [])
    field(:rolls, :integer, default: 0)
    field(:dice, {:array, :integer}, default: [1, 2, 3, 4, 5])
    has_many(:scorecards, Scorecard, foreign_key: :user_id)
  end

  def add_user(state, user_id) do
    case Enum.count(state.users) < 2 do
      true ->
        case Enum.any?(state.users, fn x -> x == user_id end) do
          true ->
            {:already_joined, state}

          false ->
            new_state = Map.put(state, :users, state.users ++ [user_id])

            if Enum.count(new_state.users) == 5 do
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

        if Enum.count(new_state.users) == 0 do
          {:ok, new_state |> Map.put(:joinable?, true) |> Map.put(:started?, false)}
        else
          {:ok, new_state}
        end

      false ->
        {:not_in_game, state}
    end
  end

  def start_game(state) do
    cond do
      state.started? ->
        {{:cannot_start, "Already started"}, state}

      Enum.count(state.users) > 0 ->
        new_state =
          state
          |> Map.put(:started?, true)
          |> Map.put(:joinable?, false)
          |> Map.put(:user_turn, Enum.shuffle(state.users) |> hd)

        {{:ok, new_state.user_turn}, new_state}

      true ->
        {{:cannot_start, "Cannot start"}, state}
    end
  end

  def roll(state, user_id) do
    cond do
      not state.started? ->
        {:game_not_started}

      user_id not in state.users ->
        {:not_in_game, state}

      state.user_turn != user_id ->
        {:not_your_turn, state}

      state.rolls >= 3 ->
        {:no_more_rolls, state}

      true ->
        new_state =
          state
          |> Map.put(:dice, Enum.map(state.dice, fn _ -> :rand.uniform(6) + 1 end))
          |> Map.put(:rolls, state.rolls + 1)

        {:ok, new_state}
    end
  end

  def score(state, user_id, category) do
    cond do
      not state.started? ->
        {:game_not_started, state}

      user_id not in state.users ->
        {:not_in_game, state}

      state.user_turn != user_id ->
        {:not_your_turn, state}

      true ->
        new_scorecards =
          case Enum.find(state.scorecards, fn scorecard -> scorecard.user_id == user_id end) do
            nil ->
              new_scorecard = %Scorecard{user_id: user_id}
              [new_scorecard | state.scorecards]

            _ ->
              state.scorecards
          end

        updated_scorecards =
          Enum.map(new_scorecards, fn scorecard ->
            if scorecard.user_id == user_id do
              scorecard
              |> Scorecard.score_scorecard_roll(category, state.dice)
              |> Scorecard.update_totals()
            else
              scorecard
            end
          end)

        new_state =
          state
          |> Map.put(:scorecards, updated_scorecards)
          |> Map.put(
            :user_turn,
            Enum.at(
              state.users,
              Enum.find_index(state.users, fn x -> x == user_id end) + 1,
              hd(state.users)
            )
          )

        {:ok, new_state}
    end
  end
end
