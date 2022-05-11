require Lethe

{:ok, _cluster_pid} = Emit.Cluster.start_link 0
{:ok, _db_pid} = Emit.DB.start_link 0
{:ok, _task_scheduler_pid} = Task.Supervisor.start_link name: Emit.TaskScheduler

_waiters =
  for i <- 1..10_000 do
    spawn fn ->
      Emit.sub %{id: i}
    end
  end

half_query =
  Emit.query()
  |> Lethe.where(:id <= 5_000)

under_ten_query =
  Emit.query()
  |> Lethe.where(:id <= 1_000)

under_five_query =
  Emit.query()
  |> Lethe.where(:id <= 500)

Benchee.run(%{
  "sending messages to all 10k clients" => fn -> Emit.pub(:hello, Emit.query()) end,
  "sending messages to only 5k clients" => fn -> Emit.pub(:hello, half_query) end,
  "sending messages to only 1k clients" => fn -> Emit.pub(:hello, under_ten_query) end,
  "sending messages to only 500 clients" => fn -> Emit.pub(:hello, under_five_query) end,
}, parallel: 8)
