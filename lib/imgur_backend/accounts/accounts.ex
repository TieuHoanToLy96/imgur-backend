defmodule ImgurBackend.Accounts do
  import Ecto.Query, warn: false
  alias ImgurBackend.Repo
  alias ImgurBackend.Accounts.Account

  def get_account_by_id(id) do
    Repo.get(Account, id)
  end

  def get_account(id) do
    case Repo.get(Account, id) do
      nil -> {:error, :entity_not_existed}
      value -> {:ok, value}
    end
  end

  def get_account_by_email(email) do
    query = from(a in Account, where: a.email == ^email)
    Repo.one(query)
  end

  def create_account(params) do
    %Account{}
    |> Account.changeset(params)
    |> Repo.insert()
  end

  def update_account(account, params) do
    account
    |> Account.changeset_update(params)
    |> Repo.update()
  end
end
