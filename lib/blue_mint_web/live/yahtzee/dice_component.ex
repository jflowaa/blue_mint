defmodule BlueMintWeb.Yahtzee.DiceComponent do
  use BlueMintWeb, :html

  def render(assigns) do
    ~H"""
    <div class="block p-6 mx-auto rounded-lg shadow-lg bg-white dark:bg-gray-800 max-w-sm">
      <%= if @user_id == @game_state.user_turn do %>
        <button phx-click="roll" class="btn-primary">Roll</button>
      <% end %>
      <p class="text-gray-700 mb-4 dark:text-white text-sm">Roll Count <%= @game_state.rolls %></p>
      <%= render_dice_column(assigns) %>
    </div>
    """
  end

  defp render_dice_column(assigns) do
    ~H"""
    <div class="flex justify-center">
      <%= for die <- @game_state.dice do %>
        <div class="die">
          <span class="text-3xl md:text-5xl" />
          <%= die %>
        </div>
      <% end %>
    </div>
    """
  end
end
