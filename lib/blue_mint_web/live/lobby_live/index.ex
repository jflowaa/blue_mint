defmodule BlueMintWeb.LobbyLive.Index do
  use BlueMintWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    lobby = BlueMint.Lobby.Client.get_lobby(params["lobby_id"])

    case lobby do
      {:error, _} ->
        {:ok, redirect(socket, to: ~p"/")}

      {:ok, lobby} ->
        BlueMint.Lobby.Client.user_connected(lobby.id, session["user_id"])
        username = BlueMint.Common.NameManager.lookup_username(session["user_id"])
        send(self(), {:lobby_message, "'#{username}' entered the lobby"})

        BlueMint.Common.ProcessMonitor.monitor(self(), __MODULE__, %{
          lobby_id: lobby.id,
          user_id: session["user_id"]
        })

        BlueMint.subscribe_to_lobby_messages(lobby.id)
        BlueMint.subscribe_to_user_messages(session["user_id"])
        BlueMint.subscribe_to_username_changes(session["user_id"])

        {:ok,
         socket
         |> assign(unique_incrementor: 0)
         |> stream(:messages, [])
         |> assign(lobby: lobby)
         |> assign(user_id: session["user_id"])}
    end
  end

  def unmount(_reason, %{lobby_id: lobby_id, user_id: user_id}) do
    BlueMint.Lobby.Client.user_disconnected(lobby_id, user_id)
    username = BlueMint.Common.NameManager.lookup_username(user_id)
    BlueMint.broadcast_lobby_message(lobby_id, "'#{username}' left the lobby")
    # lobby = BlueMint.Lobby.Client.get_lobby(lobby_id)
    # if lobby.owner_id == user_id do
    #   BlueMint.Lobby.Client.close_lobby(lobby_id)
    #   BlueMint.broadcast_lobby_closed(lobby_id)
    # end

    :ok
  end

  @impl true
  def handle_info({:username_change, previous_username, new_username}, socket) do
    send(
      self(),
      {:lobby_message, "User '#{previous_username}' changed name to '#{new_username}'"}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message, message}, socket) do
    unique_incrementor = socket.assigns.unique_incrementor + 1

    {:noreply,
     socket
     |> stream_insert(
       :messages,
       %{id: unique_incrementor, content: message}
     )
     |> assign(:unique_incrementor, unique_incrementor)}
  end

  @impl true
  def handle_info({:lobby_message, message}, socket) do
    BlueMint.broadcast_lobby_message(socket.assigns.lobby.id, message)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:lobby_closed, socket) do
    {:noreply,
     socket
     |> redirect(to: ~p"/?reason=lobby_closed")}
  end

  @impl true
  def handle_event("close_lobby", _, socket) do
    if socket.assigns.lobby.owner_id != socket.assigns.user_id do
      {:noreply, redirect(socket, to: ~p"/")}
    else
      BlueMint.Lobby.Client.close_lobby(socket.assigns.lobby.id)
      BlueMint.broadcast_lobby_closed(socket.assigns.lobby.id)

      {:noreply, redirect(socket, to: ~p"/")}
    end
  end
end
