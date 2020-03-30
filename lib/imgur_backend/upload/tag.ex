defmodule ImgurBackend.Upload.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  alias ImgurBackend.Upload.Tag

  schema "tags" do
    field(:title, :string)
    field(:images, {:array, :string}, default: [])
    field(:color, :string)

    timestamps()
  end

  def changeset(%Tag{} = tag, attrs) do
    tag
    |> cast(attrs, [:title, :images, :color])
  end
end
