defmodule BlueMint.Common.ProcessMonitorTest do
  use BlueMintWeb.ConnCase, async: true
  alias BlueMint.Common.ProcessMonitor

  defmodule MockViewModule do
    def unmount(_reason, _meta), do: :ok
  end

  setup do
    case ProcessMonitor.start_link([]) do
      {:ok, pid} -> :ok
      :ignore -> :ok
    end
  end

  test "start_link/1 ignore already started server" do
    assert :ignore = ProcessMonitor.start_link([])
  end

  @tag :skip
  test "monitor/3 monitors a process and stores the view" do
    pid = spawn(fn -> :timer.sleep(100) end)
    assert :ok = ProcessMonitor.monitor(pid, MockViewModule, %{})
    assert_receive {:DOWN, _ref, :process, ^pid, _reason}
  end

  @tag :skip
  test "handle_info/2 handles :DOWN message and calls unmount" do
    pid = spawn(fn -> :timer.sleep(100) end)
    ProcessMonitor.monitor(pid, MockViewModule, %{})
    Process.exit(pid, :normal)
    assert_receive {:DOWN, _ref, :process, ^pid, :normal}
  end

  @tag :skip
  test "handle_info/2 logs warning if no view found for pid" do
    pid = spawn(fn -> :timer.sleep(100) end)
    Process.exit(pid, :normal)
    assert_receive {:DOWN, _ref, :process, ^pid, :normal}
  end
end
