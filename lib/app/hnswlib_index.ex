defmodule App.HnswlibIndex do
  use Ecto.Schema

  alias App.HnswlibIndex
  alias App.Repo

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

  def maybe_load_index_from_db(space, dim, max_elements) do
    IO.puts("maybe load index from db -----------")
    # check if the table has an entry
    Repo.get_by(HnswlibIndex, id: 1)
    |> case do
      nil ->
        # table empty
        Logger.info("New Index")
        create(space, dim, max_elements)

      response when response.file == nil ->
        # table is not empty but has no file
        Logger.info("Recreate Index")
        # recreate the table
        App.Repo.delete_all(App.HnswlibIndex)

        create(space, dim, max_elements)

      index_db ->
        # table is not empty and has a file
        Logger.info("Loading Index from DB")

        with path <-
               App.KnnIndex.index_path(),
             # save on disk
             :ok <-
               File.write(path, index_db.file),
             # load the index file
             {:ok, index} <-
               HNSWLib.Index.load_index(space, dim, path) do
          {:ok, index, index_db}
        else
          {:error, msg} -> {:error, msg}
        end
    end
  end

  defp create(space, dim, max_elements) do
    HnswlibIndex.changeset(%__MODULE__{}, %{id: 1})
    |> Repo.insert()
    |> case do
      {:ok, schema} ->
        HNSWLib.Index.new(space, dim, max_elements)
        |> Tuple.append(schema)

      {:error, msg} ->
        {:error, msg}
    end
  end
end
