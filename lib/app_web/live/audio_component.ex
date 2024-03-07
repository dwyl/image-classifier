defmodule AppWeb.AudioComponent do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <section id="audio-component">
      <div class="mx-auto max-w-2xl lg">
        <h2 class="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl text-center">
          Semantic search using an audio
        </h2>
        <br />
        <p>
          Please record a phrase. You can listen to your audio. It will be transcripted automatically into a text that will appear below. The semantic search for matching images will then run automatically and the found image will appear below.
        </p>
        <br />
        <form id="audio-upload-form" phx-change="noop" class="flex flex-col items-center">
          <.live_file_input upload={@uploads.speech} class="hidden" />
          <button
            id="record"
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold p-4 rounded flex"
            type="button"
            phx-hook="Audio"
            disabled={@mic_off?}
          >
            <Heroicons.microphone
              outline
              class="w-6 h-6 text-white font-bold group-active:animate-pulse"
            />
            <span id="text">Record</span>
          </button>
        </form>
        <br />
        <p class="flex flex-col items-center">
          <audio id="audio" controls></audio>
        </p>
        <br />
        <div class="flex mt-2 space-x-1.5 items-center font-bold text-gray-900 text-xl">
          <span>Transcription: </span>
          <AppWeb.Spinner.spin spin={@audio_running?} />
          <%= if @transcription do %>
            <span id="output" class="text-gray-700 font-light"><%= @transcription %></span>
          <% else %>
            <span class="text-gray-300 font-light">Waiting for audio input.</span>
          <% end %>
        </div>
        <br />

        <div :if={@audio_search_result}>
          <div class="border-gray-900/10">
            <div class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10">
              <img src={@audio_search_result.url} alt="found_image" />
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
