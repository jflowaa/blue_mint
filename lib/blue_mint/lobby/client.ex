defmodule BlueMint.Lobby.Client do
  def list_lobbies(),
    do: GenServer.call(:lobby_server, :list_lobbies)

  def create_lobby(lobby),
    do: GenServer.call(:lobby_server, {:create_lobby, lobby})

  def get_lobby(lobby_id),
    do: GenServer.call(:lobby_server, {:get_lobby, lobby_id})

  def user_connected(lobby_id, user_id),
    do: GenServer.call(:lobby_server, {:user_connected, lobby_id, user_id})

  def user_disconnected(lobby_id, user_id),
    do: GenServer.call(:lobby_server, {:user_disconnected, lobby_id, user_id})
end
