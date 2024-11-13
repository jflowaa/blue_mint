defmodule BlueMintWeb.Live.TicTacToe.Index do
  use BlueMintWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    case BlueMint.Game.ServerSupervisor.create(session["lobby_id"], :tic_tac_toe) do
      {:ok, _} ->
        case BlueMint.TicTacToe.Client.get(session["lobby_id"]) do
          {:ok, game_state} ->
            Phoenix.PubSub.subscribe(
              BlueMint.PubSub,
              BlueMint.game_state_topic(session["lobby_id"])
            )

            {:ok,
             socket
             |> assign(:lobby_id, session["lobby_id"])
             |> assign(:user_id, session["user_id"])
             |> assign(:game_state, game_state)
             |> assign(:show_state, false)}

          _ ->
            {:error, "Failed to retrieve game state"}
        end

      _ ->
        {:error, "Failed to create game server"}
    end
  end

  @impl true
  def handle_info(:update, socket) do
    case BlueMint.TicTacToe.Client.get(socket.assigns.lobby_id) do
      {:ok, game_state} ->
        {:noreply, assign(socket, :game_state, game_state)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("show_state", _, socket) do
    {:noreply, assign(socket, :show_state, not socket.assigns.show_state)}
  end

  @impl true
  def handle_event("join", _, socket) do
    case BlueMint.TicTacToe.Client.join(socket.assigns.lobby_id, socket.assigns.user_id) do
      :ok ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.game_state_topic(socket.assigns.lobby_id),
          :update
        )

        username = BlueMint.Common.NameManager.lookup_username(socket.assigns.user_id)

        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.lobby_messages_topic(socket.assigns.lobby_id),
          {:message, "Player '#{username}' joined the game"}
        )

      :not_joinable ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(socket.assigns.user_id),
          {:message, "Game not joinable"}
        )

      :already_joined ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(socket.assigns.user_id),
          {:message, "Already joined"}
        )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("leave", _, socket) do
    case BlueMint.TicTacToe.Client.leave(socket.assigns.lobby_id, socket.assigns.user_id) do
      :ok ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.game_state_topic(socket.assigns.lobby_id),
          :update
        )

        username = BlueMint.Common.NameManager.lookup_username(socket.assigns.user_id)

        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.lobby_messages_topic(socket.assigns.lobby_id),
          {:message, "Player '#{username}' left the game"}
        )

      :not_in_game ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(socket.assigns.user_id),
          {:message, "Not in game"}
        )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("start_game", _, socket) do
    case BlueMint.TicTacToe.Client.start_game(socket.assigns.lobby_id) do
      {:ok, user_id} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.game_state_topic(socket.assigns.lobby_id),
          :update
        )

        username = BlueMint.Common.NameManager.lookup_username(user_id)

        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.lobby_messages_topic(socket.assigns.lobby_id),
          {:message, "Player '#{username}' has the first move"}
        )

        {:noreply, socket}

      {:cannot_start, reason} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(socket.assigns.user_id),
          {:message, reason}
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move", %{"position" => position}, socket) do
    case BlueMint.TicTacToe.Client.move(
           socket.assigns.lobby_id,
           socket.assigns.user_id,
           String.to_integer(position)
         ) do
      {:not_in_game, _} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(socket.assigns.user_id),
          {:message, "Not in game"}
        )

      {:not_started, _} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(socket.assigns.user_id),
          {:message, "Game not started yet"}
        )

      {:invalid_move, _} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(socket.assigns.user_id),
          {:message, "Invalid move"}
        )

      {:not_your_turn, _} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.user_messages_topic(socket.assigns.user_id),
          {:message, "Not your turn"}
        )

      {:winner, _} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.game_state_topic(socket.assigns.lobby_id),
          :update
        )

        username = BlueMint.Common.NameManager.lookup_username(socket.assigns.user_id)

        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.lobby_messages_topic(socket.assigns.lobby_id),
          {:message, "Player '#{username}' won!"}
        )

      {:tie, _} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.game_state_topic(socket.assigns.lobby_id),
          :update
        )

        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.lobby_messages_topic(socket.assigns.lobby_id),
          {:message, "Game ended in a tie!"}
        )

      {:ok, user_id} ->
        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.game_state_topic(socket.assigns.lobby_id),
          :update
        )

        username = BlueMint.Common.NameManager.lookup_username(user_id)

        Phoenix.PubSub.broadcast(
          BlueMint.PubSub,
          BlueMint.lobby_messages_topic(socket.assigns.lobby_id),
          {:message, "Player '#{username}' turn to move"}
        )
    end

    {:noreply, socket}
  end

  defp render_square(position, assigns) do
    assigns =
      assigns
      |> assign(
        :available_cell_class,
        if(
          assigns.game_state.user_turn == assigns.user_id and
            Enum.at(assigns.game_state.board, position) == "",
          do: "cursor-pointer border-green-900"
        )
      )
      |> assign(:position, position)

    ~H"""
    <td
      class={"border-8 #{@available_cell_class}"}
      phx-click="move"
      phx-value-position={"#{@position}"}
    >
      <svg width="100%" height="100%" preserveAspectRatio="none">
        <%= case Enum.at(@game_state.board, @position) do %>
          <% "x" -> %>
            <%= draw_svg_cross() %>
          <% "o" -> %>
            <%= draw_svg_circle() %>
          <% _ -> %>
        <% end %>
      </svg>
    </td>
    """
  end

  defp draw_svg_cross(assigns \\ %{}),
    do: ~H"""
    <line x1="25%" y1="25%" x2="75%" y2="75%" stroke="black" stroke-width="8" />
    <line x1="75%" y1="25%" x2="25%" y2="75%" stroke="black" stroke-width="8" />
    """

  defp draw_svg_circle(assigns \\ %{}),
    do: ~H"""
    <circle cx="50%" cy="50%" r="25%" stroke="black" stroke-width="8" fill="white" fill-opacity="0.0" />
    """
end
