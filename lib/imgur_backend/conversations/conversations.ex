defmodule ImgurBackend.Conversations do
  import Ecto.Query, warn: false
  alias ImgurBackend.Repo

  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Conversations.{ConversationAccount, Conversation, Message}

  def create_or_update_conversation(creator_id, params) do
    if params["id"] do
      Repo.get_by(Conversation, %{id: params["id"]})
      |> case do
        nil ->
          {:error, :entity_not_existed}

        value ->
          data = %{
            title: params["title"] || ""
          }

          Conversation.changeset(value, data)
          |> Repo.update()
      end
    else
      data =
        %{
          creator_id: creator_id,
          title: params["title"] || ""
        }
        |> IO.inspect(label: "daaaaa")

      Conversation.changeset(%Conversation{}, data)
      |> Repo.insert()
      |> IO.inspect(label: "Conversation")
    end
  end

  def create_conversation_accounts(acount_id, conversation_id, params) do
    account_ids = params["account_ids"] || []
    account_ids = account_ids ++ [acount_id]

    {success, error} =
      Enum.map(account_ids, fn el ->
        %{
          account_id: el,
          conversation_id: conversation_id
        }
      end)
      |> Enum.reduce({[], []}, fn el, acc ->
        {s, e} = acc
        IO.inspect(el, label: "1111111111")

        %ConversationAccount{}
        |> ConversationAccount.changeset(el)
        |> Repo.insert()
        |> IO.inspect()
        |> case do
          {:ok, value} ->
            {s ++ [value], e}

          {:error, changeset} ->
            {s, e ++ [changeset]}
        end
      end)

    if error == [] do
      {:ok, success}
    else
      {:error, error}
    end
  end

  def check_existed_conversation(account_id, params) do
    account_ids = params["account_ids"]

    if !account_ids || account_ids == [] do
      {:error, "Hội thoại không có thành viên"}
    else
      from(ca in ConversationAccount)

      {:ok, :pass}
    end
  end

  def get_conversations(account_id, params) do
    term = params["term"]

    preload_message = from(m in Message)
    preload_account = from(a in Account)

    preload_con_acc =
      from(
        ca in ConversationAccount,
        preload: [account: ^preload_account]
      )

    condition_where = dynamic([c, ca], ca.account_id == ^account_id and not ca.is_deleted)

    condition_where =
      if term do
        dynamic([c, ca], ^condition_where and ilike(c.title, ^"%#{term}%"))
      else
        condition_where
      end

    query =
      from(
        c in Conversation,
        left_join: ca in ConversationAccount,
        on: ca.conversation_id == c.id,
        where: ^condition_where,
        preload: [conversation_accounts: ^preload_con_acc],
        order_by: [desc: c.inserted_at]
      )

    {:ok, Repo.all(query)}
  end

  def send_message(account_id, params) do
    data = %{
      message: params["message"],
      type: "text",
      conversation_id: params["conversation_id"],
      account_id: account_id
    }

    %Message{}
    |> Message.changeset(data)
    |> Repo.insert()
  end

  def update_unread_count(account_id, conversation_id) do
    {success, error} =
      from(
        ca in ConversationAccount,
        where:
          ca.conversation_id == ^conversation_id and not ca.is_deleted and
            ca.account_id == ^account_id
      )
      |> Repo.all()
      |> Enum.reduce({[], []}, fn el, acc ->
        {s, e} = acc

        data = %{
          unread_count: el.unread_count + 1
        }

        ConversationAccount.changeset(el, data)
        |> Repo.update()
        |> case do
          {:ok, value} -> {s ++ [value], e}
          {:error, changeset} -> {s, e ++ [changeset]}
        end
      end)

    if error == [] do
      {:ok, success}
    else
      {:error, error}
    end
  end

  def get_messages(account_id, params) do
    preload_account = from(a in Account)

    messages =
      from(
        m in Message,
        where: m.conversation_id == ^params["conversation_id"] and not m.is_deleted,
        preload: [account: ^preload_account],
        order_by: [desc: m.inserted_at]
      )
      |> Repo.all()

    {:ok, messages}
  end

  def get_conversation(id) do
    preload_message = from(m in Message)
    preload_account = from(a in Account)

    preload_con_acc =
      from(
        ca in ConversationAccount,
        preload: [account: ^preload_account]
      )

    query =
      from(
        c in Conversation,
        where: c.id == ^id,
        preload: [conversation_accounts: ^preload_con_acc]
      )

    Repo.one(query)
  end

  def update_conversations(params) do
  end
end
