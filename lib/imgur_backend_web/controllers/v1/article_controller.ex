defmodule ImgurBackendWeb.V1.ArticleController do
  use ImgurBackendWeb, :controller
  alias Ecto.Multi
  alias ImgurBackendWeb.V1.ArticleView
  alias ImgurBackend.Upload.{ArticleAction, Comment, ArticleReaction}
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

    _resource = ImgurBackend.Guardian.Plug.current_resource(conn) |> IO.inspect(label: "oooooo")

    with {:ok, article} <- ArticleAction.get_article(article_id, account_id) do
      article = ArticleView.render("article.json", article)
      {:success, :with_data, :article, article}
    end
  end

  def create_or_update_comment(conn, params) do
    account_id = conn.assigns.account.id

    multi =
      Multi.new()
      |> Multi.run(:comment, fn _ ->
        ArticleAction.create_or_update_comment(account_id, params)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        c = result.comment

        with {:ok, comment} <- ArticleAction.get_comment(c.id) do
          comment = Comment.to_json("comment.json", comment)
          {:success, :with_data, :comment, comment}
        end

      reason ->
        IO.inspect(reason, label: "create_or_update_comment ERROR")
        {:failed, :with_reason, "Xảy ra lỗi"}
    end
  end

  def create_or_update_reaction(conn, params) do
    account_id = conn.assigns.account.id

    multi =
      Multi.new()
      |> Multi.run(:reaction, fn _ ->
        ArticleAction.create_or_update_reaction(account_id, params)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        reaction = ArticleReaction.to_json("reaction.json", result.reaction)
        {:success, :with_data, :reaction, reaction}

      reason ->
        IO.inspect(reason, label: "create_or_update_reaction ERROR")
        {:failed, :with_reason, "Xảy ra lỗi"}
    end
  end

  def get_comments(conn, params) do
    with {:ok, %{comments: comments, count: count}} <- ArticleAction.get_comments(params) do
      comments = Comment.to_json("comments.json", comments)
      {:success, :with_data, :data, %{comments: comments, count: count}}
    end
  end

  def update_reaction_comment(conn, params) do
    account_id = conn.assigns.account.id

    with {:ok, _} <- ArticleAction.update_reaction_comment(account_id, params) do
    end
  end
end
