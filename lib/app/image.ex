defmodule App.Image do
  use Ecto.Schema
  alias App.{Image, Repo}

  @primary_key {:id, :id, autogenerate: true, source: :rowid}
  schema "images" do
    field(:url, :string)
    field(:info, :string)
    field(:width, :integer)
    field(:height, :integer)

    timestamps()
  end

  def changeset(image, params \\ %{}) do
    image
    |> Ecto.Changeset.cast(params, [:url, :info, :width, :height])
    |> Ecto.Changeset.validate_required([:url, :info, :width, :height])
  end

  def insert(attrs) do
    %Image{}
    |> changeset(attrs)
    |> Repo.insert!()
  end
end
