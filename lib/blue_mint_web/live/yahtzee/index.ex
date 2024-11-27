defmodule BlueMintWeb.Live.Yahtzee.Index do
  use BlueMintWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    case BlueMint.Game.ServerSupervisor.create(session["lobby_id"], BlueMint.Yahtzee.Server) do
      {:ok, _} ->
        case BlueMint.Yahtzee.Client.get(session["lobby_id"]) do
          {:ok, game_state} ->
            BlueMint.subscribe_to_game_state(session["lobby_id"])

            {:ok,
             socket
             |> assign(:lobby_id, session["lobby_id"])
             |> assign(:user_id, session["user_id"])
             |> assign(:game_state, game_state)}

          _ ->
            {:error, "Failed to retrieve game state"}
        end

      _ ->
        {:error, "Failed to create game server"}
    end
  end

  @impl true
  def handle_info(:update, socket) do
    case BlueMint.Yahtzee.Client.get(socket.assigns.lobby_id) do
      {:ok, game_state} ->
        {:noreply, assign(socket, :game_state, game_state)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("join", _, socket) do
    case BlueMint.Yahtzee.Client.join(socket.assigns.lobby_id, socket.assigns.user_id) do
      :ok ->
        BlueMint.broadcast_game_state(socket.assigns.lobby_id)
        username = BlueMint.Common.NameManager.lookup_username(socket.assigns.user_id)

        BlueMint.broadcast_lobby_message(
          socket.assigns.lobby_id,
          "Player '#{username}' joined the game"
        )

      :not_joinable ->
        BlueMint.broadcast_user_message(socket.assigns.user_id, "Game not joinable")

      :already_joined ->
        BlueMint.broadcast_user_message(socket.assigns.user_id, "Already joined")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("leave", _, socket) do
    case BlueMint.Yahtzee.Client.leave(socket.assigns.lobby_id, socket.assigns.user_id) do
      :ok ->
        BlueMint.broadcast_game_state(socket.assigns.lobby_id)
        username = BlueMint.Common.NameManager.lookup_username(socket.assigns.user_id)

        BlueMint.broadcast_lobby_message(
          socket.assigns.lobby_id,
          "Player '#{username}' left the game"
        )

      :not_in_game ->
        BlueMint.broadcast_user_message(socket.assigns.user_id, "Not in game")
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("start_game", _, socket) do
    case BlueMint.Yahtzee.Client.start_game(socket.assigns.lobby_id) do
      {:ok, user_id} ->
        BlueMint.broadcast_game_state(socket.assigns.lobby_id)
        username = BlueMint.Common.NameManager.lookup_username(user_id)

        BlueMint.broadcast_lobby_message(
          socket.assigns.lobby_id,
          "Player '#{username}' has the first move"
        )

        {:noreply, socket}

      {:cannot_start, reason} ->
        BlueMint.broadcast_user_message(socket.assigns.user_id, reason)

        {:noreply, socket}
    end
  end
end
