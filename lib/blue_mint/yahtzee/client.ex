defmodule BlueMint.Yahtzee.Client do
  def get(lobby_id) do
    try do
      {:ok, GenServer.call(BlueMint.Game.ServerSupervisor.game_server_via(lobby_id), :get)}
    catch
      :exit, {:noproc, _} ->
        {:not_found}
    end
  end

  def new(lobby_id, user_id),
    do: GenServer.call(BlueMint.Game.ServerSupervisor.game_server_via(lobby_id), {:new, user_id})

  def join(lobby_id, user_id),
    do: GenServer.call(BlueMint.Game.ServerSupervisor.game_server_via(lobby_id), {:join, user_id})

  def leave(lobby_id, user_id),
    do:
      GenServer.call(BlueMint.Game.ServerSupervisor.game_server_via(lobby_id), {:leave, user_id})

  def start_game(lobby_id),
    do: GenServer.call(BlueMint.Game.ServerSupervisor.game_server_via(lobby_id), :start_game)

  def roll(lobby_id, user_id),
    do:
      GenServer.call(
        BlueMint.Game.ServerSupervisor.game_server_via(lobby_id),
        {:roll, user_id}
      )
end
