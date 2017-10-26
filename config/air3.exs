# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
# configure your airports with tuples {:name, :number_of_landing_strips}
#
# {distributed, [
#     {
#      m8ball,
#      5000,
#      [a@ferdmbp, {b@ferdmbp, c@ferdmbp}]
#     }
#   ]
# }
#
config :kernel,
  distributed: [{:air_elixir, 5000, [:"air1@127.0.0.1", {:"air2@127.0.0.1", :"air3@127.0.0.1"}]}],
  sync_nodes_mandatory: [:"air2@127.0.0.1", :"air1@127.0.0.1"],
  sync_nodes_timeout: 10000
#
# and access this configuration in your application as:
#
#     Application.get_env(:air_elixir, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
