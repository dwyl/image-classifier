defmodule AppWeb.PageLiveTest do
  use AppWeb.ConnCase
  import Phoenix.LiveViewTest
  import AppWeb.UploadSupport
  import Mock

  test "connected mount", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Caption your image!"

    {:ok, _view, _html} = live(conn)
  end

  test "connected and renders hook after period of inactivity", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Caption your image!"

    # Executes `show_examples` event handler
    assert render_hook(lv, "show_examples", %{})

    # Wait for the predictions to end
    AppWeb.SupervisorSupport.wait_for_completion()

    # Should show "Examples" title
    assert render(lv) =~ "Examples"
  end

  test "uploading a file and getting prediction", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Caption your image!"

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

  test "uploading a file without alpha", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Caption your image!"

    # Get file and add it to the form
    file =
      [:code.priv_dir(:app), "static", "images", "phoenix.jpg"]
      |> Path.join()
      |> build_upload("image/jpg")

    image = file_input(lv, "#upload-form", :image_list, [file])

    # Should show an uploaded local file
    assert render_upload(image, file.name)

    # Wait for the prediction to end
    AppWeb.SupervisorSupport.wait_for_completion()

    # A prediction should have occurred and the label should be shown ("Waiting for image input." should not be shown)
    refute render(lv) =~ "Waiting for image input."
  end

  test "uploading an audio file", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Caption your image!"

    # Get file and add it to the form
    file =
      [:code.priv_dir(:app), "static", "audio", "itwillallbeok.mp3"]
      |> Path.join()
      |> build_upload("audio/mp3")

    audio = file_input(lv, "#audio-upload-form", :speech, [file])

    # The transcription should be empty
    assert render(lv) |> Floki.find("#output") |> Floki.text() == ""

    # Should show an uploaded local file
    assert render_upload(audio, file.name)

    # Wait for the audio prediction to end
    AppWeb.SupervisorSupport.wait_for_completion()

    # A prediction should have occurred and the label should be shown with the audio transcription
    assert render(lv) |> Floki.find("#output") |> Floki.text() =~
             "Sometimes, the inner voice is encouraging"
  end

  test "error should be shown if size is bigger than limit", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Caption your image!"

    # Get file and add it to the form
    file =
      [:code.priv_dir(:app), "static", "images", "8mb_image.jpeg"]
      |> Path.join()
      |> build_upload("image/jpeg")

    image = file_input(lv, "#upload-form", :image_list, [file])

    # Should show an uploaded local file
    assert render_upload(image, file.name)

    # Wait for the prediction to end
    AppWeb.SupervisorSupport.wait_for_completion()

    # Should show error
    assert render(lv) =~ "Image too large. Upload a smaller image up to 5MB."
  end

  test "check MIME type", %{conn: _conn} do
    path = [:code.priv_dir(:app), "static", "images", "test.png"] |> Path.join()
    _file = build_upload(path, "image/xyz")

    assert AppWeb.PageLive.magic_check(path) == {:error, "Not acceptable."}

    accepted_mime = ~w(image/jpeg image/jpg image/png image/webp)
    assert App.Image.gen_magic_eval(path, accepted_mime) == {:error, "Not acceptable."}
    assert App.Image.gen_magic_eval("", accepted_mime) == {:error, "invalid command"}
  end

  test "uploading an invalid image", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Caption your image!"

    # Get file and add it to the form
    file =
      [:code.priv_dir(:app), "static", "images", "phoenix.xyz"]
      |> Path.join()
      |> build_upload("image/xyz")

    image = file_input(lv, "#upload-form", :image_list, [file])

    # API returns invalid error
    with_mock HTTPoison,
      post: fn _url, _, _ ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: "{\"errors\":{\"detail\":\"Uploaded file is not a valid image.\"}}"
         }}
      end do
      # Should show an uploaded local file
      assert render_upload(image, file.name)

      # Wait for the prediction to end
      AppWeb.SupervisorSupport.wait_for_completion()

      # No prediction occured.
      assert render(lv) =~ "Waiting for image input."
    end
  end

  test "`imgup` is down, so no prediction occurs", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert html =~ "Caption your image!"

    # Get file and add it to the form
    file =
      [:code.priv_dir(:app), "static", "images", "phoenix.xyz"]
      |> Path.join()
      |> build_upload("image/xyz")

    image = file_input(lv, "#upload-form", :image_list, [file])

    # API returns invalid error
    with_mock HTTPoison,
      post: fn _url, _, _ -> {:error, %HTTPoison.Error{}} end do
      # Should show an uploaded local file
      assert render_upload(image, file.name)

      # Wait for the prediction to end
      AppWeb.SupervisorSupport.wait_for_completion()

      # No prediction occured because API is down.
      assert render(lv) =~ "Waiting for image input."
    end
  end

  test "handle_intermediate_progress", %{conn: _conn} do
    ret = AppWeb.PageLive.handle_progress(:image_list, %{}, %{})
    assert ret == {:noreply, %{}}
  end

  test "noop event handler", %{conn: _conn} do
    ret = AppWeb.PageLive.handle_event("noop", %{}, %{})

    assert ret == {:noreply, %{}}
  end

  test "genserver init" do
    path = set_path("indexes1.bin")
    {:ok, file} = File.read(path)

    # ------------------------------------------------
    # happy path
    Supervisor.stop(App.Supervisor)
    App.Application.start(:normal, [])
    App.Repo.delete_all(App.HnswlibIndex)
    App.Repo.delete_all(App.Image)

    next_lock = 1

    %App.HnswlibIndex{}
    |> App.HnswlibIndex.changeset(%{
      lock_version: next_lock,
      file: file,
      id: 1
    })
    |> App.Repo.insert()

    %{
      description: nil,
      width: 445,
      url: nil,
      idx: 1,
      height: 259,
      sha1: "C3E6725418C904560448D182050AECCD7F1D9E93",
      mimetype: "image/png"
    }
    |> App.Image.insert()

    assert :ok ==
             Supervisor.start_child(App.Supervisor, {App.KnnIndex, [space: :cosine, index: path]})
             |> elem(0)

    assert 1 == App.KnnIndex.get_count()
    # ------------------------------------------------
    # case Index file does not exist on Filesystem but exists in DB => create from DB copy.
    Supervisor.stop(App.Supervisor)
    App.Application.start(:normal, [])
    App.Repo.delete_all(App.HnswlibIndex)
    App.Repo.delete_all(App.Image)

    assert {:error, "Incoherence on table"} ==
             Supervisor.start_child(App.Supervisor, {App.KnnIndex, [space: :cosine, index: path]})
             |> elem(1)
             |> elem(0)

    # ------------------------------------------------
    # db es empty but index file is present
    Supervisor.stop(App.Supervisor)
    App.Application.start(:normal, [])
    App.Repo.delete_all(App.HnswlibIndex)
    App.Repo.delete_all(App.Image)

    path = set_path("indexes2.bin")

    App.HnswlibIndex.changeset(%App.HnswlibIndex{}, %{
      lock_version: next_lock,
      file: nil,
      id: 1
    })
    |> App.Repo.insert()

    assert {:error, "Integrity error"} ==
             Supervisor.start_child(App.Supervisor, {App.KnnIndex, [space: :cosine, index: path]})
             |> elem(1)
             |> elem(0)

    # ------------------------------------------------
    # load file from db
    Supervisor.stop(App.Supervisor)
    App.Application.start(:normal, [])
    App.Repo.delete_all(App.HnswlibIndex)
    App.Repo.delete_all(App.Image)

    %App.HnswlibIndex{}
    |> App.HnswlibIndex.changeset(%{
      lock_version: next_lock,
      file: file,
      id: 1
    })
    |> App.Repo.insert()

    assert :ok ==
             Supervisor.start_child(App.Supervisor, {App.KnnIndex, [space: :cosine, index: ""]})
             |> elem(0)

    assert App.KnnIndex.get_index() == App.KnnIndex.load_index() |> elem(0)

    # ------------------------------------------------
    # no index file and index table no empty but no file.
    # because the process has been stopped without uploading an image
    Supervisor.stop(App.Supervisor)
    App.Application.start(:normal, [])
    App.Repo.delete_all(App.HnswlibIndex)
    App.Repo.delete_all(App.Image)

    %App.HnswlibIndex{}
    |> App.HnswlibIndex.changeset(%{
      lock_version: next_lock,
      file: nil,
      id: 1
    })
    |> App.Repo.insert()

    assert :ok ==
             Supervisor.start_child(App.Supervisor, {App.KnnIndex, [space: :cosine, index: ""]})
             |> elem(0)
  end

  defp set_path(name) do
    Application.app_dir(:app, ["priv", "static", "uploads"])
    |> Path.join(name)
  end
end
