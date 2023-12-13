# Install the needed dependencies
Mix.install(
  [
    # Models
    {:bumblebee, "~> 0.4.2"},
    {:exla, "~> 0.6.4"},
    {:nx, "~> 0.6.4 "},
    # Image
    {:vix, "~> 0.25.0"},
  ],
  config: [nx: [default_backend: EXLA.Backend]]
)

# Define the model information struct used for each model being benchmarked.
defmodule ModelInfo do
  @doc """
  Information regarding the model being loaded.
  It holds the name of the model repository and the directory it will be saved into.
  It also has booleans to load each model parameter at will - this is because some models (like BLIP) require featurizer, tokenizations and generation configuration.
  """
  defstruct [:name, :cache_path, :load_featurizer, :load_tokenizer, :load_generation_config]
end


# Benchmark module that when executed, will create a file with the results of the benchmark.
defmodule Benchmark do

  alias Vix.Vips.Image, as: Vimage
  Code.require_file("manage_models.exs")

  @image_width 640

  # Models to be benchmarked -------
  @models_folder_path Path.join(File.cwd!, "models")

  @model %ModelInfo{
    name: "Salesforce/blip-image-captioning-base",
    cache_path: Path.join(@models_folder_path, "blip-image-captioning-base"),
    load_featurizer: true,
    load_tokenizer: true,
    load_generation_config: true
  }
  def extract_label(result) do %{results: [%{text: label}]} = result; label end


  # Run this to create a file to benchmark the models
  def main() do

    # We first verify if the model exists and we download accordingly
    Comparison.Models.verify_and_download_model(@model)

    #files = Path.wildcard(Path.join(File.cwd!, "cocodataset"))
    #dbg(files)

    # Retrieve 50 images from COCO dataset

    #{:ok, thumbnail_vimage} =
    #  Vix.Vips.Operation.thumbnail(meta.path, @image_width, size: :VIPS_SIZE_DOWN)
#
    ## Pre-process it
    #{:ok, tensor} = pre_process_image(thumbnail_vimage)

    #images = get_coco_images()

    # Pre-process the images according to the best size

    serving = Comparison.Models.serving(@model)


    # Run the images through the model and get the prediction for each one.
    # We measure the time to predict the image, get the prediction and save the prediction and execution time to file.
    #Enum.each(images, fn image ->
    #  prediction = predict_example_image(image, model)
    #end)

  end

  # Pre-processes a given Vix image so it's suitable for the model to consume.
  defp pre_process_image(%Vimage{} = image) do
    # If the image has an alpha channel, flatten it:
    {:ok, flattened_image} =
      case Vix.Vips.Image.has_alpha?(image) do
        true -> Vix.Vips.Operation.flatten(image)
        false -> {:ok, image}
      end

    # Convert the image to sRGB colourspace ----------------
    {:ok, srgb_image} = Vix.Vips.Operation.colourspace(flattened_image, :VIPS_INTERPRETATION_sRGB)

    # Converting image to tensor ----------------
    {:ok, tensor} = Vix.Vips.Image.write_to_tensor(srgb_image)

    # We reshape the tensor given a specific format.
    # In this case, we are using {height, width, channels/bands}.
    %Vix.Tensor{data: binary, type: type, shape: {x, y, bands}} = tensor
    format = [:height, :width, :bands]
    shape = {x, y, bands}

    final_tensor =
      binary
      |> Nx.from_binary(type)
      |> Nx.reshape(shape, names: format)

    {:ok, final_tensor}
  end

end

# Run Benchmark module
Benchmark.main()
