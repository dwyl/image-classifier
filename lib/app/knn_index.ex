defmodule App.KnnIndex do
  use GenServer

  @indexes "indexes.bin"
  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])

  def start_link(space) do
    :ok = File.mkdir_p!(@upload_dir)
    GenServer.start_link(__MODULE__, space, name: __MODULE__)
  end

  def get_index_path do
    Path.join([@upload_dir, @indexes])
  end

  def load_index do
    GenServer.call(__MODULE__, :load)
  end

  @doc """
  Debugging function to check the Idnex current count
  """
  def get_count do
    GenServer.call(__MODULE__, :get_count)
  end

  @doc """
  Debugging function to print the Index
  """
  def get_index do
    GenServer.call(__MODULE__, :get_index)
  end

  @impl true
  def init(space) do
    File.mkdir_p!(@upload_dir)

    path = get_index_path()
    dim = 384
    max_elements = 200

    require Logger

    case File.exists?(path) do
      false ->
        App.HnswlibIndex.maybe_load_index_from_db(space, dim, max_elements)
        |> case do
          {:ok, index} -> {:ok, index}
          {:error, msg} -> {:ok, {:error, msg}}
        end

      true ->
        Logger.info("Existing Index")
        {:ok, _index} = HNSWLib.Index.load_index(space, dim, path)
    end
  end

  @impl true
  def handle_call(:load, _, {:error, :badarg} = state) do
    App.HnswlibIndex.maybe_load_index_from_db(:cosine, 384, 200)
    |> case do
      {:ok, index} ->
        {:reply, index, state}

      _ ->
        {:stop, {:error, :badarg}, state}
    end
  end

  def handle_call(:load, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_count, _, state) do
    {:ok, count} = HNSWLib.Index.get_current_count(state)
    {:reply, count, state}
  end

  def handle_call(:get_index, _, state) do
    {:reply, state, state}
  end
end
