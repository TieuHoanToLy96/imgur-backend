defmodule ImgurBackendWeb.Router do
  use ImgurBackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ImgurBackendWeb.V1 do
    pipe_through :api
    scope "/v1" do
      scope "/article" do
        get("/all", ArticleController,  :index)
      end
    end
  end
end
