defmodule ImgurBackend.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Conversations.{Conversation, Message, ConversationAccount}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "conversations" do
    field(:message_count, :integer)
    field(:creator_id, :binary_id)
    field(:title, :string)

    has_many(:messages, Message, foreign_key: :conversation_id)
    has_many(:conversation_accounts, ConversationAccount, foreign_key: :conversation_id)
    timestamps()
  end

  def changeset(%Conversation{} = c, attrs \\ %{}) do
    c
    |> cast(attrs, [:message_count, :creator_id, :title])
  end

  def to_json("conversation.json", c) do
    data = Map.take(c, [:id, :message_count, :creator_id, :title])

    data =
      if Ecto.assoc_loaded?(c.conversation_accounts) do
        conversation_accounts =
          ConversationAccount.to_json("conversation_accounts.json", c.conversation_accounts)

        Map.put(data, :conversation_accounts, conversation_accounts)
      else
        data
      end

    data
  end

  def to_json("conversations.json", c) do
    Enum.map(c, &to_json("conversation.json", &1))
  end
end
