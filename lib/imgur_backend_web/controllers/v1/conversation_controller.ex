defmodule ImgurBackendWeb.V1.ConversationController do
  use ImgurBackendWeb, :controller
  alias Ecto.Multi
  import Ecto.Query, warn: false
  alias ImgurBackend.{Conversations, Repo}
  alias ImgurBackend.Conversations.{Conversation, Message}

  action_fallback(ImgurBackendWeb.FallbackController)

  def create_conversation(conn, params) do
    current_account_id = conn.assigns.account.id

    multi =
      Multi.new()
      |> Multi.run(:existed_conversation, fn _ ->
        Conversations.check_existed_conversation(current_account_id, params)
      end)
      |> Multi.run(:conversation, fn _ ->
        Conversations.create_or_update_conversation(current_account_id, params)
      end)
      |> Multi.run(:conversation_accounts, fn %{conversation: conversation} ->
        Conversations.create_conversation_accounts(current_account_id, conversation.id, params)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        conversation = Conversations.get_conversation(result.conversation.id)
        conversation = Conversation.to_json("conversation.json", conversation)
        {:success, :with_data, :data, %{conversation: conversation}}

      reason ->
        IO.inspect(reason, label: "oooooo")
        {:failed, :with_reason, reason, "Tạo hội thoại thất bại"}
    end
  end

  def get_conversations(conn, params) do
    current_account_id = conn.assigns.account.id

    with {:ok, conversations} <- Conversations.get_conversations(current_account_id, params) do
      conversations = Conversation.to_json("conversations.json", conversations)

      {:success, :with_data, :data, %{conversations: conversations}}
    end
  end

  def send_message(conn, params) do
    current_account_id = conn.assigns.account.id

    multi =
      Multi.new()
      |> Multi.run(:message, fn _ ->
        Conversations.send_message(current_account_id, params)
      end)
      |> Multi.run(:conversations_accounts, fn _ ->
        Conversations.update_unread_count(current_account_id, params["conversation_id"])
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        message = Repo.preload(result.message, [:account])
        message = Message.to_json("message.json", message)
        {:success, :with_data, :data, %{message: message}}

      reason ->
        {:failed, :with_reason, reason, "Gửi tin nhắn thất bại"}
    end
  end

  def get_messages(conn, params) do
    current_account_id = conn.assigns.account.id

    with {:ok, messages} <- Conversations.get_messages(current_account_id, params) do
      messages =
        Message.to_json("messages.json", messages)
        |> Enum.map(fn el ->
          if el.account_id != current_account_id,
            do: Map.put(el, :is_left, true),
            else: Map.put(el, :is_left, false)
        end)

      {:success, :with_data, :data, %{messages: messages}}
    end
  end

  def update_conversations(conn, params) do
    multi =
      Multi.new()
      |> Multi.run(:conversation, fn _ ->
        Conversations.create_or_update_conversation(nil, params)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        conversation = Conversations.get_conversation(result.conversation.id)
        conversation = Conversation.to_json("conversation.json", conversation)
        {:success, :with_data, :data, %{conversation: conversation}}

      reason ->
        IO.inspect(reason, label: "oooooo")
        {:failed, :with_reason, reason, "Cập nhật hội thoại thất bại"}
    end
  end
end
