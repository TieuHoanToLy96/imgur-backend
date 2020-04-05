defmodule ImgurBackend.Upload.ArticleView do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.Article
  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Upload.ArticleView

  schema "article_views" do
    field(:count, :integer, default: 0)
    belongs_to(:article, Article, foreign_key: :article_id, type: :binary_id)
    belongs_to(:account, Article, foreign_key: :account_id, type: :binary_id)

    timestamps()
  end

  def changeset(%ArticleView{} = article_view, attrs) do
    article_view
    |> cast(attrs, [:article_id, :account_id, :count])
    |> validate_required([:article_id, :account_id])
  end
end
