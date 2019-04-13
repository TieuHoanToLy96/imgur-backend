defmodule ImgurBackendWeb.V1.AccountView do
  def render("account_just_loaded.json", account) do
    Map.take(account, [
      :user_name,
      :email,
      :avatar,
      :id
    ])
  end

  def render_many("accounts.json", accounts) do
    Enum.map(accounts, fn el ->
      render("account_just_loaded.json", el)
    end)
  end
end
