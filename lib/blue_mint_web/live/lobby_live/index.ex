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

        Phoenix.PubSub.subscribe(BlueMint.PubSub, BlueMint.lobby_messages_topic(lobby.id))

        Phoenix.PubSub.subscribe(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(session["user_id"])
        )

        Phoenix.PubSub.subscribe(
          BlueMint.PubSub,
          BlueMint.username_change_topic(session["user_id"])
        )

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

    Phoenix.PubSub.broadcast(
      BlueMint.PubSub,
      BlueMint.lobby_messages_topic(lobby_id),
      {:message, "'#{username}' left the lobby"}
    )

    :ok
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
  def handle_info({:username_change, previous_username, new_username}, socket) do
    Phoenix.PubSub.broadcast(
      BlueMint.PubSub,
      BlueMint.lobby_messages_topic(socket.assigns.lobby.id),
      {:message, "User '#{previous_username}' changed name to '#{new_username}'"}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:lobby_message, message}, socket) do
    Phoenix.PubSub.broadcast(
      BlueMint.PubSub,
      BlueMint.lobby_messages_topic(socket.assigns.lobby.id),
      {:message, message}
    )

    {:noreply, socket}
  end
end
