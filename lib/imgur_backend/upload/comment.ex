defmodule ImgurBackend.Upload.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.Comment
  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Upload.Article

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "comments" do
    field(:content, :string)
    field(:images, {:array, :string}, default: [])
    field(:is_deleted, :boolean, default: false)

    belongs_to(:article, Article, foreign_key: :article_id)
    belongs_to(:account, Account, foreign_key: :account_id)
    belongs_to(:parent_comment, Comment, foreign_key: :parent_id)
    has_many(:child_comments, Comment, foreign_key: :parent_id)
  end

  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:content, :images, :is_deleted, :account_id, :parent_id, :article_id])
    |> validate_required([:article_id, :account_id])
  end
end
