defmodule BlueMintWeb.LobbyBrowserLive.Index do
  use BlueMintWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    Registry.register(BlueMint.EventRegistry.LobbyUpdate, :lobby_update, %{})

    {:ok,
     socket
     |> assign(:user_id, session["user_id"])
     |> stream(:lobbies, BlueMint.Lobby.Client.list_lobbies())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({BlueMintWeb.LobbyBrowserLive.FormComponent, {:saved, lobby}}, socket) do
    {:noreply, redirect(socket, to: ~p"/lobby/#{lobby.id}")}
  end

  def handle_info(:refresh_lobbies, socket) do
    {:noreply, stream(socket, :lobbies, BlueMint.Lobby.Client.list_lobbies())}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Lobbies")
    |> assign(:lobby, nil)
  end

  defp apply_action(socket, :new, _params) do
    case BlueMint.Common.NameManager.lobby_name_generate() do
      {:ok, name} ->
        socket
        |> assign(:page_title, "New Lobby")
        |> assign(:lobby, %BlueMint.Lobby.LobbyState{name: name})

      _ ->
        socket
        |> assign(:page_title, "Error")
        |> assign(:error_message, "Failed to generate lobby name")
    end
  end
end
