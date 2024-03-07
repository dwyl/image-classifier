defmodule AppWeb.ExamplesComponent do
  use Phoenix.Component
  use AppWeb, :verified_routes

  def render(assigns) do
    ~H"""
    <section>
      <div :if={@display_list?} class="flex flex-col">
        <h3 class="mt-10 text-xl lg:text-center font-light tracking-tight text-gray-900 lg:text-2xl">
          Examples
        </h3>
        <div class="flex flex-row justify-center my-8">
          <div class="mx-auto grid max-w-2xl grid-cols-1 gap-x-6 gap-y-20 sm:grid-cols-2">
            <%= for example_img <- @example_list do %>
              <!-- Loading skeleton if it is predicting -->
              <%= if example_img.predicting? == true do %>
                <div
                  role="status"
                  class="flex items-center justify-center w-full h-full max-w-sm bg-gray-300 rounded-lg animate-pulse"
                >
                  <img src={~p"/images/spinner.svg"} alt="spinner" />
                  <span class="sr-only">Loading...</span>
                </div>
              <% else %>
                <div>
                  <img id={example_img.url} src={example_img.url} class="rounded-2xl object-cover" />
                  <h3 class="mt-1 text-lg leading-8 text-gray-900 text-center">
                    <%= example_img.label %>
                  </h3>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
