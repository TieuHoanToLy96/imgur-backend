defmodule ImgurBackendWeb.V1.ArticleView do
  alias ImgurBackend.Upload.{ArticleContent, Comment, ArticleReaction}

  def render("article_just_loaded.json", article) do
    Map.take(article, [
      :title,
      :description,
      :contents,
      :is_published,
      :type,
      :id,
      :reaction_count
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

    data
  end

  def render_many("articles.json", articles) do
    Enum.map(articles, fn el ->
      render("article.json", el)
    end)
  end
end
