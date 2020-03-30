defmodule ImgurBackend.Accounts do
  import Ecto.Query, warn: false
  alias ImgurBackend.Repo
  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Upload.Article

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
    url = String.split(params.email, "@") |> List.first()
    params = Map.merge(params, %{account_url: url})

    %Account{}
    |> Account.changeset(params)
    |> Repo.insert()
  end

  def update_account(account, params) do
    account
    |> Account.changeset_update(params)
    |> Repo.update()
  end

  def get_user_by_url(account_url) do
    Repo.get_by(Account, %{account_url: account_url})
    |> case do
      nil -> {:error, :entity_not_existed}
      account -> {:ok, account}
    end
  end
end
