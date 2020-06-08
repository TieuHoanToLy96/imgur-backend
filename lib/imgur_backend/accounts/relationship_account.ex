defmodule ImgurBackend.Accounts.RelationshipAccount do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Accounts.RelationshipAccount

  schema "relationship_accounts" do
    field(:account_one_id, :binary_id)
    field(:account_two_id, :binary_id)
    field(:status, :integer)

    timestamps()
  end

  def changeset(%RelationshipAccount{} = ra, attrs \\ %{}) do
    ra
    |> cast(attrs, [:account_one_id, :account_two_id, :status])
  end

  def to_json("relation_account.json", relation_account \\ %{}) do
    Map.take(relation_account, [:account_one_id, :account_two_id, :status])
  end
end
