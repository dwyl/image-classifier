defmodule App.Image do
  use Ecto.Schema
  alias App.{Image, Repo}

  @primary_key {:id, :id, autogenerate: true}
  schema "images" do
    field(:description, :string)
    field(:width, :integer)
    field(:url, :string)
    field(:height, :integer)

    timestamps(type: :utc_datetime)
  end

  def changeset(image, params \\ %{}) do
    image
    |> Ecto.Changeset.cast(params, [:url, :description, :width, :height])
    |> Ecto.Changeset.validate_required([:url, :description, :width, :height])
  end

  @doc """
  Uploads the given image to S3
  and adds the image information to the database.
  """
  def insert(image) do
    %Image{}
    |> changeset(image)
    |> Repo.insert!()
  end

  @doc """
  Uploads the given image to S3.
  Returns {:ok, response} if the upload is successful.
  Returns {:error, reason} if the upload fails.
  """
  def upload_image_to_s3(file_path, mimetype) do
    extension = MIME.extensions(mimetype) |> Enum.at(0)

    # Upload to Imgup - https://github.com/dwyl/imgup
    upload_response =
      HTTPoison.post(
        "https://imgup.fly.dev/api/images",
        {:multipart,
         [
           {
             :file,
             file_path,
             {"form-data", [name: "image", filename: "#{Path.basename(file_path)}.#{extension}"]},
             [{"Content-Type", mimetype}]
           }
         ]},
        []
      )

    # Process the response and return error if there was a problem uploading the image
    case upload_response do
      # In case it's successful
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"url" => url, "compressed_url" => _} = Jason.decode!(body)
        {:ok, url}

      # In case it returns HTTP 400 with specific reason it failed
      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        %{"errors" => %{"detail" => reason}} = Jason.decode!(body)
        {:error, reason}

      # In case the request fails for whatever other reason
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
