defmodule AppWeb.PageLive do
  use AppWeb, :live_view
  alias Vix.Vips.Image, as: Vimage
  alias Vix.Vips.Operation, as: Vops

  @doc """
  Width of the image to be resized to.
  For better results, this should be the same value of the model's dataset.
  The aspect ratio is maintained.
  """
  @image_width 640
  @upload_dir Application.app_dir(:app, ["priv", "static", "uploads"])

  @impl true
  def mount(_params, _session, socket) do
    File.mkdir_p!(@upload_dir)

    {:ok,
     socket
     |> assign(
       # Related to the file uploaded by the user
       image: %{label: nil, filename: nil},
       #  label: nil,
       running?: false,
       task_ref: nil,
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
  This function is called whenever an image is uploaded by the user.

  It reads the file, processes it and sends it to the model for classification.
  It updates the socket assigns
  """
  def handle_progress(:image_list, entry, socket) when entry.done? do
    File.ls!(@upload_dir) |> Enum.map(&File.rm!(Path.join([@upload_dir, &1])))

    # Consume the entry and get the tensor to feed to classifier
    %{tensor: tensor, upload_task: upload_task, filename: filename} =
      consume_uploaded_entry(socket, entry, fn %{path: path} = _meta ->
        # file_binary = File.read!(path)
        type = entry.client_type

        filename =
          File.read!(path)
          |> App.Utils.short_name(type)

        tmp_path =
          App.Utils.copy_path_into(filename, path)

        upload_task =
          App.Upload.run_task(tmp_path, filename, type)

        # Get image and resize
        {:ok, thumbnail_vimage} =
          Vops.thumbnail(path, @image_width, size: :VIPS_SIZE_DOWN)

        # Pre-process it
        {:ok, tensor} = pre_process_image(thumbnail_vimage)

        # Return it
        {:ok, %{tensor: tensor, upload_task: upload_task, filename: filename}}
      end)

    # Create an async task to classify the image
    i2t_task =
      Task.Supervisor.async(App.TaskSupervisor, fn ->
        Nx.Serving.batched_run(ImageClassifier, tensor)
      end)

    # Encode the image to base64
    # base64 = "data:image/png;base64, " <> Base.encode64(file_binary)
    image = %{filename: filename, label: nil}

    # Update socket assigns to show spinner whilst task is running
    {:noreply,
     assign(socket,
       running?: true,
       i2t_ref: i2t_task.ref,
       #  image_preview_base64: base64,
       upload_ref: upload_task.ref,
       image: image
     )}
  end

  def handle_progress(_, _, socket), do: {:noreply, socket}

  @doc """
  Every time an `async task` is created, this function is called.
  We destructure the output of the task and update the socket assigns.

  This function handles both the image that is uploaded by the user and the example images.
  """
  @impl true
  def handle_info({ref, {:error, {:http_error, 400, msg}}}, %{assigns: assigns} = socket)
      when assigns.upload_task.ref == ref do
    Process.demonitor(ref, [:flush])
    require Logger
    Logger.warning("#{inspect(msg)}")
    {:noreply, put_flash(socket, :error, "Upload error")}
  end

  # return from upload into bucket process
  def handle_info({ref, {:ok, msg}}, %{assigns: assigns} = socket)
      when assigns.upload_ref == ref do
    %{body: %{location: location}} = msg

    Process.demonitor(ref, [:flush])
    {:noreply, update(socket, :image, fn img -> Map.merge(img, %{location: location}) end)}
  end

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
      # return from ML captioning process
      Map.get(assigns, :i2t_ref) == ref ->
        {:noreply,
         socket
         |> update(:running?, fn val -> !val end)
         |> update(:image, fn img -> Map.merge(img, %{label: label}) end)}

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

  def error_to_string(:too_large), do: "Image too large. Upload a smaller image up to 10MB."

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
