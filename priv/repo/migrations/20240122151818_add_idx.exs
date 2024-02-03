defmodule App.Repo.Migrations.AddIdx do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add(:idx, :bigint)
      add(:sha1, :string)
    end

    create unique_index(:images, [:sha1])
    create unique_index(:images, [:idx])
  end
end
