defmodule EmitTest do
  use ExUnit.Case
  alias Emit.{Cluster, DB}
  require Lethe
  doctest Emit

  setup do
    {:ok, cluster_pid} = Cluster.start_link 0
    {:ok, db_pid} = DB.start_link 0
    on_exit fn ->
      Emit.unsub()
      Process.exit cluster_pid, :normal
      Process.exit db_pid, :normal
    end

    %{cluster: cluster_pid, db: db_pid}
  end

  test "emitting works" do
    Emit.sub %{key: "value"}
    assert 1 == DB.count()

    query =
      Emit.query()
      |> Lethe.where(map_get(:key, :metadata) == "value")

    Emit.pub :hello, query
    assert_receive :hello
  end

  test "stopping emits works" do
    query =
      Emit.query()
      |> Lethe.where(map_get(:key, :metadata) == "value")

    Emit.sub %{key: "value"}
    Emit.pub :you_will_get_this, query
    assert_receive :you_will_get_this
    Emit.unsub()
    Emit.pub :you_will_never_get_this, query

    # The process mailbox won't actually be empty, but there won't be emit messages in it
    {:messages, msgs} = :erlang.process_info(self(), :messages)
    for msg <- msgs do
      refute msg == :you_will_never_get_this
    end
  end

  test "deeply nested metadata works as expected" do
    Emit.sub %{key: %{key2: "value"}}
    query =
      Emit.query()
      |> Lethe.where(map_get(:key2, map_get(:key, :metadata)) == "value")

    Emit.pub :hello, query
    assert_receive :hello
  end

  test "bound variables work as expected" do
    Emit.sub %{key: "value"}
    expected = "value"
    query =
      Emit.query()
      |> Lethe.where(map_get(:key, :metadata) == ^expected)

    Emit.pub :hello, query
    assert_receive :hello
  end
end
