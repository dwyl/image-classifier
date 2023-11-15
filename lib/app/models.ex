defmodule App.Models do
  @moduledoc """
  Manages loading the modules and their location according to env.
  """
  require Logger

  # IMPORTANT: This should be the same directory as defined in the `Dockerfile`.
  @models_folder_path Path.join(
                        System.get_env("BUMBLEBEE_CACHE_DIR") || Application.compile_env!(:app, :models_cache_dir),
                        "huggingface"
                      )


  @doc """
  Verifies if downloaded models folder is populated or not.
  If `:force_download` is set to true in `config.ex`, it also downloads the models.

  If it is not populated, downloads the models according to env.
  If it is populated, does nothing.
  """
  def verify_and_download_models() do

    # If `force_models_download` is enabled, we delete the files in the folder.
    force_download = case Application.fetch_env(:app, :force_models_download) do
      {:ok, true} ->
        Logger.info(
          "Deleting models..."
        )
        File.rm_rf!(@models_folder_path)
        true
      _ -> false
    end

    if not File.exists?(@models_folder_path) or File.ls!(@models_folder_path) == [] or force_download == true do
      Logger.info(
        "The downloaded models folder is empty or does not exist. Downloading the models..."
      )

      case Mix.env() do
        :test -> download_models_test()
        _ -> download_models_prod()
      end
    end
  end

  @doc """
  Serving function that serves the `Bumblebee` models used throughout the app.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def serving do
    # BLIP -----
    # {:ok, model_info} = Bumblebee.load_model({:hf, "Salesforce/blip-image-captioning-base"})
    # {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "Salesforce/blip-image-captioning-base"})
    # {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "Salesforce/blip-image-captioning-base"})
    # {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "Salesforce/blip-image-captioning-base"})

    # Bumblebee.Vision.image` _to_text(model_info, featurizer, tokenizer, generation_config,
    #   compile: [batch_size: 10],
    #   defn_options: [compiler: EXLA]
    # )

    # ResNet-50 -----
    {:ok, model_info} = Bumblebee.load_model({:hf, "microsoft/resnet-50", offline: true})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50", offline: true})

    Bumblebee.Vision.image_classification(model_info, featurizer,
      top_k: 1,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA],
      preallocate_params: true        # needed to run on `Fly.io`
    )
  end

  # Downloads the models for the test environment.
  # Downloads `ResNet-50`, which is fairly lightweight.
  defp download_models_test do
    {:ok, _} = Bumblebee.load_model({:hf, "microsoft/resnet-50"})
    {:ok, _} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50"})
  end

  # Downloads the models used in the production environment.
  # They must download the same models that are used in the `serving/0` function for this to work.
  defp download_models_prod do
    # ResNet-50 -----
    {:ok, _} = Bumblebee.load_model({:hf, "microsoft/resnet-50"})
    {:ok, _} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50"})
  end
end
