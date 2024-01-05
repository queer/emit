defmodule Emit do
  alias Emit.{Cluster, DB}
  alias Lethe.Query

  def sub(key \\ key(), metadata) when is_map(metadata) do
    DB.set(key, metadata)
  end

  def unsub(key \\ key()) do
    DB.del(key)
  end

  def unsub_auto(key \\ key()) do
    spawn(fn ->
      Process.monitor(key)

      receive do
        {:DOWN, _ref, :process, _pid, _reason} ->
          DB.del(key)
      end
    end)
  end

  def pub(msg, %Query{} = query) do
    [Node.self() | Node.list()]
    |> Enum.map(fn node ->
      target =
        if node == Node.self() do
          Cluster.task_supervisor()
        else
          {Cluster.task_supervisor(), node}
        end

      Task.Supervisor.async(target, fn ->
        query
        |> DB.query()
        |> Manifold.send(msg)
      end)
    end)
    |> Enum.each(&Task.await/1)
  end

  def query, do: DB.new_query()

  defp key, do: self()
end
