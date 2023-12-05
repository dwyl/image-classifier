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
  """
  def upload_image_to_s3(file_path, mimetype) do
    extension = MIME.extensions(mimetype) |> Enum.at(0)

    # Upload to Imgup - https://github.com/dwyl/imgup
    upload_response =
      HTTPoison.post!(
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

    # Return URL
    Jason.decode!(upload_response.body)
  end
end
