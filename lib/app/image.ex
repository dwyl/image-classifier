defmodule App.Image do
  use Ecto.Schema
  alias App.{Image, Repo}

  @primary_key {:id, :id, autogenerate: true, source: :rowid}
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

  def upload_image_to_s3(file_path, file_binary) do
    # Get information of the file
    {mimetype, _width, _height, _variant} = ExImageInfo.info(file_binary)
    extension = MIME.extensions(mimetype) |> Enum.at(0)

    # Upload to Imgup
    # https://github.com/dwyl/imgup
    upload_response =
      HTTPoison.post!(
        "https://imgup.fly.dev/api/images",
        {:multipart,
         [
           {
            :file, file_path,
            {"form-data", [name: "image", filename: "#{Path.basename(file_path)}.#{extension}"]},
            [{"Content-Type", mimetype}]
          }
         ]},
        []
      )

    Jason.decode!(upload_response.body)
  end

  def insert(attrs) do
    %Image{}
    |> changeset(attrs)
    |> Repo.insert!()
  end
end
