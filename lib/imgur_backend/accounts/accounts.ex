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

  def get_accounts(params) do
    term = params["term"]
    page = params["page"] || 1
    limit = params["limit"] || 50
    offset = (page - 1) * limit

    query = from(a in Account)
    count = from(a in query, select: count(a.id)) |> Repo.one()

    accounts =
      from(
        a in query,
        where: ilike(a.user_name, ^"%#{term}%") or ilike(a.email, ^"%#{term}%"),
        offset: ^offset,
        limit: ^limit
      )
      |> Repo.all()

    {:ok, %{count: count, accounts: accounts}}
  end

  def get_update_account_params(params) do
    account = params["account"]
    IO.inspect(account, label: "aaaaa")

    if account["password"] do
      if account["password"] == account["re_password"] do
        account = Map.put(account, "password_hash", Bcrypt.hash_pwd_salt(account["password"]))
        {:ok, Map.put(params, "account", account)}
      else
        {:error, "2 mật khẩu không khớp"}
      end
    else
      {:ok, params}
    end
  end
end
