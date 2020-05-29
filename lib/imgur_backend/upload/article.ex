defmodule ImgurBackend.Upload.Article do
  use Ecto.Schema
  import Ecto.Changeset

  alias ImgurBackend.Upload.{
    Article,
    ArticleTag,
    ArticleContent,
    ArticleView,
    Comment,
    ArticleReaction
  }

  alias ImgurBackend.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "articles" do
    field(:title, :string, null: false)
    field(:is_deleted, :boolean, default: false)
    field(:is_published, :boolean, default: false)
    field(:type, :integer, default: 0)
    field(:is_story, :boolean, default: false)

    belongs_to(:account, Account, foreign_key: :account_id, type: :binary_id)
    has_many(:article_tags, ArticleTag, foreign_key: :article_id)
    has_many(:article_contents, ArticleContent, foreign_key: :article_id)
    has_many(:article_views, ArticleView, foreign_key: :article_id)
    has_many(:comments, Comment, foreign_key: :article_id)
    has_many(:reactions, ArticleReaction, foreign_key: :article_id)

    has_many(:count_comments, Comment, foreign_key: :article_id)
    has_many(:count_reactions, ArticleReaction, foreign_key: :article_id)
    timestamps()
  end

  def changeset(%Article{} = article, attrs) do
    article
    |> cast(attrs, [
      :title,
      :is_deleted,
      :is_published,
      :type,
      :account_id,
      :is_story
    ])
    |> validate_required([:title, :account_id])
  end
end
