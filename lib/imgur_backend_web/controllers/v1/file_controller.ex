defmodule ImgurBackendWeb.V1.FileController do
  use ImgurBackendWeb, :controller
  alias ImgurBackend.App.Tools

  action_fallback(ImgurBackendWeb.FallbackController)
  # file_size < 15Mb
  @max_file_size 15_728_640
  def upload_file(conn, params) do
    file = params["file"]
    file_type = file.content_type
    file_extension = String.split(file.filename, ".") |> List.last()
    file_name = (String.split(file.filename, ".") -- [file_extension]) |> Enum.join(".")

    %{"content-length" => file_size} =
      Enum.reduce(conn.req_headers, %{}, fn {k, v}, acc -> Map.put(acc, k, v) end)

    base_storage =
      if System.get_env("MIX_ENV") != "prod",
        do: System.get_env("IMGUR_STORAGE_DEV") <> ":4000",
        else: System.get_env("IMGUR_STORAGE_HOST")

    url_upload = "https://#{base_storage}/api/v1/upload"
    file_size = Tools.to_int(file_size)

    if file_size <= @max_file_size do
      case File.read(file.path) do
        {:ok, file_binary} ->
          HTTPoison.post(url_upload, file_binary, [
            {"Content-Type", file_type},
            {"X-Content-Name", file_name},
            {"X-Content-Extension", file_extension}
          ])
          |> case do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
              body = Jason.decode!(body)
              {:success, :with_data, body["data"], "Upload file success"}

            _ ->
              {:failed, :success_false_with_reason, "Upload file failed"}
          end

        {:error, reason} ->
          IO.inspect(reason, label: "ERROR upload_file 1")
          {:error, :entity_not_existed}

        reason ->
          IO.inspect(reason, label: "ERROR upload_file 2")
          {:error, :entity_not_existed}
      end
    else
      {:failed, :success_false_with_reason, "File upload over 15Mb"}
    end
  end
end
