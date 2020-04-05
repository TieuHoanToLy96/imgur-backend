defmodule ImgurBackend.Repo.Migrations.UpdateDatabase do
  use Ecto.Migration

  def up do
    alter table(:article_views) do
      add(:count, :integer, default: 0)
    end
  end

  def down do
    alter table(:article_views) do
      remove(:count)
    end
  end
end
