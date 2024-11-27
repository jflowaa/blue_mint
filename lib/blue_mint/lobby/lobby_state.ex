defmodule BlueMint.Lobby.LobbyState do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @game_types [:tic_tac_toe, :connect_four, :yahtzee]

  schema "lobby_state" do
    field(:name, :string)
    field(:owner_id, :string)
    field(:game_type, Ecto.Enum, values: @game_types)
    field(:connected_users, {:array, :string}, default: [])
  end

  def changeset(%BlueMint.Lobby.LobbyState{} = lobby_state, attrs) do
    lobby_state
    |> cast(attrs, [:name, :game_type])
    |> validate_required([:name, :game_type])
  end

  def game_types() do
    @game_types
    |> Enum.map(fn game_type ->
      {BlueMint.pretty_atom(game_type), game_type}
    end)
  end
end
