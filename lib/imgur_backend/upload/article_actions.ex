defmodule ImgurBackend.Upload.ArticleAction do
  import Ecto.Query, warn: false
  alias ImgurBackend.Repo
  alias ImgurBackend.Upload.{Article, Tag, ArticleTag, ArticleContent, ArticleView}

  def create_or_update_article(account_id, params) do
    params = Map.put(params, "account_id", account_id)

    if id = params["id"] do
      Repo.get_by(Article, %{account_id: account_id, id: id, is_deleted: false})
      |> case do
        nil -> %Article{}
        value -> value
      end
    else
      %Article{}
    end
    |> Article.changeset(params)
    |> Repo.insert_or_update()
  end

  def create_tags(tags) do
    old_tags =
      from(
        t in Tag,
        where: t.title in ^tags,
        select: t.title
      )
      |> Repo.all()

    new_tags = tags -- old_tags

    new_tags =
      Enum.map(new_tags, fn el ->
        %{title: el}
      end)

    {success, error} =
      Enum.reduce(new_tags, {[], []}, fn el, acc ->
        {s, e} = acc

        %Tag{}
        |> Tag.changeset(el)
        |> Repo.insert()
        |> case do
          {:ok, value} -> {s ++ [value], e}
          {:error, changeset} -> {s, e ++ [changeset]}
        end
      end)

    if length(error) == 0 do
      {:ok, success}
    else
      {:error, error}
    end
  end

  def create_article_tags(article_id, tags) do
    {success, error} =
      Enum.reduce(tags, {[], []}, fn el, acc ->
        {s, e} = acc

        Repo.get_by(ArticleTag, %{tag_id: el.id, article_id: article_id, is_deleted: false})
        |> case do
          nil -> %ArticleTag{}
          value -> value
        end
        |> ArticleTag.changeset(%{article_id: article_id, tag_id: el.id, is_deleted: false})
        |> Repo.insert_or_update()
        |> case do
          {:ok, value} -> {s ++ [value], e}
          {:error, changeset} -> {s, e ++ [changeset]}
        end
      end)

    if length(error) == 0 do
      {:ok, success}
    else
      {:error, error}
    end
  end

  def create_article_contents(article_id, contents) do
    {success, error} =
      Enum.map(contents, fn el ->
        Map.put(el, "article_id", article_id)
      end)
      |> Enum.reduce({[], []}, fn el, acc ->
        {s, e} = acc

        if id = el["id"] do
          Repo.get_by(
            ArticleContent,
            %{is_deleted: false, id: id, article_id: article_id}
          )
          |> case do
            nil -> %ArticleContent{}
            value -> value
          end
        else
          %ArticleContent{}
        end
        |> ArticleContent.changeset(el)
        |> Repo.insert_or_update()
        |> case do
          {:ok, value} -> {s ++ [value], e}
          {:error, changeset} -> {s, e ++ [changeset]}
        end
      end)

    if length(error) == 0 do
      {:ok, success}
    else
      {:error, error}
    end
  end

  def get_article(article_id, account_id) do
    preload_contents = from(ac in ArticleContent, where: ac.is_deleted == false)
    preload_tags = from(t in Tag)

    preload_article_tags =
      from(at in ArticleTag, where: at.is_deleted == false, preload: [tag: ^preload_tags])

    from(
      a in Article,
      where: a.account_id == ^account_id and a.id == ^article_id and a.is_deleted == false,
      preload: [article_tags: ^preload_article_tags, article_contents: ^preload_contents]
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :entity_not_existed}
      value -> {:ok, value}
    end
  end

  def search_articles_user(params) do
    IO.inspect(params, label: "1111111")
    preload_contents = from(ac in ArticleContent, where: ac.is_deleted == false)
    #     preload_views = from(av in ArticleView, select: sum(av.count))

    condition_where =
      dynamic([a], a.account_id == ^params["account_id"] and a.is_deleted == false)

    condition_where =
      case params["type"] do
        "2" ->
          dynamic([a], ^condition_where and a.is_published == true)

        "3" ->
          dynamic([a], ^condition_where and a.is_published == false)

        _ ->
          condition_where
      end

    query =
      from(
        a in Article,
        where: ^condition_where,
        left_join: av in ArticleView,
        on: av.article_id == a.id,
        preload: [
          article_contents: ^preload_contents
          # article_views: ^preload_views
        ],
        group_by: [av.id, a.id],
        order_by: a.inserted_at,
        select_merge: %{article_views: sum(av.count)}
      )

    {:ok, Repo.all(query)}
    |> IO.inspect(label: "iiiiiii")
  end
end
