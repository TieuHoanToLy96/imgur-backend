defmodule ImgurBackendWeb.Router do
  use ImgurBackendWeb, :router

  alias ImgurBackendWeb.Plug.RequireAccount
  alias ImgurBackendWeb.Plug.TokenPlug

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :app do
    plug(RequireAccount)
  end

  pipeline :token do
    plug(TokenPlug)
  end

  scope "/api", ImgurBackendWeb.V1 do
    pipe_through([:api, :token])

    scope "/v1" do
      get("/search", SearchController, :search)
      get("/all_articles", ArticleController, :get_all)
      get("/all_story", ArticleController, :get_all_story)

      scope "/account" do
        get("/get_user", AccountController, :get_user)
        get("/search_friend", AccountController, :search_friend)
        post("/update", AccountController, :update)
        post("/create", AccountController, :create)
        post("/sign_in", AccountController, :sign_in)

        post("/me", AccountController, :auth_account)

        pipe_through(:app)
        get("/get_notifications", AccountController, :get_notifications)
        post("/send_friend_request", AccountController, :send_friend_request)
        post("/accept_friend_request", AccountController, :accept_friend_request)
        post("/cancel_friend_request", AccountController, :cancel_friend_request)
        post("/seen_notification", AccountController, :mark_seen_notifications)
      end

      scope "/conversations" do
        get("/get_messages", ConversationController, :get_messages)
        get("/get_conversations", ConversationController, :get_conversations)
        post("/create_conversation", ConversationController, :create_conversation)
        post("/send_message", ConversationController, :send_message)
        post("/update_conversations", ConversationController, :update_conversations)
      end

      scope "/files" do
        post("/upload", FileController, :upload_file)
      end

      scope "/article" do
        # pipe_through(:app)
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
