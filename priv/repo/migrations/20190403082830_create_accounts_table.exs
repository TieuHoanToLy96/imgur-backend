defmodule ImgurBackend.Repo.Migrations.CreateAccountsTable do
  use Ecto.Migration

  def up do
    create table(:accounts, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:user_name, :string, null: false)
      add(:email, :string, null: false)
      add(:avatar, :string)
      add(:password_hash, :string, null: false)
      add(:is_global_admin, :boolean, default: false)

      timestamps()
    end

    create(unique_index(:accounts, [:user_name]))
    create(unique_index(:accounts, [:email]))
  end

  def down do
    drop_if_exists(table(:accounts))
    drop_if_exists(unique_index(:accounts, [:user_name, :email]))
  end
end
