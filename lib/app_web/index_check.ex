defmodule AppWeb.IndexCheck do
  import Phoenix.LiveView
  use AppWeb, :verified_routes

  require Logger

  @moduledoc """
  Checks if the length of the Image table is equal to the index count of the Hnswlib Index file.
  Redirects to 404 page if not.
  """
  def on_mount(:default, _params, _session, socket) do
    App.KnnIndex.check_integrity()
    |> case do
      true ->
        {:cont, socket}

      false ->
        Logger.warning("Index Integrity Error")
        {:halt, push_redirect(socket, to: ~p"/404")}
    end
  end
end
