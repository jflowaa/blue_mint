defmodule BlueMint.Game.ServerSupervisor do
  use Supervisor

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link(args),
    do: Supervisor.start_link(__MODULE__, args, name: BlueMint.Game.Supervisor)

  def init(_args) do
    children = [
      {DynamicSupervisor, name: BlueMint.Game.ServerSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: BlueMint.Game.ServerRegistry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def create(lobby_id, server_type) do
    case DynamicSupervisor.start_child(
           BlueMint.Game.ServerSupervisor,
           {server_type, lobby_id: lobby_id}
         ) do
      {:ok, pid} ->
        {:ok, pid}

      :ignore ->
        {:ok, GenServer.whereis(BlueMint.Game.ServerSupervisor.game_server_via(lobby_id))}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def game_server_via(lobby_id),
    do: {:via, Registry, {BlueMint.Game.ServerRegistry, "lobby_#{lobby_id}_game_server"}}
end
