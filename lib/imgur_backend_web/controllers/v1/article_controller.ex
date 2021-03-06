defmodule ImgurBackendWeb.V1.ArticleController do
  use ImgurBackendWeb, :controller
  alias Ecto.Multi
  alias ImgurBackendWeb.V1.ArticleView
  alias ImgurBackend.Upload.{ArticleAction, Comment, ArticleReaction}
  alias ImgurBackend.{Repo, Accounts}
  alias ImgurBackend.Accounts.Notification

  action_fallback(ImgurBackendWeb.FallbackController)

  def index(conn, params) do
    current_account_id = if conn.assigns != %{}, do: conn.assigns.account.id
    account_url = params["account_url"]
    opts = []

    opts =
      if params["is_get_favorite"] == "true",
        do: opts ++ [is_get_favorite: true],
        else: opts

    opts =
      if params["is_get_comment"] == "true",
        do: opts ++ [is_get_comment: true],
        else: opts

    with {:ok, account} <- Accounts.get_user_by_url(account_url),
         {:ok, %{count: count, articles: articles}} <-
           ArticleAction.search_articles_user(
             current_account_id,
             params |> Map.put("account_id", account.id),
             opts
           ) do
      articles = ArticleView.render_many("articles.json", articles)

      {:success, :with_data, :data, %{count: count, articles: articles}}
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
    current_account_id = if conn.assigns[:account], do: conn.assigns.account[:id], else: nil
    account_id = params["account_id"]
    article_id = params["article_id"]

    with {:ok, article} <- ArticleAction.get_article(article_id) do
      if current_account_id do
        ArticleAction.update_article_view(current_account_id, article_id)
      end

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
      |> Multi.run(:notification, fn _ ->
        if account_id != params["account_id"] do
          data = %{
            content: "đã bình luận bài viết của bạn",
            url: "/posts/#{params["article_id"]}/edit",
            sender_id: account_id,
            receiver_id: params["account_id"],
            type: 3
          }

          Accounts.send_notification(data)
        else
          {:ok, :pass}
        end
      end)
      |> Multi.run(:count_noti, fn _ ->
        Accounts.count_notifications(params["account_id"])
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        c = result.comment

        with {:ok, comment} <- ArticleAction.get_comment(c.id) do
          comment = Comment.to_json("comment.json", comment)

          notification =
            result.notification
            |> case do
              :pass ->
                nil

              value ->
                Accounts.get_notification(value.id)
                |> case do
                  {:ok, v} ->
                    Notification.to_json("notification.json", v)

                  _ ->
                    nil
                end
            end

          {:success, :with_data, :data,
           %{comment: comment, notification: notification, count_noti: result.count_noti}}
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
        ArticleAction.create_or_update_reaction(
          account_id,
          params |> Map.put("account_id", account_id)
        )
      end)
      |> Multi.run(:notification, fn _ ->
        if account_id != params["account_id"] do
          data = %{
            content: "đã bày tỏ cảm xúc về bài viết của bạn",
            url: "/posts/#{params["article_id"]}/edit",
            sender_id: account_id,
            receiver_id: params["account_id"],
            type: 3
          }

          Accounts.send_notification(data)
        else
          {:ok, :pass}
        end
      end)
      |> Multi.run(:count_noti, fn _ ->
        Accounts.count_notifications(params["account_id"])
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        reaction_count = ArticleAction.get_reaction_count(params["article_id"])
        reaction = ArticleReaction.to_json("reaction.json", result.reaction)

        notification =
          result.notification
          |> case do
            :pass ->
              nil

            value ->
              Accounts.get_notification(value.id)
              |> case do
                {:ok, v} ->
                  Notification.to_json("notification.json", v)

                _ ->
                  nil
              end
          end

        {:success, :with_data, :data,
         %{
           reaction: reaction,
           notification: notification,
           count_noti: result.count_noti,
           reaction_count: reaction_count
         }}

      reason ->
        IO.inspect(reason, label: "create_or_update_reaction ERROR")
        {:failed, :with_reason, "Xảy ra lỗi"}
    end
  end

  def get_comments(_conn, params) do
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

  def get_all(_conn, params) do
    with {:ok, %{count: count, articles: articles}} <-
           ArticleAction.get_articles(params,
             is_preload_content: true,
             is_preload_account: true,
             is_preload_reaction: true,
             is_preload_comment: true
           ) do
      articles = ArticleView.render_many("articles.json", articles)

      {:success, :with_data, :data, %{count: count, articles: articles}}
    end
  end

  def get_all_story(conn, params) do
    with {:ok, %{count: count, articles: list_story}} <-
           ArticleAction.get_articles(params,
             is_preload_account: true,
             is_preload_content: true,
             is_story: true
           ) do
      list_story = ArticleView.render_many("articles.json", list_story)
      {:success, :with_data, :data, %{list_story: list_story}}
    end
  end
end
