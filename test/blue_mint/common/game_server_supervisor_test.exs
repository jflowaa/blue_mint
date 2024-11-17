defmodule BlueMint.Game.ServerSupervisorTest do
  use ExUnit.Case, async: true

  alias BlueMint.Game.ServerSupervisor

  setup do
    _ = ServerSupervisor.start_link([])
    :ok
  end

  test "start_link/1 cannot start supervisor due to already being started" do
    assert {:error, {:already_started, _}} = ServerSupervisor.start_link([])
  end

  test "create/2 starts a new game server" do
    lobby_id = 1
    server_type = BlueMint.TicTacToe.Server
    assert {:ok, pid} = ServerSupervisor.create(lobby_id, server_type)
    assert is_pid(pid)
  end

  test "create/2 returns existing game server if already started" do
    lobby_id = 2
    server_type = BlueMint.TicTacToe.Server
    {:ok, pid1} = ServerSupervisor.create(lobby_id, server_type)
    assert {:ok, pid2} = ServerSupervisor.create(lobby_id, server_type)
    assert pid1 == pid2
  end

  test "game_server_via/1 returns the correct via tuple" do
    lobby_id = 3

    expected_via =
      {:via, Registry, {BlueMint.Game.ServerRegistry, "lobby_#{lobby_id}_game_server"}}

    assert expected_via == ServerSupervisor.game_server_via(lobby_id)
  end
end
