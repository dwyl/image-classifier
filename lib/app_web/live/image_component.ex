defmodule AppWeb.ImageComponent do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <section id="image-component">
      <div class="mx-auto max-w-2xl lg">
        <h2 class="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl text-center">
          Caption your image!
        </h2>
        <h3 class="mt-6 text-lg leading-8 text-gray-600">
          Upload your own image (up to 5MB) and perform image captioning with
          <a
            href="https://elixir-lang.org/"
            target="_blank"
            rel="noopener noreferrer"
            class="font-mono font-medium text-sky-500"
          >
            Elixir
          </a>
          !
        </h3>
      </div>
      <div class="border-gray-900/10">
        <!-- File upload section -->
        <div class="col-span-full">
          <div
            class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
            phx-drop-target={@uploads.image_list.ref}
          >
            <div class="text-center">
              <!-- Show image preview -->
              <%= if @image_preview_base64 do %>
                <form id="upload-form" phx-change="noop" phx-submit="noop">
                  <label class="cursor-pointer">
                    <%= if not @upload_running? do %>
                      <.live_file_input upload={@uploads.image_list} class="hidden" />
                    <% end %>
                    <img src={@image_preview_base64} />
                  </label>
                </form>
              <% else %>
                <svg
                  class="mx-auto h-12 w-12 text-gray-300"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
                    clip-rule="evenodd"
                  />
                </svg>
                <div class="mt-4 flex text-sm leading-6 text-gray-600">
                  <label
                    for="file-upload"
                    class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
                  >
                    <form id="upload-form" phx-change="noop" phx-submit="noop">
                      <label class="cursor-pointer">
                        <.live_file_input upload={@uploads.image_list} class="hidden" /> Upload
                      </label>
                    </form>
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs leading-5 text-gray-600">PNG, JPG, GIF up to 5MB</p>
              <% end %>
            </div>
          </div>
        </div>
        <!-- Show errors -->
        <%= for entry <- @uploads.image_list.entries do %>
          <div class="mt-2">
            <%= for err <- Phoenix.Component.upload_errors(@uploads.image_list, entry) do %>
              <div class="rounded-md bg-red-50 p-4 mb-2">
                <div class="flex">
                  <div class="flex-shrink-0">
                    <svg
                      class="h-5 w-5 text-red-400"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                  <div class="ml-3">
                    <h3 class="text-sm font-medium text-red-800">
                      <%= AppWeb.PageLive.error_to_string(err) %>
                    </h3>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
        <!-- Prediction text -->
        <div class="flex mt-2 space-x-1.5 items-center font-bold text-gray-900 text-xl">
          <span>Description: </span>
          <!-- conditional Spinner or display caption text or waiting text-->
          <AppWeb.Spinner.spin spin={@upload_running?} />
          <%= if @label do %>
            <span class="text-gray-700 font-light"><%= @label %></span>
          <% else %>
            <span class="text-gray-300 font-light">Waiting for image input.</span>
          <% end %>
        </div>
      </div>
    </section>
    """
  end
end
