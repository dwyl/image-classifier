defmodule App.HnswlibIndex do
  use Ecto.Schema

  alias App.HnswlibIndex
  alias App.Repo

  require Logger

  @saved_index Path.expand("priv/static/uploads/indexes.bin")

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

  def save() do
    try do
      path = App.KnnIndex.get_index_path()
      file = File.read!(path)

      Repo.get!(HnswlibIndex, 1)
      |> HnswlibIndex.changeset(%{file: file})
      |> Repo.update()
    rescue
      e in Ecto.StaleEntryError ->
        require Logger
        Logger.warning(inspect(e))
        Process.sleep(10)
        save()
    end
  end

  def maybe_load_index_from_db(space, dim, max_elements) do
    # check if the table has an entry
    Repo.get_by(HnswlibIndex, id: 1)
    |> case do
      # table empty
      nil ->
        # create a singleton row
        Logger.info("New Index")

        HnswlibIndex.changeset(%__MODULE__{}, %{id: 1})
        |> Repo.insert()
        |> case do
          {:ok, _index} ->
            HNSWLib.Index.new(space, dim, max_elements)

          {:error, msg} ->
            {:error, msg}
        end

      # table is not empty but has no file
      response when response.file == nil ->
        Logger.info("Recreate Index")

        App.Repo.delete_all(App.HnswlibIndex)

        HnswlibIndex.changeset(%__MODULE__{}, %{id: 1})
        |> Repo.insert()
        |> case do
          {:ok, _index} ->
            HNSWLib.Index.new(space, dim, max_elements)

          {:error, msg} ->
            {:error, msg}
        end

      # table is not empty and has a file
      index_file ->
        Logger.info("Loading Index from DB")

        with path <- App.KnnIndex.get_index_path(),
             # save on disk
             :ok <- File.write(path, index_file.file) do
          # load the index file
          HNSWLib.Index.load_index(space, dim, path)
        else
          {:error, msg} -> {:error, msg}
        end
    end
  end

  def not_empty_index(index) do
    case HNSWLib.Index.get_current_count(index) do
      {:ok, 0} ->
        :error

      {:ok, _} ->
        :ok
    end
  end

  def index_file do
    @saved_index
  end
end
