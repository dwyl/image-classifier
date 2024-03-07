import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :app, App.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "app_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# config :wallaby,
#   base_url: "http://localhost:4002/",
#   otp_app: :app,
#   screenshot_on_failure: false,
#   chromedriver: [
#     path: "assets/node_modules//chromedriver/bin/chromedriver",
#     # change to false if you want to see the browser in action
#     headless: true
#   ],
#   driver: Wallaby.Chrome,
#   hackney_options: [timeout: :infinity, recv_timeout: :infinity]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :app, AppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "d422JqbVTXef5vPy90SakC4QcPN76fRi6wLm+pUnC09eFxWUjPbTKe0dVmpGpI5N",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# App configuration
config :app,
  start_genserver: false,
  knnindex_indices_test: true,
  use_test_models: true
