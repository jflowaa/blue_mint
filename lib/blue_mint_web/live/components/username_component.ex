defmodule BlueMintWeb.Live.Components.UsernameComponent do
  use BlueMintWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="flex items-center">
        <p class="text-xs mr-1">
          Username
        </p>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          class="size-3 cursor-pointer"
          phx-click="change"
          phx-target={@myself}
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
          />
        </svg>
      </div>
      <div>
        <p>
          <%= if assigns[:username] == nil do %>
            No username
          <% else %>
            <%= @username %>
          <% end %>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{user_id: user_id}, socket) do
    {:ok,
     socket
     |> assign(user_id: user_id)
     |> assign(username: get_username(user_id))}
  end

  @impl true
  def handle_event("change", _, socket) do
    case BlueMint.Common.NameManager.username_generate() do
      {:ok, username} ->
        case BlueMint.Common.NameManager.set_username(socket.assigns.user_id, username) do
          :ok ->
            if socket.assigns.username != nil do
              BlueMint.broadcast_username_change(
                socket.assigns.user_id,
                socket.assigns.username,
                username
              )
            end

            {:noreply, assign(socket, username: username)}

          _ ->
            {:noreply, assign(socket, username: "Error 💩")}
        end

      _ ->
        {:noreply, assign(socket, username: "Error 💩")}
    end
  end

  defp get_username(user_id) do
    case BlueMint.Common.NameManager.lookup_username(user_id) do
      nil ->
        case BlueMint.Common.NameManager.username_generate() do
          {:ok, username} ->
            case BlueMint.Common.NameManager.set_username(user_id, username) do
              :ok ->
                username

              _ ->
                "Error 💩"
            end

          _ ->
            "Error 💩"
        end

      username ->
        username
    end
  end
end
