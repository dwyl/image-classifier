defmodule App.Repo.Migrations.CreateTableHnswlibIndex do
  use Ecto.Migration

  def change do
    create_if_not_exists table("hnswlib_index") do
      add :file, :binary
    end
  end
end
