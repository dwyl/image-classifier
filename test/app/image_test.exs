defmodule AppWeb.ImageTest do
  use AppWeb.ConnCase
  import Mock

  alias App.Image

  test "uploading image to S3 with invalid image, returning error from service" do
    # API returns invalid error
    with_mock HTTPoison,
      post: fn _url, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: "{\"errors\":{\"detail\":\"Uploaded file is not a valid image.\"}}"
         }}
      end do
      file_path =
        [:code.priv_dir(:app), "static", "images", "phoenix.xyz"]
        |> Path.join()

      mimetype = "image/xyz"

      {:error, response} = Image.upload_image_to_s3(file_path, mimetype)

      assert response == "Uploaded file is not a valid image."
    end
  end

  test "uploading image to S3 but the service is down" do
    # API returns time out exception
    with_mock HTTPoison,
      post: fn _url, _, _ ->
        {:error,
         %HTTPoison.Error{
           reason: "Time out."
         }}
      end do
      file_path =
        [:code.priv_dir(:app), "static", "images", "phoenix.xyz"]
        |> Path.join()

      mimetype = "image/xyz"

      {:error, response} = Image.upload_image_to_s3(file_path, mimetype)

      assert response == "Time out."
    end
  end
end
