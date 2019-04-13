defmodule ImgurBackendWeb.V1.AccountController do
  use ImgurBackendWeb, :controller

  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Accounts
  alias ImgurBackendWeb.V1.AccountView
  alias ImgurBackend.App.Tools
  alias ImgurBackend.Guardian

  action_fallback(ImgurBackendWeb.FallbackController)

  def auth_account(conn, %{"accessToken" => token}) do
    if Tools.is_empty?(token) do
      {:failed, :success_false_with_reason, "Bạn chưa có tài khoản"}
    else
      with {:ok, value} <- Guardian.decode_and_verify(token),
           {:ok, account} <- Accounts.get_account(value["id"]) do
        account = AccountView.render("account_just_loaded.json", account)

        {:success, :with_data, account}
      end
    end
  end

  def sign_in(conn, %{"email" => email, "password_hash" => password_hash}) do
    user = Accounts.get_account_by_email(email)

    with {:ok, account} <- Account.check_password(password_hash, user),
         {:ok, token, _} <-
           ImgurBackend.Guardian.encode_and_sign(account, %{
             id: account.id,
             email: account.email,
             user_name: account.user_name,
             avatar: account.avatar
           }) do
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

        case Accounts.create_account(data) do
          {:ok, account} ->
            account = AccountView.render("account_just_loaded.json", account)

            {:success, :with_data, account, "Đăng kí tài khoản thành công"}

          {:error, changeset} ->
            message = Tools.get_error_message_from_changeset(changeset)
            {:failed, :success_false_with_reason, message}
        end
    end
  end
end
