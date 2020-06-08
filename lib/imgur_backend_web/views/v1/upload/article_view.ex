defmodule ImgurBackendWeb.V1.ArticleView do
  alias ImgurBackend.Upload.{ArticleContent, Comment, ArticleReaction}
  alias ImgurBackend.Accounts.Account

  def render("article_just_loaded.json", article) do
    Map.take(article, [
      :title,
      :description,
      :contents,
      :is_published,
      :type,
      :id,
      :reaction_count,
      :is_story,
      :account_id
    ])
  end

  def render("article.json", article) do
    data = render("article_just_loaded.json", article)

    data =
      if Ecto.assoc_loaded?(article.article_tags) do
        tags =
          Enum.map(article.article_tags || [], fn el ->
            if Ecto.assoc_loaded?(el.tag) do
              el.tag.title
            else
              nil
            end
          end)
          |> Enum.filter(& &1)

        Map.put(data, :tags, tags)
      else
        data
      end

    data =
      if Ecto.assoc_loaded?(article.article_contents) do
        contents = ArticleContent.to_json("article_contents.json", article.article_contents)
        Map.put(data, :contents, contents)
      else
        data
      end

    data =
      if Ecto.assoc_loaded?(article.article_views) do
        Map.put(data, :view_count, article.article_views || 0)
      else
        data
      end

    data =
      if Ecto.assoc_loaded?(article.comments) do
        comments = Comment.to_json("comments.json", article.comments)
        Map.put(data, :comments, comments)
      else
        Map.put(data, :comments, [])
      end

    data =
      if Ecto.assoc_loaded?(article.reactions) do
        reactions = ArticleReaction.to_json("reactions.json", article.reactions)
        Map.put(data, :reactions, reactions)
      else
        data
      end

    data =
      if Ecto.assoc_loaded?(article.account) do
        account = Account.to_json("account.json", article.account)
        Map.put(data, :account, account)
      else
        data
      end

    data =
      if Ecto.assoc_loaded?(article.count_reactions) do
        Map.put(data, :count_reactions, article.count_reactions |> length())
      else
        data
      end

    data =
      if Ecto.assoc_loaded?(article.count_comments) do
        Map.put(data, :count_comments, article.count_comments |> length())
      else
        data
      end

    data
  end

  def render_many("articles.json", articles) do
    Enum.map(articles, fn el ->
      render("article.json", el)
    end)
  end
end
