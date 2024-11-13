defmodule BlueMint.Common.ProcessMonitor do
  use GenServer
  require Logger

  def monitor(pid, view_module, meta) do
    GenServer.call(:process_monitor, {:monitor, pid, view_module, meta})
  end

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: :process_monitor) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _}} ->
        :ignore
    end
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  def handle_call({:monitor, pid, view_module, meta}, _from, %{views: views} = state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, meta})}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    case Map.pop(state.views, pid) do
      {{module, meta}, new_views} ->
        try do
          module.unmount(reason, meta)
        rescue
          exception -> Logger.error("Error unmounting view: #{inspect(exception)}")
        end

        {:noreply, %{state | views: new_views}}

      {nil, _new_views} ->
        Logger.warning("No view found for pid: #{inspect(pid)}")
        {:noreply, state}
    end
  end
end
