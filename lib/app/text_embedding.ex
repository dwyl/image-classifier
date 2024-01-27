defmodule App.TextEmbedding do
  use GenServer

  @moduledoc """
  Genserver to load asynchronously the embedding model.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    model_info = nil
    tokenizer = nil
    {:ok, {model_info, tokenizer}, {:continue, :load}}
  end

  def handle_continue(:load, {_, _}) do
    transformer = "sentence-transformers/paraphrase-MiniLM-L6-v2"

    {:ok, %{model: _model, params: _params} = model_info} =
      Bumblebee.load_model({:hf, transformer})

    {:ok, tokenizer} =
      Bumblebee.load_tokenizer({:hf, transformer})

    require Logger
    Logger.info("Transformer loaded")
    {:noreply, {model_info, tokenizer}}
  end

  # called in Liveview `mount`
  def serve() do
    GenServer.call(__MODULE__, :serve)
  end

  def handle_call(:serve, _from, {model_info, tokenizer} = state) do
    embedding_serving = Bumblebee.Text.TextEmbedding.text_embedding(model_info, tokenizer)

    {:reply, embedding_serving, state}
  end
end
