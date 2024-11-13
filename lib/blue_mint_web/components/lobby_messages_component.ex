defmodule BlueMintWeb.Components.LobbyMessagesComponent do
  use BlueMintWeb, :html

  def render(assigns) do
    ~H"""
    <div id="lobby-messages" phx-update="stream" class="flex flex-col-reverse">
      <%= for {_id, message} <- @messages do %>
        <p>
          <%= message.content %>
        </p>
      <% end %>
    </div>
    """
  end
end
