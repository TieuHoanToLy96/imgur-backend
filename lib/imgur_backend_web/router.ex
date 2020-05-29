defmodule ImgurBackendWeb.Router do
  use ImgurBackendWeb, :router

  alias ImgurBackendWeb.Plug.RequireAccount

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :app do
    plug(RequireAccount)
  end

  scope "/api", ImgurBackendWeb.V1 do
    pipe_through(:api)

    scope "/v1" do
      get("/search", SearchController, :search)
      get("/all_articles", ArticleController, :get_all)
      get("/all_story", ArticleController, :get_all_story)

      scope("/statistic") do
      end

      scope "/account" do
        get("/get_user", AccountController, :get_user)
        post("/update", AccountController, :update)
        post("/create", AccountController, :create)
        post("/sign_in", AccountController, :sign_in)
        post("/me", AccountController, :auth_account)
      end

      scope "/files" do
        post("/upload", FileController, :upload_file)
      end

      scope "/article" do
        pipe_through(:app)
        get("/show", ArticleController, :show)
        get("/search", ArticleController, :index)

        post("/create_or_update", ArticleController, :create_or_update)
      end

      scope "/comment" do
        pipe_through(:app)
        get("/list", ArticleController, :get_comments)
        post("/create_or_update", ArticleController, :create_or_update_comment)
        post("/reaction", ArticleController, :update_reaction_comment)
      end

      scope "/reaction" do
        pipe_through(:app)
        post("/create_or_update", ArticleController, :create_or_update_reaction)
      end
    end
  end
end
