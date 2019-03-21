defmodule ImgurBackendWeb.V1.ArticleController do
    use ImgurBackendWeb, :controller

    def index(conn, _params) do
      json(conn, %{success: true})
    end

end
