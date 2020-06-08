defmodule ImgurBackend.Conversations.ConversationAccount do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Conversations.ConversationAccount
  alias ImgurBackend.Accounts.Account
  alias ImgurBackendWeb.V1.AccountView

  schema "conversations_accounts" do
    field(:conversation_id, :binary_id, null: false)
    # field(:account_id, :binary_id, null: false)
    field(:is_deleted, :boolean, default: false)
    field(:last_deleted, :naive_datetime)
    field(:unread_count, :integer, default: 0)
    field(:seen, :boolean, default: false)

    belongs_to(:account, Account, foreign_key: :account_id, type: Ecto.UUID)
    timestamps()
  end

  def changeset(%ConversationAccount{} = ca, attrs \\ %{}) do
    ca
    |> cast(attrs, [
      :conversation_id,
      :account_id,
      :is_deleted,
      :last_deleted,
      :unread_count,
      :seen
    ])
  end

  def to_json("conversation_account.json", ca) do
    data =
      Map.take(ca, [
        :conversation_id,
        :account_id,
        :is_deleted,
        :last_deleted,
        :unread_count,
        :seen
      ])

    data =
      if Ecto.assoc_loaded?(ca.account) do
        account = AccountView.render("account_just_loaded.json", ca.account)

        Map.put(data, :account, account)
      else
        data
      end

    data
  end

  def to_json("conversation_accounts.json", ca) do
    Enum.map(ca, &to_json("conversation_account.json", &1))
  end
end
