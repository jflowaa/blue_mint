defmodule BlueMint.TicTacToe.Server do
  use GenServer, restart: :transient
  require Logger

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts,
           name: BlueMint.Game.ServerSupervisor.game_server_via(Keyword.get(opts, :lobby_id))
         ) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(args) do
    {:ok,
     %BlueMint.TicTacToe.GameState{
       lobby_id: Keyword.get(args, :lobby_id)
     }}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, user_id}, _from, state) do
    {result, new_state} = BlueMint.TicTacToe.GameState.add_user(state, user_id)
    {:reply, result, new_state}
  end

  def handle_call({:leave, user_id}, _from, state) do
    {result, new_state} = BlueMint.TicTacToe.GameState.remove_user(state, user_id)
    {:reply, result, new_state}
  end

  def handle_call(:start_game, _from, state) do
    cond do
      state.started? ->
        {:reply, {:cannot_start, "Already started"}, state}

      state.joinable? ->
        {:reply, {:cannot_start, "Still open for users to join joinable"}, state}

      Enum.count(state.users) == 2 ->
        new_state =
          state
          |> Map.put(:started?, true)
          |> Map.put(:joinable?, false)
          |> Map.put(:user_turn, Enum.shuffle(state.users) |> hd)
          |> Map.put(:board, ["", "", "", "", "", "", "", "", ""])

        {:reply, {:ok, new_state.user_turn}, new_state}

      true ->
        {:reply, {:cannot_start, "Cannot start"}, state}
    end
  end

  def handle_call({:move, user_id, position}, _from, state) do
    {result, new_state} = BlueMint.TicTacToe.GameState.move(state, user_id, position)
    {:reply, {result, new_state.user_turn}, new_state}
  end
end
