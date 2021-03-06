defmodule ImgurBackend.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Upload.Article

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "accounts" do
    field(:user_name, :string)
    field(:email, :string)
    field(:password_hash, :string)
    field(:is_global_admin, :boolean, default: false)
    field(:avatar, :string)
    field(:account_url, :string, null: false)
    field(:settings, :map)

    has_many(:articles, Article, foreign_key: :account_id)
    timestamps()
  end

  def changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:user_name, :email, :password_hash, :avatar, :account_url, :settings])
    |> validate_required([:user_name, :email, :password_hash, :account_url],
      message: "Không để thiếu username, email hoặc password"
    )
    |> validate_length(:user_name,
      max: 16,
      min: 3,
      message: "Username phải lớn hơn 3 kí tự và nhỏ hơn 16 kí tự"
    )
    |> validate_length(:password_hash,
      min: 6,
      message: "Password phải lớn hơn 6 kí tự"
    )
    |> unique_constraint(:user_name,
      name: :accounts_user_name_index,
      message: "Username đã tồn tại"
    )
    |> unique_constraint(:email,
      name: :accounts_email_index,
      message: "Email đã được đăng kí"
    )
    |> put_password_hash()
  end

  def changeset_update(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:user_name, :email, :avatar])
    |> unique_constraint(:user_name,
      name: :accounts_user_name_index,
      message: "Username đã tồn tại"
    )
    |> unique_constraint(:email,
      name: :accounts_email_index,
      message: "Email đã được đăng kí"
    )
  end

  def put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password_hash: pass}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end

  def check_password(_password_hash, nil), do: {:error, "Password hoặc username không đúng"}

  def check_password(password, user) do
    if Bcrypt.verify_pass(password, user.password_hash),
      do: {:ok, user},
      else: {:error, "Password hoặc username không đúng"}
  end

  def to_json("account.json", account) do
    Map.take(account, [:id, :user_name, :email, :avatar, :account_url])
  end

  def to_json("accounts.json", accounts) do
    Enum.map(accounts, &to_json("account.json", &1))
  end
end
