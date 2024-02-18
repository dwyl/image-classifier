defmodule ModelInfo do
  @moduledoc """
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

  # Embedding-------
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
    {
      Application.get_env(:app, :force_models_download, false),
      Application.get_env(:app, :use_test_models, false)
    }
    |> case do
      {true, true} ->
        # Delete any cached pre-existing models
        File.rm_rf!(@models_folder_path)

        with {:ok, _} <-
               download_model(@captioning_test_model),
             # Download captioning test model model
             {:ok, _} <-
               download_model(@embedding_model),
             # Download whisper model
             {:ok, _} <-
               download_model(@audio_test_model) do
          :ok
        else
          {:error, msg} -> {:error, msg}
        end

      {true, false} ->
        # Delete any cached pre-existing models
        File.rm_rf!(@models_folder_path)

        with {:ok, _} <-
               download_model(@captioning_prod_model),
             {:ok, _} <-
               download_model(@audio_prod_model),
             {:ok, _} <-
               download_model(@embedding_model) do
          :ok
        else
          {:error, msg} -> {:error, msg}
        end

      {false, false} ->
        # Check if the prod model cache directory exists or if it's not empty.
        # If so, we download the prod models.

        with :ok <-
               check_folder_and_download(@captioning_prod_model),
             :ok <-
               check_folder_and_download(@audio_prod_model),
             :ok <-
               check_folder_and_download(@embedding_model) do
          :ok
        else
          {:error, msg} -> {:error, msg}
        end

      {false, true} ->
        # Check if the test model cache directory exists or if it's not empty.
        # If so, we download the test models.

        with :ok <-
               check_folder_and_download(@captioning_test_model),
             :ok <-
               check_folder_and_download(@audio_test_model) do
          :ok
        else
          {:error, msg} -> {:error, msg}
        end
    end
  end

  @doc """
  Loads the embedding model.
  """
  def embedding() do
    load_offline_model(@embedding_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
            Bumblebee.Text.TextEmbedding.text_embedding(
              model.model_info,
              model.tokenizer,
              defn_options: [compiler: EXLA],
              preallocate_params: true
            )

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  @doc """
  Serving function that serves the `Bumblebee` captioning model used throughout the app.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """

  def caption_serving do
    load_offline_model(@captioning_prod_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
            Bumblebee.Vision.image_to_text(
              model.model_info,
              model.featurizer,
              model.tokenizer,
              model.generation_config,
              compile: [batch_size: 1],
              defn_options: [compiler: EXLA],
              # needed to run on `Fly.io`
              preallocate_params: true
            )

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  @doc """
  Serving function that serves the `Bumblebee` audio transcription model used throughout the app.
  """
  def audio_serving do
    load_offline_model(@audio_prod_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
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

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  @doc """
  Serving function for tests only. It uses a test audio transcription model.
  """
  def audio_serving_test do
    load_offline_model(@audio_test_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
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

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  @doc """
  Serving function for tests only. It uses a test captioning model.
  This function is meant to be called and served by `Nx` in `lib/app/application.ex`.

  This assumes the models that are being used exist locally, in the @models_folder_path.
  """
  def caption_serving_test do
    load_offline_model(@captioning_test_model)
    |> then(fn response ->
      case response do
        {:ok, model} ->
          %Nx.Serving{} =
            Bumblebee.Vision.image_classification(
              model.model_info,
              model.featurizer,
              top_k: 1,
              compile: [batch_size: 10],
              defn_options: [compiler: EXLA],
              # needed to run on `Fly.io`
              preallocate_params: true
            )

        {:error, msg} ->
          {:error, msg}
      end
    end)
  end

  # Loads the models from the cache folder.
  # It will load the model and the respective the featurizer, tokenizer and generation config if needed,
  # and return a map with all of these at the end.
  @spec load_offline_model(map()) ::
          {:ok, map()} | {:error, String.t()}

  defp load_offline_model(model) do
    Logger.info("Loading #{model.name}...")

    # Loading model
    loading_settings = {:hf, model.name, cache_dir: model.cache_path, offline: true}

    Bumblebee.load_model(loading_settings)
    |> case do
      {:ok, model_info} ->
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
        {:ok, info}

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Downloads the pre-trained models according to a given %ModelInfo struct.
  # It will load the model and the respective the featurizer, tokenizer and generation config if needed.
  @spec download_model(map()) :: {:ok, map()} | {:error, binary()}
  defp download_model(model) do
    Logger.info("Downloading #{model.name}...")

    # Download model
    downloading_settings = {:hf, model.name, cache_dir: model.cache_path}

    # Download featurizer, tokenizer and generation config if needed
    Bumblebee.load_model(downloading_settings)
    |> case do
      {:ok, _} ->
        if Map.get(model, :load_featurizer) do
          {:ok, _} = Bumblebee.load_featurizer(downloading_settings)
        end

        if Map.get(model, :load_tokenizer) do
          {:ok, _} = Bumblebee.load_tokenizer(downloading_settings)
        end

        if Map.get(model, :load_generation_config) do
          {:ok, _} = Bumblebee.load_generation_config(downloading_settings)
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Checks if the folder exists and downloads the model if it doesn't.
  def check_folder_and_download(model) do
    :ok = File.mkdir_p!(@models_folder_path)

    model_location =
      Path.join(model.cache_path, "huggingface")

    if File.ls(model_location) == {:error, :enoent} or File.ls(model_location) == {:ok, []} do
      download_model(model)
      |> case do
        {:ok, %Bumblebee.Text.GenerationConfig{}} -> :ok
        {:error, msg} -> {:error, msg}
      end
    else
      Logger.info("No download: #{model.name}")
      :ok
    end
  end
end
