defmodule BlueMintWeb.LobbyBrowserLive.FormComponent do
  use BlueMintWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Create a new lobby</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="lobby-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="name" />
        <.input
          field={@form[:game_type]}
          type="select"
          options={BlueMint.Lobby.LobbyState.game_types()}
          label="game type"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Lobby</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{lobby: lobby} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(BlueMint.Lobby.LobbyState.changeset(lobby, %{}))
     end)}
  end

  @impl true
  def handle_event("validate", %{"lobby_state" => lobby_params}, socket) do
    changeset = BlueMint.Lobby.LobbyState.changeset(socket.assigns.lobby, lobby_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"lobby_state" => lobby_params}, socket) do
    changeset = BlueMint.Lobby.LobbyState.changeset(socket.assigns.lobby, lobby_params)

    case changeset.valid? do
      true ->
        save_lobby(socket, :new, Ecto.Changeset.apply_changes(changeset))

      false ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_lobby(socket, :new, lobby_params) do
    case BlueMint.Lobby.Client.create_lobby(
           Map.put(lobby_params, :owner_id, socket.assigns.user_id)
         ) do
      {:ok, lobby} ->
        notify_parent({:saved, lobby})

        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
