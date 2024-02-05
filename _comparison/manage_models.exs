defmodule Comparison.Models do
  @moduledoc """
  Manages loading the modules when benchmarking models.
  It is inspired by the `App.Models` module in the Phoenix app.
  """
  require Logger

  @doc """
  Verifies and downloads the model according.
  You can optionally force it to re-download the model by passing `force_download?`
  """
  def verify_and_download_model(model, force_download? \\ false) do
    case force_download? do
      true ->
        # Delete any cached pre-existing model
        File.rm_rf!(model.cache_path)
        # Download model
        download_model(model)

      false ->
        # Check if the model cache directory exists or if it's not empty.
        # If so, we download the model.
        model_location = Path.join(model.cache_path, "huggingface")

        if not File.exists?(model_location) or File.ls!(model_location) == [] do
          download_model(model)
        end
    end
  end

  @doc """
  Serving function that serves the `Bumblebee` models used throughout the app.
  This function is meant to be called and served by `Nx`,
  like `Nx.Serving.run(serving, "The capital of [MASK] is Paris.")`

  This assumes the models that are being used exist locally.
  """
  def serving(model) do
    model = load_offline_model_params(model)

    Bumblebee.Vision.image_to_text(
      model.model_info,
      model.featurizer,
      model.tokenizer,
      model.generation_config,
      compile: [batch_size: 10],
      defn_options: [compiler: EXLA],
      preallocate_params: true
    )
  end

  # Loads the model from the cache folder.
  # It will load the model and the respective the featurizer, tokenizer and generation config if needed,
  # and return a map with all of these at the end.
  defp load_offline_model_params(model) do
    Logger.info("Loading #{model.name}...")

    # Loading model
    loading_settings = {:hf, model.name, cache_dir: model.cache_path, offline: true}
    {:ok, model_info} = Bumblebee.load_model(loading_settings)

    info = %{model_info: model_info}

    # Load featurizer, tokenizer and generation config if needed
    info =
      if(model.load_featurizer) do
        {:ok, featurizer} = Bumblebee.load_featurizer(loading_settings)
        Map.put(info, :featurizer, featurizer)
      else
        info
      end

    info =
      if(model.load_tokenizer) do
        {:ok, tokenizer} = Bumblebee.load_tokenizer(loading_settings)
        Map.put(info, :tokenizer, tokenizer)
      else
        info
      end

    info =
      if(model.load_generation_config) do
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
    if(model.load_featurizer) do
      Bumblebee.load_featurizer(downloading_settings)
    end

    if(model.load_tokenizer) do
      Bumblebee.load_tokenizer(downloading_settings)
    end

    if(model.load_generation_config) do
      Bumblebee.load_generation_config(downloading_settings)
    end
  end
end
