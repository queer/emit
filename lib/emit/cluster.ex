defmodule Emit.Cluster do
  use GenServer
  require Logger

  def start_link(monitor_fn \\ {__MODULE__, :monitor_nodes, []}) do
    GenServer.start_link(__MODULE__, monitor_fn, name: __MODULE__)
  end

  def init([]) do
    init({__MODULE__, :monitor_nodes, []})
  end

  def init({m, f, a}) do
    apply(m, f, a)
    Logger.debug("[EMIT] [CLUSTER] boot: node: monitor up")

    {:ok, 0}
  end

  def handle_info({msg, _node}, 0) when msg in [:nodeup, :nodedown] do
    Logger.info("[EMIT] [CLUSTER] topology: neighbours updating...")

    Logger.info("[EMIT] [CLUSTER] topology: neighbours updated")
    {:noreply, 0}
  end

  def task_supervisor, do: Application.get_env(:emit, :task_scheduler, Emit.TaskScheduler)

  def monitor_nodes do
    :net_kernel.monitor_nodes(true)
  end
end
