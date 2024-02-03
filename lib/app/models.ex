defmodule ModelInfo do
  @doc """
  Information regarding the model being loaded.
  It holds the name of the model repository and the directory it will be saved into.
  It also has booleans to load each model parameter at will - this is because some models (like BLIP) require featurizer, tokenizations and generation configuration.
  """
  defstruct [:name, :cache_path, :load_featurizer, :load_tokenizer, :load_generation_config]
end

defmodule App.Models do
  @moduledoc """
  Manages loading the modules and their location according to env.
  """
  require Logger

  # IMPORTANT: This should be the same directory as defined in the `Dockerfile`
  # where the models will be downloaded into.
  @models_folder_path Application.compile_env!(:app, :models_cache_dir)

  # Test and prod models information -------

  @embedding_model %ModelInfo{
    name: "sentence-transformers/paraphrase-MiniLM-L6-v2",
    cache_path: Path.join(@models_folder_path, "paraphrase-MiniLM-L6-v2"),
    load_featurizer: false,
    load_tokenizer: true,
    load_generation_config: true
  }
  # Captioning --
  @captioning_test_model %ModelInfo{
    name: "microsoft/resnet-50",
    cache_path: Path.join(@models_folder_path, "resnet-50"),
    load_featurizer: true
  }

  @captioning_prod_model %ModelInfo{
    name: "Salesforce/blip-image-captioning-base",
    cache_path: Path.join(@models_folder_path, "blip-image-captioning-base"),
    load_featurizer: true,
    load_tokenizer: true,
    load_generation_config: true
  }

  # Audio transcription --
  @audio_test_model %ModelInfo{
    name: "openai/whisper-small",
    cache_path: Path.join(@models_folder_path, "whisper-small"),
    load_featurizer: true,
    load_tokenizer: true,
    load_generation_config: true
  }

  @audio_prod_model %ModelInfo{
    name: "openai/whisper-small",
    cache_path: Path.join(@models_folder_path, "whisper-small"),
    load_featurizer: true,
    load_tokenizer: true,
    load_generation_config: true
  }

  def extract_captioning_test_label(result) do
    %{predictions: [%{label: label}]} = result
    label
  end

  def extract_captioning_prod_label(result) do
    %{results: [%{text: label}]} = result
    label
  end

  @doc """
  Verifies and downloads the models according to configuration
  and if they are already cached locally or not.

  The models that are downloaded are hardcoded in this function.
  """
  def verify_and_download_models() do
    force_models_download = Application.get_env(:app, :force_models_download, false)
    use_test_models = Application.get_env(:app, :use_test_models, false)

    case {force_models_download, use_test_models} do
      {true, true} ->
        # Delete any cached pre-existing models
        File.rm_rf!(@models_folder_path)

        # Download captioning test model model
        download_model(@captioning_test_model)
        # Download whisper model
        download_model(@audio_test_model)

      {true, false} ->
        # Delete any cached pre-existing models
        File.rm_rf!(@models_folder_path)

        # download embedding model
        download_model(@embedding_model)

        # Download captioning prod model
        download_model(@captioning_prod_model)
        # Download whisper model
        download_model(@audio_prod_model)

      {false, false} ->
        # Check if the prod model cache directory exists or if it's not empty.
        # If so, we download the prod models.

        # Embedding model
        check_folder_and_download(@embedding_model)
        # Captioning test model
        check_folder_and_download(@captioning_prod_model)

        # Audio capture model
        check_folder_and_download(@audio_prod_model)

      {false, true} ->
        # Check if the test model cache directory exists or if it's not empty.
        # If so, we download the test models.

        # Captioning test model
        check_folder_and_download(@captioning_test_model)

        # Audio capture model
        check_folder_and_download(@audio_test_model)
    end
  end

  def embedding() do
    model = load_offline_model(@embedding_model)

    Bumblebee.Text.TextEmbedding.text_embedding(
      model.model_info,
      model.tokenizer,
      compile: [batch_size: 16, sequence_length: 130],
      defn_options: [compiler: EXLA, lazy_transfers: :never],
      preallocate_params: true
    )
  end

  @doc """
  Serving function that serves the `Bumblebee` captioning model used throughout the app.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def caption_serving do
    model = load_offline_model(@captioning_prod_model)

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
  Serving function that serves the `Bumblebee` audio transcription model used throughout the app.
  """
  def audio_serving do
    model = load_offline_model(@audio_prod_model)

    Bumblebee.Audio.speech_to_text_whisper(
      model.model_info,
      model.featurizer,
      model.tokenizer,
      model.generation_config,
      chunk_num_seconds: 30,
      task: :transcribe,
      defn_options: [compiler: EXLA],
      preallocate_params: true
    )
  end

  @doc """
  Serving function for tests only. It uses a test audio transcription model.
  """
  def audio_serving_test do
    model = load_offline_model(@audio_test_model)

    Bumblebee.Audio.speech_to_text_whisper(
      model.model_info,
      model.featurizer,
      model.tokenizer,
      model.generation_config,
      chunk_num_seconds: 30,
      task: :transcribe,
      defn_options: [compiler: EXLA],
      preallocate_params: true
    )
  end

  @doc """
  Serving function for tests only. It uses a test captioning model.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def caption_serving_test do
    model = load_offline_model(@captioning_test_model)

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
  defp load_offline_model(model) do
    Logger.info("Loading #{model.name}...")

    # Loading model
    loading_settings = {:hf, model.name, cache_dir: model.cache_path, offline: true}
    {:ok, model_info} = Bumblebee.load_model(loading_settings)

    info = %{model_info: model_info}

    # Load featurizer, tokenizer and generation config if needed

    info =
      if Map.get(model, :load_featurizer) do
        {:ok, featurizer} = Bumblebee.load_featurizer(loading_settings)
        Map.put(info, :featurizer, featurizer)
      else
        info
      end

    info =
      if Map.get(model, :load_tokenizer) do
        {:ok, tokenizer} = Bumblebee.load_tokenizer(loading_settings)
        Map.put(info, :tokenizer, tokenizer)
      else
        info
      end

    info =
      if Map.get(model, :load_generation_config) do
        {:ok, generation_config} =
          Bumblebee.load_generation_config(loading_settings)

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
    Logger.info("Downloading #{model.name}...")

    # Download model
    downloading_settings = {:hf, model.name, cache_dir: model.cache_path}
    Bumblebee.load_model(downloading_settings)

    # Download featurizer, tokenizer and generation config if needed
    if Map.get(model, :load_featurizer) do
      Bumblebee.load_featurizer(downloading_settings)
    end

    if Map.get(model, :load_tokenizer) do
      Bumblebee.load_tokenizer(downloading_settings)
    end

    if Map.get(model, :load_generation_config) do
      Bumblebee.load_generation_config(downloading_settings)
    end
  end

  # Checks if the folder exists and downloads the model if it doesn't.
  defp check_folder_and_download(model) do
    model_location = Path.join(model.cache_path, "huggingface")

    if not File.exists?(model_location) or File.ls!(model_location) == [] do
      download_model(model)
    end
  end
end
