defmodule ImgurBackendWeb.V1.SearchController do
  use ImgurBackendWeb, :controller
  alias ImgurBackend.Accounts.Account
  alias ImgurBackend.Upload.ArticleAction
  alias ImgurBackend.Accounts
  alias ImgurBackend.Accounts.Account
  alias ImgurBackendWeb.V1.ArticleView

  action_fallback(ImgurBackendWeb.FallbackController)

  def search(conn, params) do
    with {:ok, %{count: count_article, articles: articles}} <- ArticleAction.get_articles(params),
         {:ok, %{count: count_account, accounts: accounts}} <- Accounts.get_accounts(params) do
      articles = ArticleView.render_many("articles.json", articles)
      accounts = Account.to_json("accounts.json", accounts)

      data =
        %{
          article: %{
            count: count_article,
            posts: articles
          },
          account: %{
            count: count_account,
            accounts: accounts
          }
        }
        |> IO.inspect(label: "iiiiiii")

      {:success, :with_data, :data, data}
    end
  end
end
