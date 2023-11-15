import Config

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

# Configuring app (general)
config :app,
  models_cache_dir: ".bumblebee"
