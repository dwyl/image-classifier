defmodule App.HnswlibIndex do
  use Ecto.Schema

  alias App.HnswlibIndex
  alias App.Repo

  require Logger

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
    path = App.KnnIndex.get_index_path()
    file = File.read!(path)

    Repo.get!(HnswlibIndex, 1)
    |> HnswlibIndex.changeset(%{file: file})
    |> Repo.update()
  end

  def maybe_load_index_from_db(space, dim, max_elements) do
    Repo.get_by(HnswlibIndex, id: 1)
    |> case do
      nil ->
        # create a singleton row
        HnswlibIndex.changeset(%__MODULE__{}, %{id: 1})
        |> Repo.insert()

        Logger.info("New Index")
        HNSWLib.Index.new(space, dim, max_elements)

      index_file ->
        Logger.info("Loading Index from DB")
        path = App.KnnIndex.get_index_path()
        # save on disk
        File.write!(path, index_file.file)
        # load the index file
        HNSWLib.Index.load_index(space, dim, path)
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
end
