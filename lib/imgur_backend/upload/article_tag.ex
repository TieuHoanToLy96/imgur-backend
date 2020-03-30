defmodule ImgurBackend.Upload.ArticleTag do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.Article
  alias ImgurBackend.Upload.ArticleTag
  alias ImgurBackend.Upload.Tag

  schema "articles_tags" do
    field(:is_deleted, :boolean, default: false)

    belongs_to(:article, Article, primary_key: :article_id, type: :binary_id)
    belongs_to(:tag, Tag, primary_key: :tag_id)

    timestamps()
  end

  def changeset(%ArticleTag{} = article_tag, attrs) do
    article_tag
    |> cast(attrs, [:article_id, :tag_id, :is_deleted])
  end
end
