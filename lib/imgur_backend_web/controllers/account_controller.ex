defmodule ImgurBackendWeb.V1.AccountController do
  use ImgurBackendWeb, :controller

  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Accounts
  alias ImgurBackendWeb.V1.AccountView
  alias ImgurBackend.App.Tools
  alias ImgurBackend.Guardian

  action_fallback(ImgurBackendWeb.FallbackController)

  def auth_account(_conn, %{"accessToken" => token}) do
    if Tools.is_empty?(token) do
      {:failed, :success_false_with_reason, "Bạn chưa có tài khoản"}
    else
      with {:ok, value} <- Guardian.decode_and_verify(token),
           {:ok, account} <- Accounts.get_account(value["id"]) do
        account = AccountView.render("account_just_loaded.json", account)

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
    with {:ok, params} <- Accounts.get_update_account_params(params) |> IO.inspect(label: "dddddd"),
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

  def get_user(_conn, params) do
    with {:ok, value} <- Accounts.get_user_by_url(params["account_url"]) do
      value = AccountView.render("account_just_loaded.json", value)
      {:success, :with_data, :user, value}
    else
      {:error, :entity_not_existed} ->
        message = "Account not existed"
        {:failed, :success_false_with_reason, message}
    end
  end
end
