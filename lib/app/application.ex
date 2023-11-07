defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AppWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Nx serving for image classifier
      {Nx.Serving, serving: serving(), name: ImageClassifier},
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

  def serving do
    {:ok, model_info} = Bumblebee.load_model({:hf, "Salesforce/blip-image-captioning-base"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "Salesforce/blip-image-captioning-base"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "Salesforce/blip-image-captioning-base"})
    {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "Salesforce/blip-image-captioning-base"})

    Bumblebee.Vision.image_to_text(model_info, featurizer, tokenizer, generation_config,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA]
    )
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
