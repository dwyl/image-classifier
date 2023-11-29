defmodule App.Repo.Migrations.CreateImagesTable do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :url, :string
      add :info, :string
      add :width, :integer
      add :height, :integer

      timestamps()
    end
  end
end
