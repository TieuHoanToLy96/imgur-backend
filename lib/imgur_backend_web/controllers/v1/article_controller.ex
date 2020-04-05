defmodule ImgurBackendWeb.V1.ArticleController do
  use ImgurBackendWeb, :controller
  alias Ecto.Multi
  alias ImgurBackendWeb.V1.ArticleView
  alias ImgurBackend.Upload.ArticleAction
  alias ImgurBackend.Repo

  action_fallback(ImgurBackendWeb.FallbackController)

  def index(_conn, params) do
    with {:ok, articles} <- ArticleAction.search_articles_user(params) do
      articles = ArticleView.render_many("articles.json", articles)

      {:success, :with_data, :articles, articles}
    end
  end

  def create_or_update(_conn, params) do
    account_id = params["account_id"]

    multi =
      Multi.new()
      |> Multi.run(:article, fn _ ->
        ArticleAction.create_or_update_article(account_id, params["article"])
      end)
      |> Multi.run(:contents, fn %{article: article} ->
        ArticleAction.create_article_contents(article.id, params["article"]["contents"])
      end)
      |> Multi.run(:tags, fn _ ->
        ArticleAction.create_tags(params["article"]["tags"] || [])
      end)
      |> Multi.run(:article_tags, fn %{article: article, tags: tags} ->
        ArticleAction.create_article_tags(article.id, tags)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        article =
          ArticleView.render("article_just_loaded.json", result.article)
          |> Map.merge(%{
            tags: params["article"]["tags"],
            contents: params["article"]["contents"]
          })

        {:success, :with_data, :article, article}

      reason ->
        IO.inspect(reason, label: "create_or_update ERROR")
        {:failed, :with_reason, "Update article error"}
    end
  end

  def show(conn, params) do
    account_id = params["account_id"]
    article_id = params["article_id"]
    IO.inspect(conn, label: "llll")

    resource = ImgurBackend.Guardian.Plug.current_resource(conn) |> IO.inspect(label: "oooooo")

    with {:ok, article} <- ArticleAction.get_article(article_id, account_id) do
      article = ArticleView.render("article.json", article)
      {:success, :with_data, :article, article}
    end
  end
end
