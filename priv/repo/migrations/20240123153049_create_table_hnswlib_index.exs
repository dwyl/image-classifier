defmodule App.Repo.Migrations.CreateTableHnswlibIndex do
  use Ecto.Migration

  def change do
    create_if_not_exists table("hnswlib_index") do
      add :lock_version, :integer, default: 1
      add :file, :binary
    end
  end
end
