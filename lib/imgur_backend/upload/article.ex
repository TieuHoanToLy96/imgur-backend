defmodule ImgurBackend.Upload.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field(:name, :string, null: false)
    field(:description, :string)

  end
end
