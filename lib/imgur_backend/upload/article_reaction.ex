defmodule ImgurBackend.Upload.ArticleReaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.ArticleReaction
  alias ImgurBackend.Upload.Article
  alias ImgurBackend.Accounts.Account

  schema "article_reactions" do
    field(:type_reaction, :integer, default: 0)
    belongs_to(:article, Article, foreign_key: :article_id, type: :binary_id)
    belongs_to(:account, Account, foreign_key: :account_id, type: :binary_id)

    timestamps()
  end

  def changeset(%ArticleReaction{} = article_reaction, attrs) do
    article_reaction
    |> cast(attrs, [:account_id, :article_id, :type_reaction])
  end

  def to_json("reaction.json", reaction) do
    Map.take(reaction, [:id, :type_reaction, :count])
  end

  def to_json("reactions.json", reactions) do
    Enum.map(reactions, &to_json("reaction.json", &1))
  end
end
