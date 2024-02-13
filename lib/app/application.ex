defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger
  use Application

  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])

  @saved_index if Application.compile_env(:app, :knnindex_indices_test, false),
                 do: Path.join(@upload_dir, "indexes_test.bin"),
                 else: Path.join(@upload_dir, "indexes.bin")

  def check_models_on_startup do
    App.Models.verify_and_download_models()
    |> case do
      {:error, msg} ->
        Logger.warning(msg)
        System.stop(0)

      :ok ->
        Logger.info("Models: " <> "\u2705")
        :ok
    end
  end

  @impl true
  def start(_type, _args) do
    :ok = check_models_on_startup()

    children = [
      # Start the Telemetry supervisor
      AppWeb.Telemetry,
      # Setup DB
      App.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: App.PubSub},
      # Nx serving for the embedding
      {Nx.Serving, serving: App.Models.embedding(), name: Embedding, batch_size: 1},
      # Nx serving for Speech-to-Text
      {Nx.Serving,
       serving:
         if Application.get_env(:app, :use_test_models) == true do
           App.Models.audio_serving_test()
         else
           App.Models.audio_serving()
         end,
       name: Whisper},
      # Nx serving for image classifier
      {Nx.Serving,
       serving:
         if Application.get_env(:app, :use_test_models) == true do
           App.Models.caption_serving_test()
         else
           App.Models.caption_serving()
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

    # We are starting the HNSWLib Index GenServer only during testing.
    # Because this GenServer needs the database to be seeded first,
    # we only add it when we're not testing.
    # When testing, you need to spawn this process manually (it is done in the test_helper.exs file).
    children =
      if Application.get_env(:app, :start_genserver, true) == true do
        Enum.concat(children, [{App.KnnIndex, [space: :cosine, index: @saved_index]}])
      else
        children
      end

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
