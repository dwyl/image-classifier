defmodule AppWeb.Spinner do
  use Phoenix.Component
  # use AppWeb, :html

  @moduledoc """
  Stateless component to display a spinner.
  Takes a boolean `spin` as assign
  """

  attr :spin, :boolean, default: false

  def spin(assigns) do
    ~H"""
    <div :if={@spin} role="status">
      <div class="relative w-6 h-6 animate-spin rounded-full bg-gradient-to-r from-purple-400 via-blue-500 to-red-400 ">
        <div class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-gray-200 rounded-full border-2 border-white">
        </div>
      </div>
    </div>
    """
  end
end
