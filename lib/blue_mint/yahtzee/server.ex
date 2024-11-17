defmodule BlueMint.Yahtzee.Server do
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
     %BlueMint.Yahtzee.GameState{
       lobby_id: Keyword.get(args, :lobby_id)
     }}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, user_id}, _from, state) do
    {result, new_state} = BlueMint.Yahtzee.GameState.add_user(state, user_id)
    {:reply, result, new_state}
  end

  def handle_call({:leave, user_id}, _from, state) do
    {result, new_state} = BlueMint.Yahtzee.GameState.remove_user(state, user_id)
    {:reply, result, new_state}
  end

  def handle_call(:start_game, _from, state) do
    {result, new_state} = BlueMint.Yahtzee.GameState.start_game(state)
    {:reply, result, new_state}
  end

  def handle_call({:roll, user_id}, _from, state) do
    {result, new_state} = BlueMint.Yahtzee.GameState.roll(state, user_id)
    {:reply, {result, new_state}, new_state}
  end

  def handle_call({:score, user_id, category}, _from, state) do
    {result, new_state} = BlueMint.Yahtzee.GameState.score(state, user_id, category)
    {:reply, {result, new_state.user_turn}, new_state}
  end
end
