defmodule ImgurBackend.Repo.Migrations.InitDatabase do
  use Ecto.Migration

  def up do
    create table(:relation_friends, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:account_one_id, :binary_id, null: false)
      add(:account_two_id, :binary_id, null: false)

      timestamps()
    end

    create table(:articles, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:title, :string, null: false)
      add(:description, :text)
      add(:contents, {:array, :map}, default: [])
      add(:views, {:array, :map}, default: [])
      add(:reactions, {:array, :map}, default: [])
      add(:is_deleted, :boolean, default: false)
      add(:is_published, :boolean, default: false)

      add(:creator_id, :binary_id, null: false)
      timestamps()
    end

    create table(:tags) do
      add(:title, :string)
      add(:images, {:array, :text}, default: [])
      add(:color, :string)
    end

    create table(:articles_tags, primary_key: false) do
      add(:is_deleted, :boolean, default: false)
      add(:article_id, :binary_id, null: false)
      add(:tag_id, :binary_id, null: false)
    end

    create table(:comments, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:is_deleted, :boolean, default: false)
      add(:content, :text, null: false)
      add(:image, :text)
      add(:reactions, {:array, :map}, default: [])
      add(:parent_id, :binary_id)
      add(:creator_id, :binary_id, null: false)
      add(:article_id, :binary_id, null: false)

      timestamps()
    end

    create table(:conversations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:unread_count, :int)
      add(:message_count, :bigint)
      add(:seen, :boolean, default: false)

      timestamps()
    end

    create table(:conversations_accounts, primary_key: false) do
      add(:is_deleted, :boolean, default: false)
      add(:conversation_id, :binary_id, null: false)
      add(:creator_id, :binary_id, null: false)
      add(:account_id, :binary_id, null: false)

      timestamps()
    end

    create table(:messages, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:message, :text)
      add(:type, :integer)
      add(:reactions, {:array, :map}, default: [])
      add(:seen, :boolean, default: false)
      add(:is_deleted, :boolean, default: false)
      add(:creator_id, :binary_id, null: false)
      timestamps()
    end
  end

  def down do
    drop_if_exists(table(:articles))
  end
end
