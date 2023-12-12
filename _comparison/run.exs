# Install the needed dependencies
Mix.install(
  [
    {:bumblebee, "~> 0.4.2"},
    {:exla, ">= 0.0.0"}
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

  # Import model manager module
  Code.require_file("manage_models.exs")

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

    serving = Comparison.Models.serving(@model)

    # Retrieve 50 images from COCO dataset
    #images = get_coco_images()

    # Pre-process the images according to the best size

    # Run the images through the model and get the prediction for each one.
    # We measure the time to predict the image, get the prediction and save the prediction and execution time to file.
    #Enum.each(images, fn image ->
    #  prediction = predict_example_image(image, model)
    #end)

  end
end

# Run Benchmark module
Benchmark.main()
