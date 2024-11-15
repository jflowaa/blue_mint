defmodule BlueMint.Lobby.Server do
  use GenServer, restart: :transient
  require Logger

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: :lobby_server) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(_args) do
    {:ok, []}
  end

  def handle_call(:list_lobbies, _from, state), do: {:reply, state, state}

  def handle_call({:create_lobby, lobby}, _from, state) do
    lobby = Map.put(lobby, :id, BlueMint.generate_unique_identifier())
    send(self(), :dispatch_update_event)
    {:reply, {:ok, lobby}, [lobby | state]}
  end

  def handle_call({:close_lobby, lobby_id}, _from, state) do
    new_state = Enum.reject(state, fn lobby -> lobby.id == lobby_id end)
    {:reply, :ok, new_state}
  end

  def handle_call({:get_lobby, lobby_id}, _from, state) do
    case Enum.find(state, &(&1.id == lobby_id)) do
      nil ->
        {:reply, {:error, :lobby_not_found}, state}

      lobby ->
        {:reply, {:ok, lobby}, state}
    end
  end

  def handle_call({:user_connected, lobby_id, user_id}, _from, state) do
    case Enum.find(state, &(&1.id == lobby_id)) do
      nil ->
        {:reply, {:error, :lobby_not_found}, state}

      lobby ->
        updated_lobby =
          if user_id in lobby.connected_users do
            lobby
          else
            %{lobby | connected_users: [user_id | lobby.connected_users]}
          end

        updated_state =
          Enum.map(state, fn
            l when l.id == lobby_id -> updated_lobby
            l -> l
          end)

        send(self(), :dispatch_update_event)
        {:reply, {:ok, updated_lobby}, updated_state}
    end
  end

  def handle_call({:user_disconnected, lobby_id, user_id}, _from, state) do
    case Enum.find(state, &(&1.id == lobby_id)) do
      nil ->
        {:reply, {:error, :lobby_not_found}, state}

      lobby ->
        updated_lobby =
          %{lobby | connected_users: Enum.reject(lobby.connected_users, &(&1 == user_id))}

        updated_state =
          Enum.map(state, fn
            l when l.id == lobby_id -> updated_lobby
            l -> l
          end)

        send(self(), :dispatch_update_event)
        {:reply, {:ok, updated_lobby}, updated_state}
    end
  end

  def handle_info(:dispatch_update_event, state) do
    Registry.dispatch(BlueMint.EventRegistry.LobbyUpdate, :lobby_update, fn entries ->
      for {pid, _} <- entries, do: send(pid, :refresh_lobbies)
    end)

    {:noreply, state}
  end
end
