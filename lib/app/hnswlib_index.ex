defmodule App.HnswlibIndex do
  use Ecto.Schema

  require Logger

  schema "hnswlib_index" do
    field(:file, :binary)
  end

  def changeset(struct \\ %__MODULE__{}, params \\ %{}) do
    struct
    |> Ecto.Changeset.cast(params, [:id, :file])
    |> Ecto.Changeset.validate_required([:id])
  end

  def save() do
    path = App.KnnIndex.get_index_path()
    file = File.read!(path)

    App.Repo.get!(App.HnswlibIndex, 1)
    |> App.HnswlibIndex.changeset(%{file: file})
    |> App.Repo.update()
  end

  def maybe_load_index_from_db(space, dim, max_elements) do
    App.Repo.get_by(App.HnswlibIndex, id: 1)
    |> dbg()
    |> case do
      nil ->
        App.HnswlibIndex.changeset(%__MODULE__{}, %{id: 1})
        |> App.Repo.insert()

        Logger.info("New Index")
        HNSWLib.Index.new(_space = space, _dim = dim, _max_elements = max_elements)

      index_file ->
        Logger.info("Loading Index from DB")
        path = App.KnnIndex.get_index_path()
        File.write!(path, index_file.file)
        HNSWLib.Index.load_index(space, dim, path)
        HNSWLib.Index.load_index(space, dim, path)
    end
  end
end
