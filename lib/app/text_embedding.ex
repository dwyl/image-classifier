defmodule App.TextEmbedding do
  use GenServer
  @indexes "indexes.bin"

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  # upload or create a new index file
  def init(_) do
    upload_dir = Application.app_dir(:app, ["priv", "static", "uploads"])
    File.mkdir_p!(upload_dir)

    path = Path.join([upload_dir, @indexes])
    space = :cosine

    require Logger

    {:ok, index} =
      case File.exists?(path) do
        false ->
          Logger.info("New Index")
          HNSWLib.Index.new(_space = space, _dim = 384, _max_elements = 200)

        true ->
          Logger.info("Existing Index")
          HNSWLib.Index.load_index(space, 384, path)
      end

    model_info = nil
    tokenizer = nil
    {:ok, {model_info, tokenizer, index}, {:continue, :load}}
  end

  def handle_continue(:load, {_, _, index}) do
    transformer = "sentence-transformers/paraphrase-MiniLM-L6-v2"

    {:ok, %{model: _model, params: _params} = model_info} =
      Bumblebee.load_model({:hf, transformer})

    {:ok, tokenizer} =
      Bumblebee.load_tokenizer({:hf, transformer})

    require Logger
    Logger.info("Transformer loaded")
    {:noreply, {model_info, tokenizer, index}}
  end

  # called in Liveview `mount`
  def serve() do
    GenServer.call(__MODULE__, :serve)
  end

  def handle_call(:serve, _from, {model_info, tokenizer, index} = state) do
    serving = Bumblebee.Text.TextEmbedding.text_embedding(model_info, tokenizer)

    {:reply, {serving, index}, state}
  end
end
