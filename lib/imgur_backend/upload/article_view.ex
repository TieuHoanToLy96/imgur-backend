defmodule ImgurBackend.Upload.ArticleView do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.Article
  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Upload.ArticleView

  schema "article_views" do
    belongs_to(:article, Article, foreign_key: :article_id)
    belongs_to(:account, Article, foreign_key: :account_id)

    timestamps()
  end

  def changeset(%ArticleView{} = article_view, attrs) do
    article_view
    |> cast(attrs, [:article_id, :account_id])
    |> validate_required([:article_id, :account_id])
  end
end
