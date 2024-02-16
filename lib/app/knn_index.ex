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

  # client API ------------------
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
    :ok = File.mkdir_p!(@upload_dir)
    index_path = Keyword.fetch!(args, :index)
    space = Keyword.fetch!(args, :space)

    case File.exists?(index_path) do
      false ->
        {:ok, index, index_schema} =
          App.HnswlibIndex.maybe_load_index_from_db(space, @dim, @max_elements)

        # |> case do
        #   {:ok, index, index_schema} -> {:ok, {index, index_schema, space}}
        #   {:error, msg} -> {:stop, {:error, msg}}
        # end
        {:ok, {index, index_schema, space}}

      true ->
        Logger.info("Existing Index")

        App.Repo.get_by(App.HnswlibIndex, id: 1)
        |> case do
          nil ->
            {:stop, {:error, "Incoherence on table"}}

          schema ->
            check_integrity(index_path, schema, space)
        end
    end
  end

  defp check_integrity(path, schema, space) do
    with db_count <-
           App.Repo.all(App.Image) |> length(),
         {:ok, index} <-
           HNSWLib.Index.load_index(space, @dim, path),
         {:ok, index_count} <-
           HNSWLib.Index.get_current_count(index),
         true <-
           index_count == db_count do
      Logger.info("Integrity: " <> "\u2705")
      {:ok, {index, schema, space}}
    else
      false ->
        {:stop, {:error, "Integrity error"}}

      {:error, msg} ->
        Logger.warning(inspect(msg))
        {:stop, {:error, msg}}
    end
  end

  @impl true
  def handle_call(:save_index_to_db, _, {index, index_schema, space} = state) do
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
    # HNSWLib.Index.get_current_count(index)
    # |> case do
    #   {:ok, count} ->
    #     {:reply, count, state}

    #   {:error, msg} ->
    #     {:reply, {:error, msg}, state}
    # end
  end

  def handle_call({:add_item, embedding}, _, {index, _, _} = state) do
    with :ok <-
           HNSWLib.Index.add_items(index, embedding),
         {:ok, idx} <-
           HNSWLib.Index.get_current_count(index),
         :ok <-
           HNSWLib.Index.save_index(index, @saved_index) do
      Logger.info("idx: #{idx}")
      {:reply, {:ok, idx}, state}
    else
      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:knn_search, nil}, _, state) do
    {:reply, {:error, "no index found"}, state}
  end

  def handle_call({:knn_search, input}, _, {index, _, _} = state) do
    case HNSWLib.Index.knn_query(index, input, k: 1) do
      {:ok, labels, distances} ->
        Logger.info(inspect(distances))

        response =
          labels[0]
          |> Nx.to_flat_list()
          |> hd()
          |> then(fn idx ->
            App.Repo.get_by(App.Image, %{idx: idx + 1})
          end)

        # possible TODO: add threshold on  "distances"
        {:reply, response, state}

      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:not_empty, _, {index, _, _} = state) do
    case HNSWLib.Index.get_current_count(index) do
      {:ok, 0} ->
        Logger.warning("Empty index")
        {:reply, :error, state}

      {:ok, _} ->
        {:reply, :ok, state}
    end
  end
end
