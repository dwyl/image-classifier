defmodule AppWeb.PageLive do
  use AppWeb, :live_view
  alias Vix.Vips.Image, as: Vimage

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(label: nil, running: false, task_ref: nil)
     |> allow_upload(:image_list,
       accept: ~w(image/*),
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1,
       chunk_size: 2_000,
       max_file_size: 8_000
     )}
  end

  @impl true
  def handle_event("noop", _params, socket) do
    {:noreply, socket}
  end

  def handle_progress(:image_list, entry, socket) do
    if entry.done? do

      # Consume the entry and get the tensor to feed to classifier
      tensor = consume_uploaded_entry(socket, entry, fn %{} = meta ->
        {:ok, vimage} = Vix.Vips.Image.new_from_file(meta.path)
        pre_process_image(vimage)
      end)

      # Create an async task to classify the image
      task = Task.async(fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)

      # Update socket assigns to show spinner whilst task is running
      {:noreply, assign(socket, running: true, task_ref: task.ref)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket) do
    # This is called everytime an Async Task is created.
    # We flush it here.
    Process.demonitor(ref, [:flush])

    # And then destructure the result from the classifier.
    %{predictions: [%{label: label}]} = result

    # Update the socket assigns with result and stopping spinner.
    {:noreply, assign(socket, label: label, running: false)}
  end

  defp pre_process_image(%Vimage{} = image) do

    # If the image has an alpha channel, we flatten the alpha out of the image --------
    {:ok, flattened_image} = case Vix.Vips.Image.has_alpha?(image) do
      true -> Vix.Vips.Operation.flatten(image)
      false -> {:ok, image}
    end

    # Convert the image to sRGB colourspace ----------------
    {:ok, srgb_image} = Vix.Vips.Operation.colourspace(flattened_image, :VIPS_INTERPRETATION_sRGB)

    # Converting image to tensor ----------------

    {:ok, tensor} = Vix.Vips.Image.write_to_tensor(image)

    # We reshape the tensor given a specific format.
    # In this case, we are using {height, width, channels/bands}.
    # If you want to use {width, height, channels/bands},
    # you need format = `[:width, :height, :bands]` and shape = `{y, x, bands}`.
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
