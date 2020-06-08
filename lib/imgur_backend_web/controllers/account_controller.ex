defmodule ImgurBackendWeb.V1.AccountController do
  use ImgurBackendWeb, :controller
  alias Ecto.Multi
  import Ecto.Query, warn: false

  alias ImgurBackend.Accounts.{Account, RelationshipAccount, Notification}
  alias ImgurBackend.Accounts
  alias ImgurBackendWeb.V1.AccountView
  alias ImgurBackend.App.Tools
  alias ImgurBackend.Guardian
  alias ImgurBackend.Repo

  action_fallback(ImgurBackendWeb.FallbackController)

  def auth_account(conn, %{"accessToken" => token}) do
    if Tools.is_empty?(token) do
      {:failed, :success_false_with_reason, "Bạn chưa có tài khoản"}
    else
      with {:ok, value} <-
             ImgurBackend.Guardian.decode_and_verify(token),
           {:ok, account} <- Accounts.get_account(value["id"]),
           {:ok, count} <- Accounts.count_notifications(value["id"]) do
        account =
          AccountView.render("account_just_loaded.json", account)
          |> Map.put(:count_noti, count)
          |> IO.inspect()

        {:success, :with_data, account}
      else
        reason ->
          IO.inspect(reason, label: "aaaaaaaa")
          {:failed, :success_false_with_reason, "Error"}
      end
    end
  end

  def sign_in(conn, %{"email" => email, "password_hash" => password_hash}) do
    user = Accounts.get_account_by_email(email)

    with {:ok, account} <- Account.check_password(password_hash, user),
         {:ok, token, _} <-
           ImgurBackend.Guardian.encode_and_sign(
             account,
             %{
               id: account.id,
               email: account.email,
               user_name: account.user_name,
               avatar: account.avatar
             },
             week: 4
           ) do
      account = AccountView.render("account_just_loaded.json", account)

      conn
      |> put_status(:ok)
      |> json(%{success: true, account: account, token: token})
    end
  end

  def create(
        _conn,
        %{
          "user_name" => user_name,
          "email" => email,
          "password_hash" => password_hash,
          "confirm_password" => confirm_password
        } = _params
      ) do
    cond do
      password_hash != confirm_password ->
        {:failed, :success_false_with_reason, "Mật khẩu không khớp"}

      !Tools.validate_email(email) ->
        {:failed, :success_false_with_reason, "Email không hợp lệ"}

      true ->
        data = %{
          user_name: user_name,
          email: email,
          password_hash: password_hash
        }

        with {:ok, account} <- Accounts.create_account(data),
             {:ok, token, _} <-
               ImgurBackend.Guardian.encode_and_sign(account, %{
                 id: account.id,
                 email: account.email,
                 user_name: account.user_name,
                 avatar: account.avatar
               }) do
          account = AccountView.render("account_just_loaded.json", account)

          {:success, :with_data, :data, %{account: account, token: token}}
        else
          {:error, changeset} ->
            message = Tools.get_error_message_from_changeset(changeset)
            {:failed, :success_false_with_reason, message}
        end
    end
  end

  def update(_conn, params) do
    with {:ok, params} <- Accounts.get_update_account_params(params),
         {:ok, account} <- Accounts.get_account(params["account"]["id"]),
         {:ok, updated_account} <- Accounts.update_account(account, params["account"]) do
      account = AccountView.render("account_just_loaded.json", updated_account)
      {:success, :with_data, :data, %{account: account}}
    else
      {:error, message} ->
        {:failed, :success_false_with_reason, message}

      _ ->
        {:failed, :success_false_with_reason, "error"}
    end
  end

  def get_user(conn, params) do
    current_account_id = conn.assigns.account.id

    with {:ok, value} <- Accounts.get_user_by_url(params["account_url"]),
         {:ok, relation_account} <- Accounts.get_friend_request(current_account_id, value.id) do
      IO.inspect(relation_account, label: "ddd")

      relation_account =
        RelationshipAccount.to_json("relation_account.json", relation_account || %{})

      value =
        AccountView.render("account_just_loaded.json", value)
        |> Map.put(:relation_account, relation_account)

      {:success, :with_data, :user, value}
    else
      {:error, :entity_not_existed} ->
        message = "Account not existed"
        {:failed, :success_false_with_reason, message}
    end
  end

  def send_friend_request(conn, params) do
    current_account = conn.assigns.account

    multi =
      Multi.new()
      |> Multi.run(:relationship_account, fn _ ->
        Accounts.update_friend_request(current_account.id, params, 1)
      end)
      |> Multi.run(:notification, fn _ ->
        data = %{
          content: "gửi lời mời kết bạn",
          url: "",
          sender_id: current_account.id,
          receiver_id: params["account_id"],
          type: 1
        }

        Accounts.send_notification(data)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        notification =
          Repo.preload(result.notification,
            sender: from(a in Account),
            receiver: from(a in Account)
          )

        notification = Notification.to_json("notification.json", notification)

        {:success, :with_data, notification, "Gửi yêu cầu thành công"}

      reason ->
        IO.inspect(reason, label: "send_friend_request ERROR")
        {:failed, :success_false_with_reason, "Gửi yêu cầu thất bại !"}
    end
  end

  def accept_friend_request(conn, params) do
    current_account = conn.assigns.account

    multi =
      Multi.new()
      |> Multi.run(:relationship_account, fn _ ->
        Accounts.update_friend_request(
          params["account_id"],
          params |> Map.put("account_id", current_account.id),
          2
        )
      end)
      |> Multi.run(:notification, fn _ ->
        data = %{
          id: params["id"],
          content: "đã chấp nhận lời mời kết bạn của",
          seen: true,
          type: 2
        }

        Accounts.update_notification(data)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        notification =
          Repo.preload(result.notification,
            sender: from(a in Account),
            receiver: from(a in Account)
          )

        notification = Notification.to_json("notification.json", notification)

        {:success, :with_data, notification, "Chấp nhận yêu cầu thành công"}

      reason ->
        IO.inspect(reason, label: "send_friend_request ERROR")
        {:failed, :success_false_with_reason, "Chấp nhận yêu cầu thất bại !"}
    end
  end

  def cancel_friend_request(conn, params) do
    current_account = conn.assigns.account

    multi =
      Multi.new()
      |> Multi.run(:relationship_account, fn _ ->
        Accounts.update_friend_request(
          params["account_id"],
          params |> Map.put("account_id", current_account.id),
          0
        )
      end)
      |> Multi.run(:notification, fn _ ->
        data = %{
          id: params["id"],
          content: "đã xoá lời mời kết bạn của",
          seen: true,
          type: 0
        }

        Accounts.update_notification(data)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        notification =
          Repo.preload(result.notification,
            sender: from(a in Account),
            receiver: from(a in Account)
          )

        notification = Notification.to_json("notification.json", notification)
        {:success, :with_data, notification, "Xoá yêu cầu thành công"}

      reason ->
        IO.inspect(reason, label: "delete_friend_request ERROR")
        {:failed, :success_false_with_reason, "Xoá yêu cầu thất bại !"}
    end
  end

  def mark_seen_notifications(conn, params) do
    current_account_id = conn.assigns.account.id

    with {:ok, n} <- Accounts.mark_seen_notifications(current_account_id, params),
         {:ok, notification} <- Accounts.get_notification(n.id) do
      notification = Notification.to_json("notification.json", notification)
      {:success, :with_data, notification, "Xoá yêu cầu thành công"}
    end
  end

  def get_notifications(conn, params) do
    current_account_id = conn.assigns.account.id

    with {:ok, notifications} <- Accounts.get_notifications(current_account_id, params) do
      notifications = Notification.to_json("notifications.json", notifications)

      {:success, :with_data, :data, %{notifications: notifications}}
    end
  end

  def search_friend(conn, params) do
    current_account_id = conn.assigns.account.id

    with {:ok, friends} <- Accounts.search_friend(current_account_id, params) do
      friends = AccountView.render_many("accounts.json", friends)
      {:success, :with_data, :data, %{friends: friends}}
    end
  end
end
