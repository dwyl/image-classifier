defmodule App.HnswlibIndex do
  use Ecto.Schema
  alias App.HnswlibIndex

  require Logger

  @moduledoc """
  Ecto schema to save the HNSWLib Index file into a singleton table
  with utility functions
  """

  schema "hnswlib_index" do
    field(:file, :binary)
    field(:lock_version, :integer, default: 1)
  end

  def changeset(struct \\ %__MODULE__{}, params \\ %{}) do
    struct
    |> Ecto.Changeset.cast(params, [:id, :file])
    |> Ecto.Changeset.optimistic_lock(:lock_version)
    |> Ecto.Changeset.validate_required([:id])
  end

  @doc """
  Tries to load index from DB.
  If the table is empty, it creates a new one.
  If the table is not empty but there's no file, an index is created from scratch.
  If there's one, we use it and load it to be used throughout the application.
  """
  def maybe_load_index_from_db(space, dim, max_elements) do
    # Check if the table has an entry
    App.Repo.get_by(HnswlibIndex, id: 1)
    |> case do
      # If the table is empty
      nil ->
        Logger.info("ℹ️ No index file found in DB. Creating new one...")
        create(space, dim, max_elements)

      # If the table is not empty but has no file
      response when response.file == nil ->
        Logger.info("ℹ️ Empty index file in DB. Recreating one...")

        # Purge the table and create a new file row in it
        App.Repo.delete_all(App.HnswlibIndex)
        create(space, dim, max_elements)

      # If the table is not empty and has a file
      index_db ->
        Logger.info("ℹ️ Index file found in DB. Loading it...")

        # We get the path of the index
        with path <- App.KnnIndex.index_path(),
             # Save the file on disk
             :ok <- File.write(path, index_db.file),
             # And load it
             {:ok, index} <- HNSWLib.Index.load_index(space, dim, path) do
          {:ok, index, index_db}
        end
    end
  end

  defp create(space, dim, max_elements) do
    # Inserting the row in the table
    {:ok, schema} =
      HnswlibIndex.changeset(%__MODULE__{}, %{id: 1})
      |> App.Repo.insert()

    # Creates index
    {:ok, index} =
      HNSWLib.Index.new(space, dim, max_elements)

    # Builds index for testing only
    if Application.get_env(:app, :use_test_models, false) do
      empty_index =
        Application.app_dir(:app, ["priv", "static", "uploads"])
        |> Path.join("indexes_empty.bin")

      HNSWLib.Index.save_index(index, empty_index)
    end

    {:ok, index, schema}
  end
end
