defmodule ImgurBackend.Repo.Migrations.CreateDatabase do
  use Ecto.Migration

  def up do
    create table(:accounts, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:user_name, :string, null: false)
      add(:email, :string, null: false)
      add(:account_url, :string, null: false)
      add(:avatar, :string)
      add(:password_hash, :string)
      add(:is_global_admin, :boolean, default: false)

      timestamps()
    end

    create table(:relationship_accounts) do
      add(:account_one_id, :binary_id, null: false)
      add(:account_two_id, :binary_id, null: false)
      add(:status, :integer, default: 0)

      timestamps()
    end

    create table(:conversations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:message_count, :integer)
      add(:creator_id, :binary_id)
      add(:title, :string)
      timestamps()
    end

    create table(:conversations_accounts) do
      add(:conversation_id, :binary_id, null: false)
      add(:account_id, :binary_id, null: false)
      add(:is_deleted, :boolean, default: false)
      add(:last_deleted, :naive_datetime)
      add(:unread_count, :integer, default: 0)
      add(:seen, :boolean, default: false)

      timestamps()
    end

    create table(:messages, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:message, :text)
      add(:images, {:array, :text})
      add(:type, :string)
      add(:seen, :boolean, default: false)
      add(:accounts_seen, {:array, :binary_id}, default: [])
      add(:is_deleted, :boolean, default: false)
      add(:account_id, :binary_id, null: false)
      add(:conversation_id, :binary_id, null: false)

      timestamps()
    end

    create(unique_index(:accounts, [:user_name]))
    create(unique_index(:accounts, [:email]))

    create table(:articles, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:title, :string, null: false)
      add(:description, :text)
      add(:contents, {:array, :map}, default: [])
      add(:is_deleted, :boolean, default: false)
      add(:is_published, :boolean, default: false)
      add(:account_id, :binary_id, null: false)
      add(:type, :integer, default: 0)
      timestamps()
    end

    create table(:comments, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:parent_id, :binary_id, default: nil)
      add(:content, :text)
      add(:images, {:array, :text}, default: [])
      add(:is_deleted, :boolean, default: false)
      add(:article_id, :binary_id, null: false)
      add(:account_id, :binary_id, null: false)

      timestamps()
    end

    create table(:article_views) do
      add(:article_id, :binary_id, null: false)
      add(:account_id, :binary_id, null: false)

      timestamps()
    end

    create table(:article_reactions) do
      add(:article_id, :binary_id, null: false)
      add(:account_id, :binary_id, null: false)
      add(:type_reaction, :integer, default: 0)

      timestamps()
    end

    create table(:comment_reactions) do
      add(:comment_id, :binary_id, null: false)
      add(:account_id, :binary_id, null: false)
      add(:type_reaction, :integer, default: 0)

      timestamps()
    end

    create table(:tags) do
      add(:title, :string)
      add(:images, {:array, :text}, default: [])
      add(:color, :string)

      timestamps()
    end

    create table(:articles_tags) do
      add(:is_deleted, :boolean, default: false)
      add(:article_id, :binary_id, null: false)
      add(:tag_id, :binary_id, null: false)

      timestamps()
    end
  end

  def down do
    drop_if_exists(table(:accounts))
    drop_if_exists(unique_index(:accounts, [:user_name, :email]))
    drop_if_exists(table(:articles))
    drop_if_exists(table(:comments))
    drop_if_exists(table(:tags))
    drop_if_exists(table(:conversations))
    drop_if_exists(table(:conversations_accounts))
    drop_if_exists(table(:relationship_accounts))
    drop_if_exists(table(:articles_tags))
    drop_if_exists(table(:comment_reactions))
    drop_if_exists(table(:article_reactions))
    drop_if_exists(table(:article_views))
    drop_if_exists(table(:messages))
  end
end
