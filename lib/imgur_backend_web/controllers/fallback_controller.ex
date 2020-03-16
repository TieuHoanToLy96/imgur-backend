defmodule ImgurBackendWeb.FallbackController do
  use ImgurBackendWeb, :controller

  def call(conn, {:success, :with_data, key, data}) when is_bitstring(key) do
    to_send = %{success: true, fallback: "with_data"} |> Map.put(String.to_atom(key), data)

    conn
    |> put_status(:ok)
    |> json(to_send)
  end

  def call(conn, {:success, :with_data, key, data}) when is_atom(key) do
    to_send = %{success: true, fallback: "with_data"} |> Map.put(key, data)

    conn
    |> put_status(:ok)
    |> json(to_send)
  end

  def call(conn, {:success, :with_data, data}) do
    conn
    |> put_status(:ok)
    |> json(%{success: true, data: data})
  end

  def call(conn, {:success, :with_data, data, message}) do
    conn
    |> put_status(:ok)
    |> json(%{success: true, data: data, message: message})
  end

  def call(conn, {:failed, :success_false_with_reason, message}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{success: false, message: message})
  end

  def call(conn, {:error, :entity_not_existed}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      success: false,
      message: "This entity is not existed",
      fallback: "entity_not_existed"
    })
  end
end
