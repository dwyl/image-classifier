defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    App.Models.verify_and_download_models()

    children = [
      # Start the Telemetry supervisor
      AppWeb.Telemetry,
      # Setup DB
      App.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Nx serving for the embedding
      # App.TextEmbedding,
      # Nx serving for Speech-to-Text
      {Nx.Serving, serving: App.Whisper.serving(), name: Whisper},
      # Nx serving for image classifier
      {Nx.Serving,
       serving:
         if Application.get_env(:app, :use_test_models) == true do
           App.Models.serving_test()
         else
           App.Models.serving()
         end,
       name: ImageClassifier},
      {GenMagic.Server, name: :gen_magic},
      # Adding a supervisor
      {Task.Supervisor, name: App.TaskSupervisor},
      # Start the Endpoint (http/https)
      AppWeb.Endpoint
      # Start a worker by calling: App.Worker.start_link(arg)
      # {App.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
