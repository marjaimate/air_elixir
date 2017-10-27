# AirElixir

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `air_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:air_elixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/air_elixir](https://hexdocs.pm/air_elixir).

## Starting a node

First get the dependencies and compile with

```bash
$ mix deps.get
$ mix compile

You can use `iex` to start a new node with

```bash
$ iex --name node1 --cookie MySecretC00kie -S mix
```

As long as you start them like this, with the same cookie and different names, you can start as many as you like and connect the nodes with:

## Distributed setup

Prepare for building with distillery

```bash
$ mix release.init
```

Compile and generate the release for the 3 configured nodes as

```bash
$ MIX_ENV=air1 mix release --env=air1 --name=air1
$ MIX_ENV=air2 mix release --env=air2 --name=air2
$ MIX_ENV=air3 mix release --env=air3 --name=air3
```

Then all you need to do is start up each nodes on its own terminal session:

```bash
# Terminal 1
$ _build/air1/rel/air1/bin/air1 console

# Terminal 2
$ _build/air2/rel/air2/bin/air2 console

# Terminal 3
$ _build/air3/rel/air3/bin/air3 console
```
