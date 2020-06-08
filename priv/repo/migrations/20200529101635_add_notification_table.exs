defmodule ImgurBackend.Repo.Migrations.AddNotificationTable do
  use Ecto.Migration

  def up do
    create table(:notifications) do
      add(:content, :string)
      add(:url, :string)
      add(:sender_id, :binary_id)
      add(:receiver_id, :binary_id)
      add(:type, :integer)
      add(:seen, :boolean, default: false)

      timestamps()
    end
  end

  def down do
    drop(table(:notifications))
  end
end
