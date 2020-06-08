defmodule ImgurBackend.Guardian do
  use Guardian, otp_app: :imgur_backend

  alias ImgurBackend.Accounts

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    user = Accounts.get_account_by_id(id)

    {:ok, user}
  end
end
