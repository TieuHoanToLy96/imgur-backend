defmodule ImgurBackend.Upload.CommentReaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.CommentReaction
  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Upload.Comment

  schema "comment_reactions" do
    field(:type_reaction, :integer, default: 0)
    belongs_to(:comment, Comment, foreign_key: :comment_id)
    belongs_to(:account, Account, foreign_key: :account_id)
    timestamps()
  end

  def changeset(%CommentReaction{} = comment_reaction, attrs) do
    comment_reaction
    |> cast(attrs, [:type_reaction, :account_id, :comment_id])
    |> validate_required([:account_id, :comment_id])
  end
end
