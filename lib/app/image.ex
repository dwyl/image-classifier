defmodule App.Image do
  use Ecto.Schema
  alias App.{Image, Repo}

  @primary_key {:id, :id, autogenerate: true, source: :rowid}
  schema "images" do
    field :description, :string
    field :width, :integer
    field :url, :string
    field :height, :integer

    timestamps(type: :utc_datetime)
  end

  def changeset(image, params \\ %{}) do
    image
    |> Ecto.Changeset.cast(params, [:url, :description, :width, :height])
    |> Ecto.Changeset.validate_required([:url, :description, :width, :height])
  end

  def insert(attrs) do
    %Image{}
    |> changeset(attrs)
    |> Repo.insert!()
  end
end
