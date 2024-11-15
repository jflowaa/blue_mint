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
        <code class="whitespace-pre-wrap"><%= Jason.encode!(@game_state, pretty: true) %></code>
      </.modal>
    </div>
    """
  end
end
