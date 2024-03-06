defmodule AppWeb.PageLive do
  use AppWeb, :live_view
  require Logger
  alias App.Image
  alias Vix.Vips.Image, as: Vimage
  alias Vix.Vips.Operation, as: Vops

  defmodule ImageInfo do
    @doc """
    General information for the image that is being analysed.
    This information is useful when persisting the image to the database.
    """
    defstruct [:mimetype, :width, :height, :url, :file_binary, :description, :sha1]
  end

  @doc """
  Width of the image to be resized to.
  For better results, this should be the same value of the model's dataset.
  The aspect ratio is maintained.
  """
  @image_width 640

  @accepted_mime ~w(image/jpeg image/jpg image/png image/webp)
  @tmp_wav Path.expand("priv/static/uploads/tmp.wav")

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       # Related to the file uploaded by the user
       label: nil,
       upload_running?: false,
       task_ref: nil,
       image_info: nil,
       image_preview_base64: nil,

       # Related to the list of image examples
       example_list_tasks: [],
       example_list: [],
       display_list?: false,

       # Related to the audio from the user
       transcription: nil,
       mic_off?: false,
       audio_running?: false,
       audio_search_result: nil,
       tmp_wav: @tmp_wav
     )
     |> allow_upload(:image_list,
       accept: ~w(image/*),
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1,
       chunk_size: 64_000,
       max_file_size: 5_000_000
     )
     |> allow_upload(:speech,
       accept: :any,
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1
     )}
  end

  @impl true
  def handle_event("noop", _params, socket) do
    {:noreply, socket}
  end

  @doc """
  This function retrieves a random image from Unsplash API through a URL like "https://source.unsplash.com/random/640x640"
  and creates async tasks to classify it.

  Should be invoked after some seconds when LiveView is mounted.
  """
  def handle_event("show_examples", _data, %{assigns: assigns} = socket)
      when is_nil(assigns.task_ref) do
    # Only run if the user hasn't uploaded anything
    # Retrieves a random image from Unsplash with a given `image_width` dimension
    random_image = "https://source.unsplash.com/random/#{@image_width}x#{@image_width}"

    # Spawns prediction tasks for example image from random Unsplash image
    tasks =
      for _ <- 1..2 do
        %{url: url, body: body} = track_redirected(random_image)
        predict_example_image(body, url)
      end

    # List to change `example_list` socket assign to show skeleton loading
    display_example_images = Enum.map(tasks, fn obj -> %{predicting?: true, ref: obj.ref} end)

    # Updates the socket assigns
    {:noreply, assign(socket, example_list_tasks: tasks, example_list: display_example_images)}
  end

  @doc """
  Performs magic evaluation to the image MIME type.
  """
  def magic_check(path) do
    App.Image.gen_magic_eval(path, @accepted_mime)
    |> case do
      {:ok, %{mime_type: mime}} ->
        {:ok, %{mime_type: mime}}

      {:error, msg} ->
        {:error, msg}
    end
  end

  @doc """
  Checks if the MIME type of the uploaded file is the same as the
  expected MIME type.
  """
  def check_mime(magic_mime, info_mime) do
    if magic_mime == info_mime, do: :ok, else: :error
  end

  @doc """
  This function is called whenever an image is uploaded by the user.

  It reads the file, processes it and sends it to the model for classification.
  It updates the socket assigns.
  """
  def handle_progress(:image_list, entry, socket) when entry.done? do
    # We consume the entry only if the entry is done uploading from the image
    # and if consuming the entry was successful.
    consume_uploaded_entry(socket, entry, fn %{path: path} ->
      with {:magic, {:ok, %{mime_type: mime}}} <- {:magic, magic_check(path)},
           # Check if file can be properly read
           {:read, {:ok, file_binary}} <- {:read, File.read(path)},
           # Check the image info
           {:image_info, {mimetype, width, height, _variant}} <-
             {:image_info, ExImageInfo.info(file_binary)},
           # Check mime type
           {:check_mime, :ok} <- {:check_mime, check_mime(mime, mimetype)},
           # Get SHA1 code from the image and check it
           sha1 <- App.Image.calc_sha1(file_binary),
           {:sha_check, nil} <- {:sha_check, App.Image.check_sha1(sha1)},
           # Get image and resize
           {:ok, thumbnail_vimage} <- Vops.thumbnail(path, @image_width, size: :VIPS_SIZE_DOWN),
           # Pre-process the image as tensor
           {:pre_process, {:ok, tensor}} <- {:pre_process, pre_process_image(thumbnail_vimage)} do
        # Create image info to be saved as partial image
        image_info = %{
          mimetype: mimetype,
          width: width,
          height: height,
          sha1: sha1,
          description: nil,
          url: nil,
          # set a random big int to the "idx" field
          idx: :rand.uniform(1_000_000_000_000) * 1_000
        }

        # Save partial image
        App.Image.insert(image_info)
        |> case do
          {:ok, _} ->
            image_info =
              Map.merge(image_info, %{
                file_binary: file_binary
              })

            {:ok, %{tensor: tensor, image_info: image_info, path: path}}

          {:error, changeset} ->
            {:error, changeset.errors}
        end
        |> handle_upload()
      else
        {:magic, {:error, msg}} -> {:postpone, %{error: msg}}
        {:read, msg} -> {:postpone, %{error: inspect(msg)}}
        {:image_info, nil} -> {:postpone, %{error: "image_info error"}}
        {:check_mime, :error} -> {:postpone, %{error: "Bad mime type"}}
        {:sha_check, {:ok, %App.Image{}}} -> {:postpone, %{error: "Image already uploaded"}}
        {:pre_process, {:error, _msg}} -> {:postpone, %{error: "pre_processing error"}}
        {:error, reason} -> {:postpone, %{error: inspect(reason)}}
      end
    end)
    |> case do
      # If consuming the entry was successful, we spawn a task to classify the image
      # and update the socket assigns
      %{tensor: tensor, image_info: image_info} ->
        task =
          Task.Supervisor.async(App.TaskSupervisor, fn ->
            Nx.Serving.batched_run(ImageClassifier, tensor)
          end)

        # Encode the image to base64
        base64 = "data:image/png;base64, " <> Base.encode64(image_info.file_binary)

        {:noreply,
         assign(socket,
           upload_running?: true,
           task_ref: task.ref,
           image_preview_base64: base64,
           image_info: image_info
         )}

      # Otherwise, if there was an error uploading the image, we log the error and show it to the person.
      %{error: error} ->
        Logger.warning("⚠️ Error uploading image. #{inspect(error)}")
        {:noreply, push_event(socket, "toast", %{message: "Image couldn't be uploaded to S3.\n#{error}"})}
      end
  end

  # This function is called whenever a user records their voice.
  #
  # It saves the file to disk and sends it to the model to be transcribed.
  # It updates the socket assigns.
  def handle_progress(:speech, entry, %{assigns: assigns} = socket) when entry.done? do
    # We consume the audio file
    tmp_wav =
      socket
      |> consume_uploaded_entry(entry, fn %{path: path} ->
        tmp_wav = assigns.tmp_wav <> Ecto.UUID.generate() <> ".wav"
        :ok = File.cp!(path, tmp_wav)
        {:ok, tmp_wav}
      end)

    # After consuming the audio file, we spawn a task to transcribe the audio
    audio_task =
      Task.Supervisor.async(
        App.TaskSupervisor,
        fn ->
          Nx.Serving.batched_run(Whisper, {:file, tmp_wav})
        end
      )

    # Update the socket assigns
    {:noreply,
     assign(socket,
       audio_ref: audio_task.ref,
       mic_off?: true,
       tmp_wav: tmp_wav,
       audio_running?: true,
       audio_search_result: nil,
       transcription: nil
     )}
  end

  # Intermediate chunk consumption
  def handle_progress(_, _, socket), do: {:noreply, socket}

  @doc """
  Called in `handle_progress` to handle the upload to the bucket and returns the format `{:ok, map}` or {:postpone, message}`
  as demanded by the signature of callback function used `consume_uploaded_entry`
  """
  def handle_upload({:ok, %{path: path, tensor: tensor, image_info: image_info} = map})
      when is_map(map) do
    # Upload the image to S3
    Image.upload_image_to_s3(path, image_info.mimetype)
    |> case do
      # If the upload is successful, we update the socket assigns with the image info
      {:ok, url} ->
        image_info =
          struct(
            %ImageInfo{},
            Map.merge(image_info, %{url: url})
          )

        {:ok, %{tensor: tensor, image_info: image_info}}

      # If S3 upload fails, we return error
      {:error, reason} ->
        Logger.warning("⚠️ Error uploading image: #{inspect(reason)}")
        {:postpone, %{error: "Bucket error"}}
    end
  end

  def handle_upload({:error, error}) do
    Logger.warning("⚠️ Error creating partial image: #{inspect(error)}")
    {:postpone, %{error: "Error creating partial image"}}
  end

  @doc """
  This function is invoked after the async task for embedding model is completed.
  It retrieves the embedding, normalizes it and knn-searches the embedding in our database.
  """
  @impl true
  def handle_info({ref, %{chunks: [%{text: text}]} = _result}, %{assigns: assigns} = socket)
      when assigns.audio_ref == ref do
    Process.demonitor(ref, [:flush])
    File.rm!(assigns.tmp_wav)

    # Compute an normed embedding (cosine case only) on the text result
    # and returns an App.Image{} as the result of a "knn_search"
    with {:not_empty_index, :ok} <-
           {:not_empty_index, App.KnnIndex.not_empty_index()},
         %{embedding: input_embedding} <-
           Nx.Serving.batched_run(Embedding, text),
         %Nx.Tensor{} = normed_input_embedding <-
           Nx.divide(input_embedding, Nx.LinAlg.norm(input_embedding)),
         %App.Image{} = result <-
           App.KnnIndex.knn_search(normed_input_embedding) do
      {:noreply,
       assign(socket,
         transcription: String.trim(text),
         mic_off?: false,
         audio_running?: false,
         audio_search_result: result,
         audio_ref: nil,
         tmp_wav: @tmp_wav
       )}
    else
      # Stop transcription if no entries in the Index
      {:not_empty_index, :error} ->
        {:noreply,
         socket
         |> push_event("toast", %{message: "No images yet"})
         |> assign(
           mic_off?: false,
           transcription: "!! The image bank is empty. Please upload some !!",
           audio_search_result: nil,
           audio_running?: false,
           audio_ref: nil,
           tmp_wav: @tmp_wav
         )}

      nil ->
        {:noreply,
         assign(socket,
           transcription: String.trim(text),
           mic_off?: false,
           audio_search_result: nil,
           audio_running?: false,
           audio_ref: nil,
           tmp_wav: @tmp_wav
         )}
    end
  end

  # This function is invoked after the async task for captioning models is completed.
  # It flushes the async call and destructures the output of the captioning model.
  def handle_info({ref, result}, %{assigns: assigns} = socket) do
    # Flush async call
    Process.demonitor(ref, [:flush])

    # You need to change how you destructure the output of the model depending
    # on the model you've chosen for `prod` and `test` envs on `models.ex`.)
    label =
      case Application.get_env(:app, :use_test_models, false) do
        true ->
          App.Models.extract_captioning_test_label(result)

        # coveralls-ignore-start
        false ->
          App.Models.extract_captioning_prod_label(result)
          # coveralls-ignore-stop
      end

    %{image_info: image_info} = assigns

    cond do
      # If the upload task has finished executing, we run the embedding model on the image
      Map.get(assigns, :task_ref) == ref ->
        image =
          %{
            url: image_info.url,
            width: image_info.width,
            height: image_info.height,
            description: label,
            sha1: image_info.sha1
          }

        # Create embedding task
        with %{embedding: data} <- Nx.Serving.batched_run(Embedding, label),
             # Compute a normed embedding (cosine case only) on the text result
             normed_data <- Nx.divide(data, Nx.LinAlg.norm(data)),
             # Check the SHA1 of the image
             {:check_used, {:ok, pending_image}} <-
               {:check_used, App.Image.check_sha1(image.sha1)} do
          Ecto.Multi.new()
          # Save updated Image to DB
          |> Ecto.Multi.run(:update_image, fn _, _ ->
            idx = App.KnnIndex.get_count() + 1

            Ecto.Changeset.change(pending_image, %{
              idx: idx,
              description: image.description,
              url: image.url
            })
            |> App.Repo.update()
          end)

          # Save Index file to DB
          |> Ecto.Multi.run(:save_index, fn _, _ ->
            {:ok, _idx} = App.KnnIndex.add_item(normed_data)
            App.KnnIndex.save_index_to_db()
          end)
          |> App.Repo.transaction()
          |> case do
            {:error, :update_image, _changeset, _} ->
              {:noreply,
               socket
               |> push_event("toast", %{message: "Invalid entry"})
               |> assign(
                 upload_running?: false,
                 task_ref: nil,
                 label: nil
               )}

            {:error, :save_index, _, _} ->
              {:noreply,
               socket
               |> push_event("toast", %{message: "Please retry"})
               |> assign(
                 upload_running?: false,
                 task_ref: nil,
                 label: nil
               )}

            {:ok, _} ->
              {:noreply,
               socket
               |> assign(
                 upload_running?: false,
                 task_ref: nil,
                 label: label
               )}
          end
        else
          {:check_used, nil} ->
            {:noreply,
             socket
             |> push_event("toast", %{message: "Race condition"})
             |> assign(
               upload_running?: false,
               task_ref: nil,
               label: nil
             )}

          {:error, msg} ->
            {:noreply,
             socket
             |> push_event("toast", %{message: msg})
             |> assign(
               upload_running?: false,
               task_ref: nil,
               label: nil
             )}
        end

      # If the example task has finished executing, we upload the socket assigns.
      img = Map.get(assigns, :example_list_tasks) |> Enum.find(&(&1.ref == ref)) ->
        # Update the element in the `example_list` enum to turn "predicting?" to `false`
        updated_example_list = update_example_list(assigns, img, label)

        {:noreply,
         assign(socket,
           example_list: updated_example_list,
           upload_running?: false,
           display_list?: true
         )}
    end
  end

  @doc """
  Update the example list assigns after predictions are yielded.
  """
  def update_example_list(assigns, image, label) do
    Map.get(assigns, :example_list)
    |> Enum.map(fn obj ->
      if obj.ref == image.ref do
        obj
        |> Map.put(:url, image.url)
        |> Map.put(:label, label)
        |> Map.put(:predicting?, false)
      else
        obj
      end
    end)
  end

  @doc """
  This function receives a `body` binary of an image
  and pre_processes it and sends it over to the model for classification asynchronously.
  Vix is used to produce an optimized thumbnail of `@image_width` to match the COCO dataset
  used to train the BLIP model.

  Returns the task object with the base64 encoded image to be displayed on the page.
  Returns an error if processing the image fails.
  """
  def predict_example_image(body, url) do
    with {:vix, {:ok, img_thumb}} <-
           {:vix, Vops.thumbnail_buffer(body, @image_width)},
         {:pre_process, {:ok, t_img}} <-
           {:pre_process, pre_process_image(img_thumb)} do
      # Create an async task to classify the image from unsplash
      Task.Supervisor.async(App.TaskSupervisor, fn ->
        Nx.Serving.batched_run(ImageClassifier, t_img)
      end)
      |> Map.merge(%{url: url})
    else
      {_, {:error, msg}} ->
        :ok = Logger.error("⚠️ #{msg}")
    end
  end

  def error_to_string(:too_large), do: "Image too large. Upload a smaller image up to 5MB."

  @doc """
  Helper function to flatten an image.
  """
  def flatten(%Vimage{} = image) do
    case Vimage.has_alpha?(image) do
      true ->
        Vops.flatten(image)

      false ->
        {:ok, image}
    end
  end

  @doc """
  Helper function to conver the image to sRGB colourspace.
  """
  def srgb(%Vimage{} = image) do
    Vops.colourspace(image, :VIPS_INTERPRETATION_sRGB)
    |> case do
      {:ok, %Vimage{} = srgb_image} ->
        {:ok, srgb_image}

      {:error, msg} ->
        {:error, msg}
    end
  end

  @doc """
  Converting the image to tensor.
  """
  def to_tensor(%Vimage{} = image) do
    Vimage.write_to_tensor(image)
    |> case do
      {:ok, %Vix.Tensor{} = tensor} ->
        {:ok, tensor}

      {:error, msg} ->
        {:error, msg}
    end
  end

  @doc """
  Pre-processing a given image.
  """
  def pre_process_image(%Vimage{} = v_img) do
    with {:ok, %Vimage{} = flattened_image} <-
           flatten(v_img),
         {:ok, %Vimage{} = srgb_image} <-
           srgb(flattened_image),
         {:ok, %Vix.Tensor{} = tensor} <-
           to_tensor(srgb_image),
         data when data != nil <- Map.get(tensor, :data) do
      # We reshape the tensor given a specific format.
      # In this case, we are using {height, width, channels/bands}.
      %Vix.Tensor{data: binary, type: type, shape: {x, y, bands}} = tensor
      format = [:height, :width, :bands]
      shape = {x, y, bands}

      final_tensor =
        binary
        |> Nx.from_binary(type)
        |> Nx.reshape(shape, names: format)

      {:ok, %Nx.Tensor{} = final_tensor}
    end
  end

  def pre_process_image({:error, msg}) do
    {:error, msg}
  end

  # Helper function to track the redirected URI from random Unsplash images.
  defp track_redirected(url) do
    # Create request
    req = Req.new(url: url)

    # Add tracking properties to req object
    req =
      req
      |> Req.Request.register_options([:track_redirected])
      |> Req.Request.prepend_response_steps(track_redirected: &track_redirected_uri/1)

    # Make request
    {:ok, response} = Req.request(req)

    # Return the final URI
    %{url: URI.to_string(response.private.final_uri), body: response.body}
  end

  defp track_redirected_uri({request, response}) do
    {request, %{response | private: Map.put(response.private, :final_uri, request.url)}}
  end
end
