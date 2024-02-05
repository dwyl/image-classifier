defmodule App.KnnIndex do
  use GenServer

  @moduledoc """
  A GenServer to load and handle the Index file for HNSWLib.
  It loads from the FileSystem if existing or from the table HnswlibIndex.
  It creates an new one if no Index file is found in the FileSystem
  and if the table HnswlibIndex is empty.


  """
  @indexes "indexes.bin"
  @saved_index Path.expand("priv/static/uploads/" <> @indexes)
  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])

  # client API ------------------
  def start_link(space) do
    :ok = File.mkdir_p!(@upload_dir)
    GenServer.start_link(__MODULE__, space, name: __MODULE__)
  end

  def get_index_path do
    # Path.join([@upload_dir, @indexes])
    @saved_index
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

  def add_item(embedding) do
    GenServer.call(__MODULE__, {:add, embedding})
  end

  def knn_search(input) do
    GenServer.call(__MODULE__, {:knn_search, input})
  end

  def not_empty_index do
    GenServer.call(__MODULE__, :not_empty)
  end

  def index_file do
    @saved_index
  end

  def check_integrity do
    index_nb =
      App.KnnIndex.load_index()
      |> HNSWLib.Index.get_current_count()
      |> elem(1)

    db_nb = App.Repo.all(App.Image) |> length()

    if index_nb == db_nb,
      do: true,
      else: false
  end

  # ---------------------------------------------------
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

      {:error, msg} ->
        {:stop, {:error, msg}, state}
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

  def handle_call({:add, embedding}, _, state) do
    with :ok <-
           HNSWLib.Index.add_items(state, embedding),
         {:ok, idx} <-
           HNSWLib.Index.get_current_count(state),
         :ok <-
           HNSWLib.Index.save_index(state, @saved_index) do
      idx |> dbg()
      {:reply, {:ok, idx}, state}
    else
      msg ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:knn_search, nil}, _, state) do
    {:reply, {:error, "no index found"}, state}
  end

  def handle_call({:knn_search, input}, _, state) do
    # refactored to denest function as per Credo
    # case HNSWLib.Index.get_current_count(index) do
    # {:ok, 0} ->
    # {:error, "no entries in index"}

    # {:ok, _c} ->
    # check the embeddings
    # {:ok, l} = HNSWLib.Index.get_current_count(index) |> dbg()

    # for i <- 0..(l - 1) do
    #   {:ok, dt} = HNSWLib.Index.get_items(index, [i])
    #   Nx.stack(Enum.map(dt, fn d -> Nx.from_binary(d, :f32) end)) |> dbg()
    # end

    case HNSWLib.Index.knn_query(state, input, k: 1) do
      {:ok, labels, distances} ->
        dbg(distances)

        response =
          labels[0]
          |> Nx.to_flat_list()
          |> hd()
          |> then(fn idx ->
            App.Repo.get_by(App.Image, %{idx: idx + 1})
          end)

        {:reply, response, state}

      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end

    # end
  end

  def handle_call(:not_empty, _, state) do
    case HNSWLib.Index.get_current_count(state) do
      {:ok, 0} ->
        {:reply, :error, state}

      {:ok, _} ->
        {:reply, :ok, state}
    end
  end
end
