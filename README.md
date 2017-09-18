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

TODO
=====

* Add docs on how to start a node
* Implement CT start on app start
  - Add a control tower sup, with one_for_one
* Add supervisor simple_one_for_one for planes (with a plane_sup)
* Add tests to start many planes against a single gen_server
* Prapare the same app for multinode setup
  - Multiple planes from all nodes trying to land
  - http://learnyousomeerlang.com/distributed-otp-applications
