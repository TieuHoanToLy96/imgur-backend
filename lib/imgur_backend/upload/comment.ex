defmodule ImgurBackend.Upload.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.Comment
  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Upload.{Article, CommentReaction}
  alias ImgurBackendWeb.V1.AccountView

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "comments" do
    field(:content, :string)
    field(:images, {:array, :string}, default: [])
    field(:is_deleted, :boolean, default: false)

    belongs_to(:article, Article, foreign_key: :article_id, type: :binary_id)
    belongs_to(:account, Account, foreign_key: :account_id, type: :binary_id)
    belongs_to(:parent_comment, Comment, foreign_key: :parent_id, type: :binary_id)
    has_many(:child_comments, Comment, foreign_key: :parent_id)
    has_many(:reactions, CommentReaction, foreign_key: :comment_id)
    timestamps()
  end

  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:content, :images, :is_deleted, :account_id, :parent_id, :article_id])
    |> validate_required([:article_id, :account_id])
  end

  def to_json("comment.json", comment) do
    data = Map.take(comment, [:id, :content, :images, :is_deleted, :parent_id])

    data =
      if Ecto.assoc_loaded?(comment.account) do
        account = AccountView.render("account_just_loaded.json", comment.account)
        Map.put(data, :account, account)
      else
        data
      end

    data =
      if Ecto.assoc_loaded?(comment.child_comments) do
        child_comments = to_json("comments.json", comment.child_comments)
        Map.put(data, :child_comments, child_comments)
      else
        Map.put(data, :child_comments, [])
      end

    data =
      if Ecto.assoc_loaded?(comment.reactions) do
        reactions = CommentReaction.to_json("reactions", comment.reactions)

        Map.put(data, :reactions, reactions)
      else
        data
      end

    data
  end

  def to_json("comments.json", comments) do
    Enum.map(comments, &to_json("comment.json", &1))
  end
end
