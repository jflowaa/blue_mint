defmodule BlueMint.Common.NameManagerTest do
  use ExUnit.Case, async: true

  alias BlueMint.Common.NameManager

  setup do
    case NameManager.start_link([]) do
      {:ok, _pid} -> :ok
      :ignore -> :ok
    end
  end

  test "username_generate/0 generates a username" do
    assert {:ok, username} = NameManager.username_generate()
    assert is_binary(username)
  end

  test "lobby_name_generate/0 generates a lobby name" do
    assert {:ok, lobby_name} = NameManager.lobby_name_generate()
    assert is_binary(lobby_name)
  end

  test "set_username/2 sets a username for a user" do
    user_id = 1
    username = "TestUser"
    assert :ok = NameManager.set_username(user_id, username)
    assert username == NameManager.lookup_username(user_id, false)
  end

  test "set_lobby_name/2 sets a lobby name" do
    lobby_id = 1
    lobby_name = "TestLobby"
    assert :ok = NameManager.set_lobby_name(lobby_id, lobby_name)
    assert lobby_name == :ets.lookup(:lobby_name_table, lobby_id) |> hd() |> elem(1)
  end

  test "lookup_username/2 returns existing username" do
    user_id = 2
    username = "ExistingUser"
    NameManager.set_username(user_id, username)
    assert username == NameManager.lookup_username(user_id)
  end

  test "lookup_username/2 generates and sets a new username if not exists" do
    user_id = 3
    assert is_binary(NameManager.lookup_username(user_id))
  end

  test "lookup_username/2 returns nil if generate_if_not_exists? is false and username does not exist" do
    user_id = 4
    assert nil == NameManager.lookup_username(user_id, false)
  end
end
