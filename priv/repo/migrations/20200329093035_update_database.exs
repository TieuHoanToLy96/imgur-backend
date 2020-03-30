defmodule ImgurBackend.Repo.Migrations.UpdateDatabase do
  use Ecto.Migration

  def up do
    create table(:article_contents) do
      add(:article_id, :binary_id, null: false)
      add(:description, :text)
      add(:image, :text, null: false)
      add(:is_deleted, :boolean, default: false)
      add(:type, :integer, default: 0)

      timestamps()
    end

    alter table(:articles) do
      remove(:description)
      remove(:contents)
    end

    alter table(:articles_tags) do
      remove(:tag_id)
      add(:tag_id, :bigint)
    end
  end

  def down do
    drop_if_exists(table(:article_contents))

    alter table(:articles) do
      add(:description, :text)
      add(:contents, {:array, :text})
    end
  end
end
