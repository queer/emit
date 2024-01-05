defmodule Emit.DB do
  use GenServer
  alias Lethe.Query
  require Logger

  @table :emit_metadata
  @prune_interval 5_000

  def table, do: @table

  def start_link(_) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def init(_) do
    :stopped = :mnesia.stop()
    :mnesia.create_schema([])
    :ok = :mnesia.start()

    create_table_with_indexes(@table, [attributes: [:pid, :metadata]], [:pid, :metadata])

    Process.send_after(self(), :prune, @prune_interval)

    {:ok, 0}
  end

  def handle_info(:prune, 0) do
    _prune_count =
      Emit.query()
      |> query
      |> Enum.reject(&Process.alive?/1)
      |> Enum.map(&del/1)
      |> length

    # Logger.debug "[EMIT] [DB] prune: #{prune_count} entries pruned"
    Process.send_after(self(), :prune, @prune_interval)
    {:noreply, 0}
  end

  defp create_table_with_indexes(table, opts, index_keys) do
    :mnesia.create_table(table, opts)
    for index <- index_keys, do: :mnesia.add_table_index(table, index)
  end

  def stop do
    :mnesia.delete_table(@table)
    :mnesia.stop()
    :mnesia.delete_schema([])
    :ok
  end

  def get(key) do
    :mnesia.transaction(fn ->
      case :mnesia.read({@table, key}) do
        [{@table, ^key, value}] ->
          value

        [] ->
          nil
      end
    end)
    |> return_read_result_or_error(@table, key)
  end

  def set(key, value) do
    :mnesia.transaction(fn ->
      :ok = :mnesia.write({@table, key, value})
    end)
    |> return_result_or_error
  end

  def del(key) do
    :mnesia.transaction(fn ->
      :ok = :mnesia.delete({@table, key})
    end)
    |> return_result_or_error
  end

  def new_query, do: Lethe.new(@table)

  def query(%Query{} = query) do
    query_res =
      query
      |> Lethe.compile()
      |> Lethe.run()

    with {:query, {:ok, pids}} <- {:query, query_res} do
      Enum.map(pids, fn {pid, _} -> pid end)
    else
      {:query, {:error, error}} -> raise error
    end
  end

  def count do
    :mnesia.table_info(@table, :size)
  end

  defp return_read_result_or_error(mnesia_result, table, id) do
    case mnesia_result do
      {:atomic, nil} ->
        {:ok, nil}

      {:atomic, []} ->
        {:ok, nil}

      {:atomic, [{^table, ^id, value}]} ->
        {:ok, value}

      {:atomic, value} ->
        {:ok, value}

      {:aborted, reason} ->
        {:error, {:transaction_aborted, reason}}
    end
  end

  defp return_result_or_error(mnesia_result) do
    case mnesia_result do
      {:atomic, res} ->
        {:ok, res}

      {:aborted, reason} ->
        {:error, {:transaction_aborted, reason}}
    end
  end

  def handle_call(:restart, _caller, 0) do
    :mnesia.stop()
    :mnesia.start()
    {:reply, :ok, 0}
  end

  def restart, do: GenServer.call(__MODULE__, :restart)
end
