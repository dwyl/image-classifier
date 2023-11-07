defmodule AppWeb.PageLiveTest do
  use AppWeb.ConnCase
  import Phoenix.LiveViewTest
  import AppWeb.UploadSupport


  test "connected mount", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Image Classification"

    {:ok, _view, _html} = live(conn)
  end

  test "uploading a file and getting prediction", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Image Classification"

    # Get file and add it to the form
    file =
      [:code.priv_dir(:app), "static", "images", "phoenix.png"]
      |> Path.join()
      |> build_upload("image/png")

    image = file_input(lv, "#upload-form", :image_list, [file])

    # Should show an uploaded local file
    assert render_upload(image, file.name)

    # Wait for the prediction to end
    AppWeb.SupervisorSupport.wait_for_completion()

    # A prediction should have occurred and the label should be shown ("Waiting for image input." should not be shown)
    refute render(lv) =~ "Waiting for image input."
  end
end
