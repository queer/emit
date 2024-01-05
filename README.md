# Emit

> *Powerful metadata-backed pubsub for Elixir.*

Emit is a pubsub library that allows controlling the receivers of messages
through granular metadata queries. pids that subscribe to Emit messages can
set metadata about itself -- basically just a map with any keys/values the user
wants -- and messages can be sent to pids matching certain metadata.

For example, you could use this to send a message to all pids that have been
waiting more than 30 seconds:

```elixir
require Lethe

query =
  Emit.query()
  |> Lethe.where(map_get(:wait_time, :metadata) >= 30_000)

Emit.pub {:my_message, "some data"}, query
```

Or you could push a message to all pids for a specific user:

```elixir
require Lethe

user_id = ...

query =
  Emit.query()
  |> Lethe.where(map_get(:user_id, :metadata) == ^user_id)

Emit.pub :disconnect, query
```

Emit will always be slower than a basic pubsub system, due to the fact that it
has to query an in-memory database on each message send.

Emit works transparently across nodes.

## Usage

1. [Get it from Hex](https://hex.pm/packages/emit) and add to mix.exs
2. Add `config :emit, :task_scheduler, MyApp.Emit.TaskScheduler` to config.exs
3. Add `{Task.Supervisor, name: MyApp.Emit.TaskScheduler}` towards the top of
   your supervision tree
4. Add `Emit.Cluster` to your supervision tree, after `libcluster` or similar
5. Add `Emit.DB` to your supervision tree, after `Emit.Cluster`

## API

### Subscribe to messages, setting some metadata about the pid

```elixir
Emit.sub %{key: "value"}
```

### Unsubscribe this pid from Emit messages

```elixir
Emit.unsub()
```

### Automatically unsubscribe from Emit messages when this pid stops

```elixir
Emit.unsub_auto()
```

### Push messages

```elixir
# Broadcast a message to all clients
Emit.pub :hello_world, Emit.query()

# Broadcast a message to all clients that have `key: "value"` in their metadata
# Emit queries are powered by Lethe: https://github.com/queer/lethe
require Lethe

query =
  Emit.query()
  |> Lethe.where(map_get(:key, :metadata) == "value")

Emit.pub :hello_world, query
```

### Complex metadata

```elixir
require Lethe

# Set some deeply-nested metadata
Emit.sub %{key: %{key2: %{"value"}}

query =
  Emit.query()
  |> Lethe.where(map_get(:key2, map_get(:key, :metadata)) == "value")

Emit.pub :hello_world, query
```

# Benchmarks

### Please run your own benchmarks to determine if Emit is suitable for your use-case!!!

The machine this was benchmarked on is quite high-end relative to most
developer workstations etc.

<details>
   <summary>Benchmarks (1k clients)</summary>
   <pre><code>
git:(mistress) 10 | ▶  mix bench.1k

11:15:07.892 [debug] [EMIT] [CLUSTER] boot: node: monitor up

11:15:07.896 [notice] Application mnesia exited: :stopped
Operating System: Linux
CPU Information: AMD Ryzen Threadripper 3960X 24-Core Processor
Number of Available Cores: 48
Available memory: 251.62 GB
Elixir 1.13.4
Erlang 24.3.4

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 8
inputs: none specified
Estimated total run time: 28 s

Benchmarking sending messages to all 1000 clients ...
Benchmarking sending messages to only 100 clients ...
Benchmarking sending messages to only 50 clients ...
Benchmarking sending messages to only 500 clients ...

Name                                           ips        average  deviation         median         99th %
sending messages to only 100 clients        3.11 K      321.96 μs    ±38.37%      298.17 μs      618.06 μs
sending messages to only 500 clients        2.82 K      354.12 μs    ±25.38%      343.55 μs      618.60 μs
sending messages to only 50 clients         2.78 K      359.52 μs    ±26.43%      347.99 μs      633.01 μs
sending messages to all 1000 clients        1.24 K      805.97 μs    ±28.84%      758.06 μs     1491.08 μs

Comparison:
sending messages to only 100 clients        3.11 K
sending messages to only 500 clients        2.82 K - 1.10x slower +32.16 μs
sending messages to only 50 clients         2.78 K - 1.12x slower +37.56 μs
sending messages to all 1000 clients        1.24 K - 2.50x slower +484.02 μs
git:(mistress) 10 | ▶
   </code></pre>
</details>

<details>
   <summary>Benchmarks (10k clients)</summary>
   <pre><code>
git:(mistress) 10 | ▶  mix bench.10k

11:15:52.647 [debug] [EMIT] [CLUSTER] boot: node: monitor up

11:15:52.650 [notice] Application mnesia exited: :stopped
Operating System: Linux
CPU Information: AMD Ryzen Threadripper 3960X 24-Core Processor
Number of Available Cores: 48
Available memory: 251.62 GB
Elixir 1.13.4
Erlang 24.3.4

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 8
inputs: none specified
Estimated total run time: 28 s

Benchmarking sending messages to all 10k clients ...
Benchmarking sending messages to only 1k clients ...
Benchmarking sending messages to only 500 clients ...
Benchmarking sending messages to only 5k clients ...

Name                                           ips        average  deviation         median         99th %
sending messages to only 500 clients        967.03        1.03 ms    ±17.09%        1.00 ms        1.64 ms
sending messages to only 5k clients         946.15        1.06 ms    ±17.49%        1.02 ms        1.71 ms
sending messages to only 1k clients         933.83        1.07 ms    ±23.72%        1.03 ms        1.75 ms
sending messages to all 10k clients         174.44        5.73 ms    ±22.20%        5.52 ms        9.47 ms

Comparison:
sending messages to only 500 clients        967.03
sending messages to only 5k clients         946.15 - 1.02x slower +0.0228 ms
sending messages to only 1k clients         933.83 - 1.04x slower +0.0368 ms
sending messages to all 10k clients         174.44 - 5.54x slower +4.70 ms
git:(mistress) 10 | ▶
   </code></pre>
</details>

<details>
   <summary>Benchmarks (100k clients)</summary>
   <pre><code>
git:(mistress) 10 | ▶  mix bench.100k

11:16:36.182 [debug] [EMIT] [CLUSTER] boot: node: monitor up

11:16:36.186 [notice] Application mnesia exited: :stopped
Operating System: Linux
CPU Information: AMD Ryzen Threadripper 3960X 24-Core Processor
Number of Available Cores: 48
Available memory: 251.62 GB
Elixir 1.13.4
Erlang 24.3.4

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 8
inputs: none specified
Estimated total run time: 28 s

Benchmarking sending messages to all 100k clients ...
Benchmarking sending messages to only 10k clients ...
Benchmarking sending messages to only 50k clients ...
Benchmarking sending messages to only 5k clients ...

Name                                           ips        average  deviation         median         99th %
sending messages to only 5k clients          58.56       17.08 ms     ±8.50%       17.04 ms       20.20 ms
sending messages to only 50k clients         57.75       17.32 ms    ±10.10%       17.26 ms       21.96 ms
sending messages to only 10k clients         56.91       17.57 ms    ±17.55%       17.37 ms       26.96 ms
sending messages to all 100k clients         10.98       91.09 ms     ±9.96%       90.61 ms      112.20 ms

Comparison:
sending messages to only 5k clients          58.56
sending messages to only 50k clients         57.75 - 1.01x slower +0.24 ms
sending messages to only 10k clients         56.91 - 1.03x slower +0.50 ms
sending messages to all 100k clients         10.98 - 5.33x slower +74.02 ms
git:(mistress) 10 | ▶
   </code></pre>
</details>

## Key points

- It works! :D
- Performance scaling is about one order of magnitude of time per order of
  magnitude of number of clients. For example, if 10 pids takes 10ms, 100 pids
  takes 100ms, 1000 pids takes 1000ms, etc.
- Performace is great at low numbers of pids, and is acceptable even when
  pushing messages to up to 50k out of 100k pids.
