defmodule ImgurBackend.Repo.Migrations.AddSettingsAccount do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      add(:settings, :map)
    end

    alter table(:articles) do
      add(:is_story, :boolean, default: false)
    end
  end

  def down do
    alter table(:accounts) do
      remove(:settings)
    end

    alter table(:articles) do
      remove(:is_story)
    end
  end
end
