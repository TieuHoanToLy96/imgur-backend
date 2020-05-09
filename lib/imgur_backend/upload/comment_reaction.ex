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

  def to_json("reaction.json", reaction) do
    data = Map.take(reaction, [:comment_id, :id, :account_id, :type_reaction])

    data
  end

  def to_json("reactions.json", reactions) do
    Enum.map(reactions, &to_json("reaction.json", &1))
  end
end
