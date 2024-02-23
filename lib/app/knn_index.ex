defmodule App.KnnIndex do
  use GenServer

  @moduledoc """
  A GenServer to load and handle the Index file for HNSWLib.
  It loads the index from the FileSystem if existing or from the table HnswlibIndex.
  It creates an new one if no Index file is found in the FileSystem
  and if the table HnswlibIndex is empty.
  It holds the index and the App.Image singleton table in the state.
  """

  require Logger

  @dim 384
  @max_elements 200
  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])
  @saved_index if Application.compile_env(:app, :knnindex_indices_test, false),
                 do: Path.join(@upload_dir, "indexes_test.bin"),
                 else: Path.join(@upload_dir, "indexes.bin")

  # Client API ------------------
  def start_link(args) do
    :ok = File.mkdir_p!(@upload_dir)
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def index_path do
    @saved_index
  end

  def save_index_to_db do
    GenServer.call(__MODULE__, :save_index_to_db)
  end

  def get_count do
    GenServer.call(__MODULE__, :get_count)
  end

  def add_item(embedding) do
    GenServer.call(__MODULE__, {:add_item, embedding})
  end

  def knn_search(input) do
    GenServer.call(__MODULE__, {:knn_search, input})
  end

  def not_empty_index do
    GenServer.call(__MODULE__, :not_empty)
  end

  # ---------------------------------------------------
  @impl true
  def init(args) do
    # Trying to load the index file
    :ok = File.mkdir_p!(@upload_dir)
    index_path = Keyword.fetch!(args, :index)
    space = Keyword.fetch!(args, :space)

    case File.exists?(index_path) do
      # If the index file doesn't exist, we try to load from the database.
      false ->
        {:ok, index, index_schema} =
          App.HnswlibIndex.maybe_load_index_from_db(space, @dim, @max_elements)

        {:ok, {index, index_schema, space}}

      # If the index file does exist, we compare the one with teh table and check for incoherences.
      true ->
        Logger.info("ℹ️ Index file found on disk. Let's compare it with the database...")

        App.Repo.get_by(App.HnswlibIndex, id: 1)
        |> case do
          nil ->
            {:stop,
             {:error,
              "Error comparing the index file with the one on the database. Incoherence on table."}}

          schema ->
            check_integrity(index_path, schema, space)
        end
    end
  end

  defp check_integrity(path, schema, space) do
    # We check the count of the images in the database and the one in the index.
    with db_count <-
           App.Repo.all(App.Image) |> length(),
         {:ok, index} <-
           HNSWLib.Index.load_index(space, @dim, path),
         {:ok, index_count} <-
           HNSWLib.Index.get_current_count(index),
         true <-
           index_count == db_count do
      Logger.info("ℹ️ Integrity: ✅")
      {:ok, {index, schema, space}}

      # If it fails, we return an error.
    else
      false ->
        {:stop,
         {:error, "Integrity error. The count of images from index differs from the database."}}

      {:error, msg} ->
        Logger.error("⚠️ #{msg}")
        {:stop, {:error, msg}}
    end
  end

  @impl true
  def handle_call(:save_index_to_db, _, {index, index_schema, space} = state) do
    # We read the index file and try to update the index on the table as well.
    File.read(@saved_index)
    |> case do
      {:ok, file} ->
        {:ok, updated_schema} =
          index_schema
          |> App.HnswlibIndex.changeset(%{file: file})
          |> App.Repo.update()

        {:reply, {:ok, updated_schema}, {index, updated_schema, space}}

      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:get_count, _, {index, _, _} = state) do
    {:ok, count} = HNSWLib.Index.get_current_count(index)
    {:reply, count, state}
  end

  def handle_call({:add_item, embedding}, _, {index, _, _} = state) do
    # We add the new item to the index and update it.
    with :ok <-
           HNSWLib.Index.add_items(index, embedding),
         {:ok, idx} <-
           HNSWLib.Index.get_current_count(index),
         :ok <-
           HNSWLib.Index.save_index(index, @saved_index) do

      {:reply, {:ok, idx}, state}
    else
      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:knn_search, nil}, _, state) do
    {:reply, {:error, "No index found"}, state}
  end

  def handle_call({:knn_search, input}, _, {index, _, _} = state) do
    # We search for the nearest neighbors of the input embedding.
    case HNSWLib.Index.knn_query(index, input, k: 1) do
      {:ok, labels, _distances} ->

        response =
          labels[0]
          |> Nx.to_flat_list()
          |> hd()
          |> then(fn idx ->
            App.Repo.get_by(App.Image, %{idx: idx + 1})
          end)

        # TODO: add threshold on  "distances"
        {:reply, response, state}

      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:not_empty, _, {index, _, _} = state) do
    case HNSWLib.Index.get_current_count(index) do
      {:ok, 0} ->
        Logger.warning("⚠️ Empty index.")
        {:reply, :error, state}

      {:ok, _} ->
        {:reply, :ok, state}
    end
  end
end
