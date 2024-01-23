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

  def save(index) do
    bin =
      index
      |> :erlang.term_to_binary()

    App.Repo.get!(App.HnswlibIndex, 1)
    |> App.HnswlibIndex.changeset(%{file: bin})
    |> App.Repo.update()
  end

  def maybe_load_index_from_db(space, dim, max_elements) do
    App.Repo.get_by(App.HnswlibIndex, id: 1)
    |> case do
      nil ->
        App.HnswlibIndex.changeset(%__MODULE__{}, %{id: 1})
        |> App.Repo.insert()

        Logger.info("New Index")
        HNSWLib.Index.new(_space = space, _dim = dim, _max_elements = max_elements)

      index_file ->
        {:ok, :erlang.binary_to_term(index_file)}
    end
  end

  # def load(space, dim, max_elements) do
  #   Repo.get_by(HnswlibIndex, id: 1)
  #   |> case do
  #     nil ->
  #       # App.KnnIndex.get_index_path()
  #       # |> File.read!()
  #       # |> :erlang.term_to_binary()
  #       # |> then(fn t ->
  #       #   App.Repo.insert(%App.HnswlibIndex{file: t})
  #       # end)

  #       Logger.info("New Index")
  #       HNSWLib.Index.new(_space = space, _dim = dim, _max_elements = max_elements)

  #     index_file ->
  #       {:ok, :erlang.binary_to_term()}
  #   end
  # end
end
