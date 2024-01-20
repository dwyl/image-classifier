defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger
  use Application

  @models_folder_path Application.compile_env!(:app, :models_cache_dir)

  @impl true
  def start(_type, _args) do
    [
      %{
        name: "blip-image-captioning-base",
        cache_path: Path.join(@models_folder_path, "blip-image-captioning-base")
      },
      %{
        name: "openai/whisper-small",
        cache_path: Path.join(@models_folder_path, "whisper-small")
      },
      %{name: "microsoft/resnet-50", cache_path: Path.join(@models_folder_path, "resnet-50")}
    ]
    |> Task.async_stream(
      fn model ->
        dbg(model)
        App.Models.verify_and_download_models(model)
      end,
      timeout: :infinity
    )
    |> Enum.to_list()

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
      {Nx.Serving, serving: App.Models.whisper_serving(), name: Whisper},
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
