defmodule AppWeb.Nav do
  use Phoenix.Component
  use AppWeb, :verified_routes
  alias Phoenix.LiveView.JS, as: JS

  attr :active, :any
  # Function
  attr :display, :any
  # Function

  def render(assigns) do
    ~H"""
    <%!-- <nav phx-mount={@display.("#image-component")}> --%>
    <nav phx-mounted={JS.show(%JS{}, to: "#image-component") |> JS.hide(to: "#audio-component")}>
      <.link
        id="img"
        class={@active.("#image-component")}
        phx-click={@display.("#image-component")}
        patch={~p"/"}
      >
        Image
      </.link>
      <.link
        id="aud"
        class={@active.("#audio-component")}
        phx-click={@display.("#audio-component")}
        patch={~p"/?display=audio-component"}
      >
        Audio
      </.link>
    </nav>
    """
  end
end
