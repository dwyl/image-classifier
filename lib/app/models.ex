defmodule ModelInfo do
  @doc """
  The name of the model. It corresponds to the name of the repository of the model.
  It also has booleans to load each model parameter at will - this is because some models (like BLIP) require featurizer, tokenizations and generation configuration.
  """
  defstruct [:name, :load_featurizer, :load_tokenizer, :load_generation_config]
end

defmodule App.Models do
  @moduledoc """
  Manages loading the modules and their location according to env.
  """
  require Logger

  # Test and prod models information
  @test_model %ModelInfo{name: "microsoft/resnet-50", load_featurizer: true}
  @prod_model %ModelInfo{
    name: "Salesforce/blip-image-captioning-base",
    load_featurizer: true,
    load_tokenizer: true,
    load_generation_config: true
  }

  # IMPORTANT: This should be the same directory as defined in the `Dockerfile`.
  @models_folder_path Path.join(
                        System.get_env("BUMBLEBEE_CACHE_DIR") ||
                          Application.compile_env!(:app, :models_cache_dir),
                        "huggingface"
                      )

  @doc """
  Verifies if downloaded models folder is populated or not.
  We clear the folder and re-download the models if:
  - the directory is empty.
  - `force_download` in configs is set to `true`.
  - `use_test_models` in configs is set to `true`.
  """
  def verify_and_download_models() do
    force_models_download = Application.get_env(:app, :force_models_download, false)
    use_test_models = Application.get_env(:app, :use_test_models, false)

    # Re-download the models
    if not File.exists?(@models_folder_path) or File.ls!(@models_folder_path) == [] or
         force_models_download == true or
         use_test_models == true do
      # Delete any pre-existing models
      Logger.info("Deleting models...")
      File.rm_rf!(@models_folder_path)

      case use_test_models do
        true ->
          download_model(@test_model)

        _ ->
          download_model(@prod_model)
      end
    end
  end

  @doc """
  Serving function that serves the `Bumblebee` models used throughout the app.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def serving do
    model = load_offline_models(@prod_model)
    Logger.info("Loading #{@prod_model.name}...")

    Bumblebee.Vision.image_to_text(
      model.model_info,
      model.featurizer,
      model.tokenizer,
      model.generation_config,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA],
      # needed to run on `Fly.io`
      preallocate_params: true
    )
  end

  @doc """
  Serving function for tests only.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def serving_test do
    model = load_offline_models(@test_model)
    Logger.info("Loading #{@test_model.name}...")

    Bumblebee.Vision.image_classification(model.model_info, model.featurizer,
      top_k: 1,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA],
      # needed to run on `Fly.io`
      preallocate_params: true
    )
  end

  # Loads the models from the cache folder.
  # It will load the model and the respective the featurizer, tokenizer and generation config if needed,
  # and return a map with all of these at the end.
  defp load_offline_models(model) do
    # Loading model
    {:ok, model_info} = Bumblebee.load_model({:hf, model.name, offline: true})

    info = %{model_info: model_info}

    # Load featurizer, tokenizer and generation config if needed
    info =
      if(model.load_featurizer) do
        {:ok, featurizer} = Bumblebee.load_featurizer({:hf, model.name, offline: true})
        Map.put(info, :featurizer, featurizer)
      else
        info
      end

    info =
      if(model.load_tokenizer) do
        {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model.name, offline: true})
        Map.put(info, :tokenizer, tokenizer)
      else
        info
      end

    info =
      if(model.load_generation_config) do
        {:ok, generation_config} =
          Bumblebee.load_generation_config({:hf, model.name, offline: true})

        Map.put(info, :generation_config, generation_config)
      else
        info
      end

    # Return a map with the model and respective parameters.
    info
  end

  # Downloads the models according to a given %ModelInfo struct.
  # It will load the model and the respective the featurizer, tokenizer and generation config if needed.
  defp download_model(model) do
    # Download the models according to env
    Logger.info("Downloading #{model.name}...")

    # Loading model
    Bumblebee.load_model({:hf, model.name})

    # Load featurizer, tokenizer and generation config if needed
    if(model.load_featurizer) do
      Bumblebee.load_featurizer({:hf, model.name})
    end

    if(model.load_tokenizer) do
      Bumblebee.load_tokenizer({:hf, model.name})
    end

    if(model.load_generation_config) do
      Bumblebee.load_generation_config({:hf, model.name})
    end
  end
end
