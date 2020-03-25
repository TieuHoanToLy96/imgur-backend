defmodule ImgurBackendWeb.Router do
  use ImgurBackendWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", ImgurBackendWeb.V1 do
    pipe_through(:api)

    scope "/v1" do
      scope "/account" do
        post("/create", AccountController, :create)
        post("/update", AccountController, :update)
        post("/sign_in", AccountController, :sign_in)
        post("/me", AccountController, :auth_account)
      end

      scope "/files" do
        post("/upload", FileController, :upload_file)
      end

      scope "/article" do
        get("/all", ArticleController, :index)
      end
    end
  end
end
