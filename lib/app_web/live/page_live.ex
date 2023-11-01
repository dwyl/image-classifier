defmodule AppWeb.PageLive do
  use AppWeb, :live_view
  import Mogrify

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
       chunk_size: 64_000
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove-selected", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image_list, ref)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    {:noreply, socket}
  end

  def handle_progress(:image_list, entry, socket) do
    if entry.done? do
      socket
      |> consume_uploaded_entry(entry, fn %{} = meta ->
        # Resizes the image in-line
        # open(meta.path) |> resize("224x224") |> save(in_place: true)
        {:ok, vimage} = Vix.Vips.Image.new_from_file(meta.path)

        {:ok, flattened} = flatten(vimage)
        {:ok, srgb} = to_colorspace(flattened, :VIPS_INTERPRETATION_sRGB)
        {:ok, tensor} = to_nx(srgb, shape: :hwc)
      end)
      |> case do
        tensor ->
          task = Task.async(fn -> Nx.Serving.batched_run(ImageClassifier, tensor) end)

          {:noreply, assign(socket, running: true, task_ref: task.ref)}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  defp flatten(image) do
    if Vix.Vips.Image.has_alpha?(image) do
      Vix.Vips.Operation.flatten(image)
    else
      {:ok, image}
    end
  end

  defp to_colorspace(image, colorspace) do
    Vix.Vips.Operation.colourspace(image, colorspace)
  end

  def to_nx(image, options \\ []) do
    {to_shape, options} = Keyword.pop(options, :shape, @default_shape)

    with {:ok, tensor} <- Vix.Vips.Image.write_to_tensor(image),
         {:ok, shape, names} <- maybe_reshape_tensor(tensor, to_shape) do
      %Vix.Tensor{data: binary, type: type} = tensor

      binary
      |> Nx.from_binary(type, options)
      |> Nx.reshape(shape, names: names)
      |> wrap(:ok)
    end
  end

  # write_to_tensor writes in height, widght, bands format. No reshape
  # is required.
  defp maybe_reshape_tensor(%Vix.Tensor{shape: shape}, :hwc),
    do: {:ok, shape, [:height, :width, :bands]}

  defp maybe_reshape_tensor(%Vix.Tensor{shape: shape}, :hwb),
    do: {:ok, shape, [:height, :width, :bands]}

  defp maybe_reshape_tensor(%Vix.Tensor{} = tensor, :whb),
    do: maybe_reshape_tensor(tensor, :whc)

  # We need to reshape the tensor since the default is
  # :hwc
  defp maybe_reshape_tensor(%Vix.Tensor{shape: {x, y, bands}}, :whc),
    do: {:ok, {y, x, bands}, [:width, :height, :bands]}

  defp maybe_reshape_tensor(_tensor, shape) do
    {:error,
     "Invalid shape. Allowable shapes are :whb, :whc, :hwc and :hwb. Found #{inspect(shape)}"}
  end

  defp wrap(item, atom) do
    {atom, item}
  end

  defp decode_as_tensor(<<height::32-integer, width::32-integer, data::binary>>) do
    data |> Nx.from_binary(:u8) |> Nx.reshape({height, width, 3})
  end

  def handle_info({ref, result}, %{assigns: %{task_ref: ref}} = socket) do
    Process.demonitor(ref, [:flush])
    %{predictions: [%{label: label}]} = result
    {:noreply, assign(socket, label: label, running: false)}
  end
end
