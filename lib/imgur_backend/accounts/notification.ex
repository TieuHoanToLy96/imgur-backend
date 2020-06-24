defmodule ImgurBackend.Accounts.Notification do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Accounts.Notification
  alias ImgurBackend.Accounts.Account
  alias ImgurBackendWeb.V1.AccountView

  schema "notifications" do
    field(:content, :string)
    field(:url, :string)
    belongs_to(:sender, Account, foreign_key: :sender_id, type: :binary_id)
    belongs_to(:receiver, Account, foreign_key: :receiver_id, type: :binary_id)
    field(:type, :integer)
    field(:seen, :boolean, default: false)

    timestamps()
  end

  def changeset(%Notification{} = n, attrs \\ %{}) do
    n
    |> cast(
      attrs,
      [:id, :content, :url, :sender_id, :receiver_id, :seen, :type, :updated_at, :inserted_at]
    )
  end

  def to_json("notification.json", n) do
    data = Map.take(n, [:id, :content, :type, :seen, :inserted_at, :updated_at, :url])

    data =
      if Ecto.assoc_loaded?(n.sender) do
        Map.put(data, :sender, AccountView.render("account_just_loaded.json", n.sender))
      else
        data
      end

    data =
      if Ecto.assoc_loaded?(n.receiver) do
        Map.put(data, :receiver, AccountView.render("account_just_loaded.json", n.receiver))
      else
        data
      end

    data
  end

  def to_json("notifications.json", n) do
    Enum.map(n, &to_json("notification.json", &1))
  end
end
