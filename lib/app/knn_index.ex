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
  @saved_index (if(Application.compile_env(:app, :knnindex_indices_test, false)) do
    Path.join(@upload_dir, "indexes_test.bin")
  else
    Path.join(@upload_dir, "indexes.bin")
  end)

  # client API ------------------
  def start_link(space) do
    :ok = File.mkdir_p!(@upload_dir)
    GenServer.start_link(__MODULE__, space, name: __MODULE__)
  end

  def index_path do
    @saved_index
  end

  def load_index do
    GenServer.call(__MODULE__, :load_index)
  end

  def save_index_to_db do
    GenServer.call(__MODULE__, :save_index_to_db)
  end

  def get_count do
    GenServer.call(__MODULE__, :get_count)
  end

  # def get_index do
  #   GenServer.call(__MODULE__, :get_index)
  # end

  def add_item(embedding) do
    GenServer.call(__MODULE__, {:add_item, embedding})
  end

  def knn_search(input) do
    GenServer.call(__MODULE__, {:knn_search, input})
  end

  def not_empty_index do
    GenServer.call(__MODULE__, :not_empty)
  end

  @doc """
  Called `on_mount`to halt the Liveview in case the Index file length
  is not equal to the count of images in the db.
  """

  # def check_index_integrity do
  #   GenServer.call(__MODULE__, :integrity)
  # end

  # ---------------------------------------------------
  @impl true
  def init(space) do
    :ok = File.mkdir_p!(@upload_dir)

    case File.exists?(@saved_index) do
      false ->
        App.HnswlibIndex.maybe_load_index_from_db(space, @dim, @max_elements)
        |> case do
          {:ok, index, index_schema} -> {:ok, {index, index_schema, space}}
          {:error, msg} -> {:stop, {:error, msg}}
        end

      true ->
        Logger.info("Existing Index")

        App.Repo.get_by(App.HnswlibIndex, id: 1)
        |> case do
          nil ->
            {:stop, {:error, "Incoherence on table"}}

          schema ->
            check_integrity(schema, space)
        end
    end
  end

  defp check_integrity(schema, space) do
    HNSWLib.Index.load_index(space, @dim, @saved_index)
    |> case do
      {:ok, index} ->
        index_count =
          HNSWLib.Index.get_current_count(index)
          |> case do
            {:ok, index_db} ->
              index_db

            {:error, msg} ->
              Logger.warning(inspect(msg))
              :error
          end

        len = App.Repo.all(App.Image) |> length()

        if index_count == len do
          Logger.info("Integrity: " <> "\u2705")
          {:ok, {index, schema, space}}
        else
          dbg(index_count)
          dbg(len)
          {:stop, {:error, "Integrity error"}}
        end

      {:error, msg} ->
        {:stop, {:error, msg}}
    end
  end

  @impl true
  # def handle_call(:integrity, _, {index, _, _} = state) do
  #   index_count =
  #     HNSWLib.Index.get_current_count(index)
  #     |> case do
  #       {:ok, index_db} ->
  #         index_db

  #       {:error, msg} ->
  #         Logger.warning(inspect(msg))
  #         :error
  #     end

  #   db_length = App.Repo.all(App.Image) |> length()

  #   {:reply, index_count == db_length, state}
  # end

  def handle_call(:load_index, _, {:error, :badarg, space} = state) do
    App.HnswlibIndex.maybe_load_index_from_db(:cosine, @dim, @max_elements)
    |> case do
      {:ok, index, index_schema} ->
        {:reply, index, {index, index_schema, space}}

      {:error, msg} ->
        {:stop, {:error, msg}, state}
    end
  end

  def handle_call(:load_index, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:save_index_to_db, _, {index, index_schema, space} = state) do
    with {:ok, file} <-
           File.read(@saved_index),
         {:ok, updated_schema} <-
           index_schema
           |> App.HnswlibIndex.changeset(%{file: file})
           |> App.Repo.update() do
      {:reply, {:ok, updated_schema}, {index, updated_schema, space}}
    else
      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:get_count, _, {index, _, _} = state) do
    HNSWLib.Index.get_current_count(index)
    |> case do
      {:ok, count} ->
        {:reply, count, state}

      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
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
      msg ->
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

    # end
  end

  def handle_call(:not_empty, _, {index, _, _} = state) do
    case HNSWLib.Index.get_current_count(index) do
      {:ok, 0} ->
        {:reply, :error, state}

      {:ok, _} ->
        {:reply, :ok, state}
    end
  end
end
