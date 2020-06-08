defmodule ImgurBackend.Conversations.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Conversations.Message
  alias ImgurBackend.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "messages" do
    field(:message, :string)
    field(:images, {:array, :string})
    field(:type, :string)
    field(:seen, :boolean, default: false)
    field(:accounts_seen, {:array, :binary_id}, default: [])
    field(:is_deleted, :boolean, default: false)
    # field(:account_id, :binary_id, null: false)
    field(:conversation_id, :binary_id, null: false)

    belongs_to(:account, Account, foreign_key: :account_id, type: :binary_id)
    timestamps()
  end

  def changeset(%Message{} = m, attrs \\ %{}) do
    m
    |> cast(attrs, [
      :message,
      :images,
      :type,
      :seen,
      :accounts_seen,
      :is_deleted,
      :account_id,
      :conversation_id
    ])
  end

  def to_json("message.json", m) do
    data =
      Map.take(m, [
        :message,
        :images,
        :type,
        :seen,
        :accounts_seen,
        :is_deleted,
        :account_id,
        :conversation_id,
        :inserted_at
      ])

    data =
      if Ecto.assoc_loaded?(m.account) do
        account = Account.to_json("account.json", m.account)
        Map.put(data, :account, account)
      else
        data
      end

    data
  end

  def to_json("messages.json", m) do
    Enum.map(m, &to_json("message.json", &1))
  end
end
