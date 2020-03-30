defmodule ImgurBackend.Upload.ArticleContent do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.ArticleContent
  alias ImgurBackend.Upload.Article

  schema "article_contents" do
    field(:description, :string)
    field(:image, :string, null: false)
    field(:is_deleted, :boolean, defaul: false)
    field(:type, :integer, defaul: 0)
    belongs_to(:article, Article, primary_key: :article_id, type: :binary_id)
    timestamps()
  end

  def changeset(%ArticleContent{} = article_content, attrs) do
    article_content
    |> cast(attrs, [
      :image,
      :description,
      :is_deleted,
      :type,
      :article_id
    ])
    |> validate_required([:article_id, :image])
  end

  def to_json("article_content.json", content) do
    data = Map.take(content, [:image, :description, :id, :is_deleted])
    data
  end

  def to_json("article_contents.json", contents) do
    Enum.map(contents, &to_json("article_content.json", &1))
  end
end
