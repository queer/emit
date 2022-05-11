require Lethe

{:ok, _cluster_pid} = Emit.Cluster.start_link 0
{:ok, _db_pid} = Emit.DB.start_link 0
{:ok, _task_scheduler_pid} = Task.Supervisor.start_link name: Emit.TaskScheduler

_waiters =
  for i <- 1..1_000 do
    spawn fn ->
      Emit.sub %{id: i}
    end
  end

half_query =
  Emit.query()
  |> Lethe.where(:id <= 500)

under_ten_query =
  Emit.query()
  |> Lethe.where(:id <= 100)

under_five_query =
  Emit.query()
  |> Lethe.where(:id <= 50)

Benchee.run(%{
  "sending messages to all 1000 clients" => fn -> Emit.pub(:hello, Emit.query()) end,
  "sending messages to only 500 clients" => fn -> Emit.pub(:hello, half_query) end,
  "sending messages to only 100 clients" => fn -> Emit.pub(:hello, under_ten_query) end,
  "sending messages to only 50 clients" => fn -> Emit.pub(:hello, under_five_query) end,
}, parallel: 8)
