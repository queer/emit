defmodule Emit.Cluster do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link __MODULE__, 0, name: __MODULE__
  end

  def init(_) do
    :net_kernel.monitor_nodes(true)
    Logger.debug "[EMIT] [CLUSTER] boot: node: monitor up"

    {:ok, 0}
  end

  def handle_info({msg, _node}, 0) when msg in [:nodeup, :nodedown] do
    Logger.info "[EMIT] [CLUSTER] topology: neighbours updating..."

    Logger.info "[EMIT] [CLUSTER] topology: neighbours updated"
    {:noreply, 0}
  end

  def task_supervisor, do: Application.get_env(:emit, :task_scheduler, Emit.TaskScheduler)
end
