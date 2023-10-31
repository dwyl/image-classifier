defmodule AppWeb.PageLive do
  use AppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(label: nil, running: false, task_ref: nil)
     |> allow_upload(:image,
       accept: ~w(image/*),
       auto_upload: true,
       progress: &handle_progress/3,
       max_entries: 1,
       chunk_size: 64_000
     )}
  end

  @impl true
  def handle_event("noop", %{}, socket) do
    dbg("what")
    {:noreply, socket}
  end

  defp handle_progress(:image, entry, socket) do
    dbg("bru")

    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{} = meta ->
          file_path = meta.path

          # Do something with file path and then consume entry.
          # It will remove the uploaded file from the temporary folder and remove it from the uploaded_files list
          {:ok, entry}
        end)
    end

    {:noreply, socket}
  end
end
