defmodule App.KnnIndex do
  use GenServer

  @indexes "indexes.bin"
  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    upload_dir = Application.app_dir(:app, ["priv", "static", "uploads"])
    File.mkdir_p!(upload_dir)

    path = Path.join([@upload_dir, @indexes])
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

    {:ok, index}
  end

  def load_index do
    GenServer.call(__MODULE__, :load)
  end

  def handle_call(:load, _from, state) do
    {:reply, state, state}
  end
end
