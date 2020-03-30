defmodule ImgurBackendWeb.V1.FileController do
  use ImgurBackendWeb, :controller
  alias ImgurBackend.App.Tools

  action_fallback(ImgurBackendWeb.FallbackController)
  # file_size < 15Mb
  @max_file_size 15_728_640
  def upload_file(_conn, %{"url" => url} = _params) do
    case HTTPoison.get(url) do
      {:ok, res} ->
        file_binary = res.body
        content_type = for({"Content-Type", value} <- res.headers, do: value) |> List.first()

        file_size =
          for({"Content-Length", value} <- res.headers, do: value)
          |> List.first()
          |> Tools.to_int()

        [ext | filename] = Path.basename(url) |> String.split(".") |> Enum.reverse()
        filename = Enum.reverse(filename) |> Enum.join(".")

        base_storage =
          if System.get_env("MIX_ENV") != "prod",
            do: "http://imgur_storage:4000",
            else: "https://storage.tieuhoan.dev"

        url_upload = "#{base_storage}/api/v1/upload"
        file_size = Tools.to_int(file_size)

        if file_size <= @max_file_size do
          HTTPoison.post(url_upload, file_binary, [
            {"Content-Type", content_type},
            {"X-Content-Name", filename},
            {"X-Content-Extension", ext}
          ])
          |> case do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
              body = Jason.decode!(body)
              {:success, :with_data, body["data"], "Upload file success"}

            _ ->
              {:failed, :success_false_with_reason, "Upload file failed"}
          end
        else
          {:failed, :success_false_with_reason, "File upload over 15Mb"}
        end

      _ ->
        {:error, "Tải file thất bại"}
    end
  end

  def upload_file(conn, params) do
    IO.inspect(params, label: "aaaa")
    file = params["file"]
    file_type = file.content_type
    file_extension = String.split(file.filename, ".") |> List.last()
    file_name = (String.split(file.filename, ".") -- [file_extension]) |> Enum.join(".")

    %{"content-length" => file_size} =
      Enum.reduce(conn.req_headers, %{}, fn {k, v}, acc -> Map.put(acc, k, v) end)

    base_storage =
      if System.get_env("MIX_ENV") != "prod",
        do: "http://imgur_storage:4000",
        else: "https://storage.tieuhoan.dev"

    # base_storage = "https://storage.tieuhoan.dev"
    url_upload = "#{base_storage}/api/v1/upload"
    file_size = Tools.to_int(file_size)
    IO.inspect(url_upload, label: "storageeeee")

    if file_size <= @max_file_size do
      case File.read(file.path) do
        {:ok, file_binary} ->
          HTTPoison.post(url_upload, file_binary, [
            {"Content-Type", file_type},
            {"X-Content-Name", file_name},
            {"X-Content-Extension", file_extension}
          ])
          |> IO.inspect(label: "resssss")
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
