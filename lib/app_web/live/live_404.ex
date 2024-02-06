defmodule AppWeb.Live404 do
  use AppWeb, :live_view

  @moduledoc """
  Index integrity error page
  """
  def mount(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>INDEX INTEGRITY ERROR</h1>
    """
  end
end
