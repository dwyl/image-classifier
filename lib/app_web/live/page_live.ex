defmodule AppWeb.PageLive do
  use AppWeb, :live_view
  require Logger
  alias App.Image
  alias Vix.Vips.Image, as: Vimage

  defmodule ImageInfo do
    @doc """
    General information for the image that is being analysed.
    This information is useful when persisting the image to the database.
    """
    defstruct [:mimetype, :width, :height, :url, :file_binary]
  end

  @doc """
  Width of the image to be resized to.
  For better results, this should be the same value of the model's dataset.
  The aspect ratio is maintained.
  """
  @image_width 640
  @accepted_mime ~w(image/jpeg image/jpg image/png image/webp)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       # Related to the file uploaded by the user
       label: nil,
       running?: false,
       task_ref: nil,
       image_info: nil,
       image_preview_base64: nil,

       # Related to the list of image examples
       example_list_tasks: [],
       example_list: [],
       display_list?: false
     )
     |> allow_upload(:image_list,
       accept: ~w(image/*),
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1,
       chunk_size: 64_000,
       max_file_size: 5_000_000
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
  def handle_event("show_examples", _data, socket) do
    # Only run if the user hasn't uploaded anything
    if(is_nil(socket.assigns.task_ref)) do
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
    else
      {:noreply, socket}
    end
  end

  @doc """
  Double-checks the MIME type of uploaded file to ensure that the file
  is an image and is not corrupted.
  """

  # def check_file(binary, path) do
  #   with {:image_info, {mimetype, width, height, variant}} <-
  #          {:image_info, ExImageInfo.info(binary)},
  #        {:gen_magic, {:ok, %{mime_type: mime}}} <-
  #          {:gen_magic, App.Image.gen_magic_eval(path, @accepted_mime)} do
  #     if mimetype == mime,
  #       do: {:ok, {mimetype, width, height, variant}},
  #       else: {:error, "MIME types do not correspond"}
  #   else
  #     {:image_info, nil} -> {:error, "bad file"}
  #     {:gen_magic, {:error, reason}} -> {:error, reason}
  #   end
  # end

  def magic_check(path) do
    App.Image.gen_magic_eval(path, @accepted_mime)
    |> case do
      {:ok, %{mime_type: mime}} ->
        {:ok, %{mime_type: mime}}

      {:error, msg} ->
        {:error, msg}
    end
  end

  def check_mime(magic_mime, info_mime) do
    if magic_mime == info_mime, do: :ok, else: :error
  end

  @doc """
  This function is called whenever an image is uploaded by the user.

  It reads the file, processes it and sends it to the model for classification.
  It updates the socket assigns
  """
  def handle_progress(:image_list, entry, socket) when entry.done? do
    # We consume the entry only if the entry is done uploading from the image
    # and if consuming the entry was successful.
    with %{tensor: tensor, image_info: image_info} <-
           consume_uploaded_entry(socket, entry, fn %{path: path} ->
             with {:magic, {:ok, %{mime_type: mime}}} <-
                    {:magic, magic_check(path)},
                  file_binary <- File.read!(path),
                  {:image_info, {mimetype, width, height, _variant}} <-
                    {:image_info, ExImageInfo.info(file_binary)},
                  {:check_mime, :ok} <-
                    {:check_mime, check_mime(mime, mimetype)},
                  # Get image and resize
                  {:ok, thumbnail_vimage} <-
                    Vix.Vips.Operation.thumbnail(path, @image_width, size: :VIPS_SIZE_DOWN),
                  # Pre-process it
                  {:ok, tensor} <-
                    pre_process_image(thumbnail_vimage) do
               # Upload image to S3
               Image.upload_image_to_s3(path, mimetype)
               |> case do
                 {:ok, url} ->
                   image_info = %ImageInfo{
                     mimetype: mimetype,
                     width: width,
                     height: height,
                     file_binary: file_binary,
                     url: url
                   }

                   {:ok, %{tensor: tensor, image_info: image_info}}

                 # If S3 upload fails, we return error
                 {:error, reason} ->
                   {:ok, %{error: reason}}
               end
             else
               {:magic, {:error, msg}} -> {:postpone, %{error: msg}}
               {:check_mime, :error} -> {:postpone, %{error: "bad check"}}
               {:image_info, nil} -> {:postpone, %{error: "image_info error"}}
               {:error, reason} -> {:postpone, %{error: reason}}
             end
           end) do
      # If consuming the entry was successful, we spawn a task to classify the image
      # and update the socket assigns
      task =
        Task.Supervisor.async(App.TaskSupervisor, fn ->
          Nx.Serving.batched_run(ImageClassifier, tensor)
        end)

      # Encode the image to base64
      base64 = "data:image/png;base64, " <> Base.encode64(image_info.file_binary)

      {:noreply,
       assign(socket,
         running?: true,
         task_ref: task.ref,
         image_preview_base64: base64,
         image_info: image_info
       )}

      # Otherwise, if there was an error uploading the image, we log the error and show it to the person.
    else
      %{error: reason} ->
        Logger.info("Error uploading image. #{inspect(reason)}")

        {:noreply,
         push_event(socket, "toast", %{message: "Image couldn't be uploaded to S3.\n#{reason}"})}

      _ ->
        {:noreply, socket}
    end
  end

  # intermediate chunk consumption
  def handle_progress(_, _, socket), do: {:noreply, socket}

  @doc """
  Every time an `async task` is created, this function is called.
  We destructure the output of the task and update the socket assigns.

  This function handles both the image that is uploaded by the user and the example images.
  """
  @impl true
  def handle_info({ref, result}, %{assigns: assigns} = socket) do
    # Flush async call
    Process.demonitor(ref, [:flush])

    # You need to change how you destructure the output of the model depending
    # on the model you've chosen for `prod` and `test` envs on `models.ex`.)
    label =
      case Application.get_env(:app, :use_test_models, false) do
        true ->
          App.Models.extract_test_label(result)

        # coveralls-ignore-start
        false ->
          App.Models.extract_prod_label(result)
          # coveralls-ignore-stop
      end

    cond do
      # If the upload task has finished executing, we update the socket assigns.
      Map.get(assigns, :task_ref) == ref ->
        # Insert image to database
        image = %{
          url: assigns.image_info.url,
          width: assigns.image_info.width,
          height: assigns.image_info.height,
          description: label
        }

        Image.insert(image)

        # Update socket assigns
        {:noreply, assign(socket, label: label, running?: false)}

      # If the example task has finished executing, we upload the socket assigns.
      img = Map.get(assigns, :example_list_tasks) |> Enum.find(&(&1.ref == ref)) ->
        # Update the element in the `example_list` enum to turn "predicting?" to `false`
        updated_example_list =
          Map.get(assigns, :example_list)
          |> Enum.map(fn obj ->
            if obj.ref == img.ref do
              obj
              |> Map.put(:url, img.url)
              |> Map.put(:label, label)
              |> Map.put(:predicting?, false)
            else
              obj
            end
          end)

        {:noreply,
         assign(socket,
           example_list: updated_example_list,
           running?: false,
           display_list?: true
         )}
    end
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
           {:vix, Vix.Vips.Operation.thumbnail_buffer(body, @image_width)},
         {:pre_process, {:ok, t_img}} <- {:pre_process, pre_process_image(img_thumb)} do
      # Create an async task to classify the image from unsplash
      Task.Supervisor.async(App.TaskSupervisor, fn ->
        Nx.Serving.batched_run(ImageClassifier, t_img)
      end)
      |> Map.merge(%{url: url})
    else
      {stage, error} -> {stage, error}
    end
  end

  def error_to_string(:too_large), do: "Image too large. Upload a smaller image up to 5MB."

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
