defmodule ImgurBackendWeb.Router do
  use ImgurBackendWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", ImgurBackendWeb.V1 do
    pipe_through(:api)

    scope "/v1" do
      scope "/account" do
        get("/get_user", AccountController, :get_user)
        post("/create", AccountController, :create)
        post("/update", AccountController, :update)
        post("/sign_in", AccountController, :sign_in)
        post("/me", AccountController, :auth_account)
      end

      scope "/files" do
        post("/upload", FileController, :upload_file)
      end

      scope "/article" do
        get("/show", ArticleController, :show)
        get("/search", ArticleController, :index)
        post("/create_or_update", ArticleController, :create_or_update)
      end
    end
  end
end
