defmodule BlueMintWeb.Components.GameStateViewerComponent do
  use BlueMintWeb, :html

  def render(assigns) do
    ~H"""
    <div>
      <.button
        class="text-xs leading-4"
        phx-click={BlueMintWeb.CoreComponents.show_modal("game-state-modal")}
      >
        Show State
      </.button>
      <.modal id="game-state-modal">
        <.header>
          Game State
        </.header>
        <code class="whitespace-pre-wrap"><%= render_game_state(@game_state) %></code>
      </.modal>
    </div>
    """
  end

  defp render_game_state(game_state) do
    game_state
    |> Map.drop([:id, :lobby_id, :users, :user_turn, :__struct__, :__meta__, :__changeset__])
    |> inspect(pretty: true)
  end
end
