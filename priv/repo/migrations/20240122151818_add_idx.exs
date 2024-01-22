defmodule App.Repo.Migrations.AddIdx do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add(:idx, :integer, default: 0)
    end
  end
end
