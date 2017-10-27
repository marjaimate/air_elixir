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
$ iex --sname node1 --cookie MySecretC00kie --S mix
```

As long as you start them like this, with the same cookie and different names, you can start as many as you like and connect the nodes with:

```elixir
> Node.connet :'node1@127.0.0.1'
```

