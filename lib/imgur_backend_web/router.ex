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
    end
  end
end
