defmodule App.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :url, :string
      add :info, :string
      add :width, :integer
      add :height, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
