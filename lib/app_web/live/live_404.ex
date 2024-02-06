defmodule AppWeb.Live404 do
  use Phoenix.LiveView

  @moduledoc """
  Index integrity error page
  """

  def render(assigns) do
    ~H"""
    <h1>INDEX INTEGRITY ERROR</h1>
    """
  end
end
