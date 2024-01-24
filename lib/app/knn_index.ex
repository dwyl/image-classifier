defmodule App.KnnIndex do
  use GenServer

  @indexes "indexes.bin"
  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    File.mkdir_p!(@upload_dir)

    path = get_index_path()
    space = :cosine
    dim = 384
    max_elements = 200

    require Logger

    case File.exists?(path) do
      false ->
        {:ok, _index} = App.HnswlibIndex.maybe_load_index_from_db(space, dim, max_elements)

      true ->
        Logger.info("Existing Index")
        {:ok, _index} = HNSWLib.Index.load_index(space, dim, path)
    end
  end

  def get_index_path do
    Path.join([@upload_dir, @indexes])
  end

  def load_index do
    GenServer.call(__MODULE__, :load)
  end

  def handle_call(:load, _from, state) do
    {:reply, state, state}
  end
end
