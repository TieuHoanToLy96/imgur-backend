defmodule ImgurBackend.Upload.ArticleAction do
  import Ecto.Query, warn: false
  alias ImgurBackend.Repo

  alias ImgurBackend.Upload.{
    ArticleReaction,
    Article,
    Tag,
    ArticleTag,
    ArticleContent,
    ArticleView,
    Comment,
    CommentReaction
  }

  alias ImgurBackend.App.Tools
  alias ImgurBackend.Accounts.Account

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

  def get_article(article_id, account_id, current_account_id) do
    preload_contents = from(ac in ArticleContent, where: ac.is_deleted == false)
    preload_tags = from(t in Tag)

    preload_article_tags =
      from(at in ArticleTag, where: at.is_deleted == false, preload: [tag: ^preload_tags])

    preload_reactions = from(ar in ArticleReaction)

    preload_account = from(a in Account)

    from(a in Article,
      where: a.id == ^article_id and a.is_deleted == false,
      preload: [
        article_tags: ^preload_article_tags,
        article_contents: ^preload_contents,
        reactions: ^preload_reactions,
        account: ^preload_account
      ]
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, :entity_not_existed}

      value ->
        reaction_count =
          from(ar in ArticleReaction,
            where: ar.article_id == ^article_id,
            select: %{count: count(ar.type_reaction), type_reaction: ar.type_reaction},
            group_by: [ar.type_reaction, ar.article_id],
            order_by: [asc: ar.type_reaction]
          )
          |> Repo.all()

        value = Map.put(value, :reaction_count, reaction_count)
        {:ok, value}
    end
  end

  def get_articles(params, opts \\ []) do
    term = params["term"]
    page = params["page"] || 1
    limit = params["limit"] || 50
    offset = (page - 1) * limit
    account_id = params["account_id"]
    type = params["type"]
    is_preload_reaction = Keyword.get(opts, :is_preload_reaction)
    is_preload_view = Keyword.get(opts, :is_preload_view)
    is_preload_content = Keyword.get(opts, :is_preload_content)
    is_preload_account = Keyword.get(opts, :is_preload_account)
    is_preload_comment = Keyword.get(opts, :is_preload_comment)
    is_get_favorite = Keyword.get(opts, :is_get_favorite)
    is_story = Keyword.get(opts, :is_story)
    is_get_one = Keyword.get(opts, :is_get_one)
    is_get_comment = Keyword.get(opts, :is_get_comment)

    current_account_id = Keyword.get(opts, :current_account_id)

    preload_contents = from(ac in ArticleContent, where: ac.is_deleted == false)
    preload_account = from(a in Account)
    preload_count_reaction = from(ar in ArticleReaction, select: count(ar.id), group_by: ar.id)
    preload_count_comment = from(c in Comment, select: count(c.id), group_by: c.id)
    preload_count_view = from(av in ArticleView, select: sum(av.count), group_by: av.id)

    condition_where = dynamic([a], not a.is_deleted)

    condition_where =
      if term,
        do: dynamic([a], ^condition_where and ilike(a.title, ^"%#{term}%")),
        else: condition_where

    condition_where =
      if is_story,
        do: dynamic([a], ^condition_where and a.is_story),
        else: condition_where

    condition_where =
      if is_get_one && !is_get_favorite,
        do: dynamic([a], ^condition_where and a.account_id == ^account_id),
        else: condition_where

    condition_where =
      cond do
        type == "public" ->
          dynamic([a], ^condition_where and a.is_published == true)

        type == "private" && current_account_id == account_id ->
          dynamic(
            [a],
            ^condition_where and a.account_id == ^account_id and a.is_published == false
          )

        true ->
          dynamic([a], ^condition_where and a.is_published == true)
      end

    query =
      from(
        a in Article,
        where: ^condition_where
      )

    count =
      from(a in query, select: count(a.id))
      |> Repo.one()

    preload =
      if is_preload_content,
        do: [article_contents: preload_contents],
        else: nil

    preload =
      if is_preload_account,
        do: preload ++ [account: preload_account],
        else: preload

    preload =
      if is_preload_reaction,
        do: preload ++ [count_reactions: preload_count_reaction],
        else: preload

    preload =
      if is_preload_comment,
        do: preload ++ [count_comments: preload_count_comment],
        else: preload

    preload =
      if is_preload_view,
        do: preload ++ [count_views: preload_count_view],
        else: preload

    query =
      if preload do
        from(
          a in query,
          preload: ^preload,
          where: ^condition_where,
          offset: ^offset,
          limit: ^limit,
          order_by: [desc: a.inserted_at]
        )
      else
        from(
          a in query,
          where: ^condition_where,
          offset: ^offset,
          limit: ^limit,
          order_by: [desc: a.inserted_at]
        )
      end

    query =
      if is_get_favorite do
        condition_where = dynamic([a, ar], ^condition_where and ar.account_id == ^account_id)

        from(
          a in Article,
          left_join: ar in ArticleReaction,
          on: a.id == ar.article_id,
          where: ^condition_where,
          preload: ^preload
        )
      else
        query
      end

    query =
      if is_get_comment do
        condition_where = dynamic([a, c], ^condition_where and c.account_id == ^account_id)

        from(
          a in Article,
          left_join: c in Comment,
          on: a.id == c.article_id,
          where: ^condition_where,
          preload: ^preload
        )
      else
        query
      end

    articles = Repo.all(query)

    {:ok, %{count: count, articles: articles}}
  end

  def search_articles_user(current_account_id, params, opts \\ []) do
    opts =
      opts ++
        [
          current_account_id: current_account_id,
          is_preload_reaction: true,
          is_preload_comment: true,
          is_preload_content: true,
          is_preload_account: true,
          is_preload_view: true,
          is_get_one: true
        ]

    get_articles(params, opts)
  end

  def search_articles_user_old(current_account_id, params, opts \\ []) do
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
  end

  def create_or_update_comment(account_id, params) do
    if id = params["id"] do
      Repo.get_by(Comment, %{id: id, is_deleted: false})
      |> case do
        nil -> %Comment{}
        value -> value
      end
    else
      %Comment{}
    end
    |> Comment.changeset(Map.merge(params, %{"account_id" => account_id}))
    |> Repo.insert_or_update()
  end

  def get_comment(id) do
    preload_account = from(a in Account)

    from(
      c in Comment,
      where: c.id == ^id and c.is_deleted == false,
      preload: [account: ^preload_account]
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :entity_not_existed}
      value -> {:ok, value}
    end
  end

  def create_or_update_reaction(account_id, params) do
    Repo.get_by(ArticleReaction, %{
      account_id: account_id,
      article_id: params["article_id"]
    })
    |> case do
      nil -> %ArticleReaction{}
      value -> value
    end
    |> ArticleReaction.changeset(params)
    |> Repo.insert_or_update()
  end

  def get_comments(params) do
    IO.inspect(params, label: "oooo")
    article_id = params["article_id"]
    limit = Tools.to_int(params["limit"] || 100)
    page = Tools.to_int(params["page"] || 1)
    offset = (page - 1) * limit

    preload_account = from(a in Account)

    preload_child_comments =
      from(
        c in Comment,
        where: c.is_deleted == false,
        preload: [account: ^preload_account]
      )

    query =
      from(
        c in Comment,
        where: c.is_deleted == false and c.article_id == ^article_id and is_nil(c.parent_id),
        preload: [
          child_comments: ^preload_child_comments,
          account: ^preload_account
        ]
      )

    comments =
      from(
        c in query,
        offset: ^offset,
        limit: ^limit
      )
      |> Repo.all()

    count =
      from(
        c in Comment,
        where: c.is_deleted == false and c.article_id == ^article_id,
        select: count(c.id)
      )
      |> Repo.all()
      |> List.first()

    if count,
      do: {:ok, %{comments: comments, count: count}},
      else: {:error, :failed}
  end

  def update_reaction_comment(account_id, params) do
    if id = params["id"] do
      Repo.get_by(CommentReaction, %{id: id})
    else
      Repo.get_by(CommentReaction, %{
        comment_id: params["comment_id"],
        account_id: account_id
      })
    end
    |> case do
      nil -> %CommentReaction{}
      value -> value
    end
    |> CommentReaction.changeset(params)
    |> Repo.insert_or_update()
  end

  def update_article_view(account_id, article_id) do
    Repo.get_by(ArticleView, %{account_id: account_id, article_id: article_id})
    |> case do
      nil ->
        %ArticleView{}
        |> ArticleView.changeset(%{account_id: account_id, article_id: article_id, count: 1})
        |> Repo.insert()

      value ->
        value
        |> ArticleView.changeset(%{count: value.count + 1})
        |> Repo.update()
    end
  end
end
