defmodule ImgurBackendWeb.Plug.TokenPlug do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    IO.inspect(conn, label: "kkkkkk")
    token = conn.params["token"]

    token =
      try do
        conn
        |> get_req_header("authorization")
        |> List.first()
        |> String.slice((String.length("Bearer") + 1)..-1)
      rescue
        reason ->
          token
      end

    with {:ok, value} <- ImgurBackend.Guardian.decode_and_verify(token),
         {:ok, account} <- ImgurBackend.Accounts.get_account(value["id"]) do
      conn
      |> assign(:account, account)
    else
      reason ->
        conn
    end
  end
end
