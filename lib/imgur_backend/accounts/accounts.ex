defmodule ImgurBackend.Accounts do
  import Ecto.Query, warn: false
  alias ImgurBackend.Repo
  alias ImgurBackend.Accounts.{Account, RelationshipAccount, Notification}
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

  def send_notification(data) do
    Notification.changeset(%Notification{}, data)
    |> Repo.insert()
  end

  def update_notification(data) do
    Repo.get_by(Notification, %{id: data.id})
    |> Notification.changeset(data |> Map.drop([:id]))
    |> Repo.update()
  end

  def get_notifications(account_id, params) do
    limit = params["limit"] || 50
    page = params["page"] || 1
    offset = (page - 1) * limit
    preload_account = from(a in Account)

    noti =
      from(
        n in Notification,
        where: n.receiver_id == ^account_id,
        offset: ^offset,
        limit: ^limit,
        preload: [sender: ^preload_account, receiver: ^preload_account],
        order_by: [desc: n.inserted_at]
      )
      |> Repo.all()

    {:ok, noti}
  end

  def update_friend_request(current_account_id, params, status) do
    data = %{
      account_one_id: current_account_id,
      account_two_id: params["account_id"],
      status: status
    }

    Repo.get_by(RelationshipAccount, %{
      account_one_id: current_account_id,
      account_two_id: params["account_id"]
    })
    |> case do
      nil -> %RelationshipAccount{}
      value -> value
    end
    |> RelationshipAccount.changeset(data)
    |> Repo.insert_or_update()
  end

  def get_friend_request(current_account_id, account_id) do
    if current_account_id do
      ra =
        from(
          ra in RelationshipAccount,
          where:
            ((ra.account_one_id == ^current_account_id and ra.account_two_id == ^account_id) or
               (ra.account_two_id == ^current_account_id and ra.account_one_id == ^account_id)) and
              ra.status != 0,
          order_by: [desc: ra.inserted_at]
        )
        |> Repo.all()
        |> List.first()

      {:ok, ra}
    else
      {:ok, nil}
    end
  end

  def mark_seen_notifications(account_id, params) do
    Repo.get_by(Notification, %{id: params["id"], receiver_id: account_id})
    |> case do
      nil ->
        {:error, :entity_not_existed}

      value ->
        value
        |> Notification.changeset(%{seen: true})
        |> Repo.update()
    end
  end

  def get_notification(id) do
    preload_account = from(a in Account)

    from(
      n in Notification,
      where: n.id == ^id,
      preload: [sender: ^preload_account, receiver: ^preload_account]
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :entity_not_existed}
      value -> {:ok, value}
    end
  end

  def count_notifications(account_id) do
    count =
      from(
        n in Notification,
        where: n.receiver_id == ^account_id and not n.seen,
        select: count(n.id)
      )
      |> Repo.one()

    {:ok, count}
  end

  def search_friend(account_id, params) do
    term = params["term"]

    friends =
      if term do
        from(
          a in Account,
          left_join: ra in RelationshipAccount,
          on: ra.account_one_id == ^account_id or ra.account_two_id == ^account_id,
          where:
            a.id != ^account_id and ra.status == 2 and
              (ilike(a.user_name, ^"%#{term}%") or ilike(a.email, ^"%#{term}%")),
          distinct: a.id
        )
        |> Repo.all()
      else
        []
      end

    {:ok, friends}
  end
end
