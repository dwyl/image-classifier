defmodule AppWeb.PageLiveTest do
  use AppWeb.ConnCase
  import Phoenix.LiveViewTest
  import AppWeb.UploadSupport
  import Mock

  @moduledoc false

  test "connected mount", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Caption your image!"

    {:ok, _view, _html} = live(conn)
  end

  ############################################################
  # MOUNTING -------------------------------------------------
  ############################################################

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

  ############################################################
  # SUCCESSFUL SCENARIOS -------------------------------------
  ############################################################

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

  test "Image operations" do
    assert {:error, "test"} == AppWeb.PageLive.pre_process_image({:error, "test"})
    assert :ok == AppWeb.PageLive.predict_example_image("1", "http://example.com")
    assert {:error, "Failed to get VipsImage"} == AppWeb.PageLive.to_tensor(%Vix.Vips.Image{})
    assert {:error, "failed to get GObject argument"} == AppWeb.PageLive.srgb(%Vix.Vips.Image{})
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

  ############################################################
  # ERROR SCENARIOS ------------------------------------------
  ############################################################

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

  ############################################################
  # UNIT TESTS ON HANDLERS -----------------------------------
  ############################################################

  test "handle_intermediate_progress", %{conn: _conn} do
    ret = AppWeb.PageLive.handle_progress(:image_list, %{}, %{})
    assert ret == {:noreply, %{}}
  end

  test "noop event handler", %{conn: _conn} do
    ret = AppWeb.PageLive.handle_event("noop", %{}, %{})

    assert ret == {:noreply, %{}}
  end

  ############################################################
  # KnnIndex GenServer testing -------------------------------
  ############################################################

  @tag timeout: 120_000
  test "genserver init" do
    # File.mkdir_p!(Application.app_dir(:app, ["priv", "static", "uploads"]))
    path = set_path("indexes_gen_test_1.bin")
    {:ok, file} = File.read(path)

    # ------------------------------------------------
    # happy path:
    # - db image table contains an Index file,
    # - the index file exists in the FileSystem
    # - both have same length

    reset()

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
    # case:
    # - Index file exists on Filesystem
    # - db index table is empty

    reset()

    assert {:error, "Incoherence on table"} ==
             Supervisor.start_child(App.Supervisor, {App.KnnIndex, [space: :cosine, index: path]})
             |> elem(1)
             |> elem(0)

    # ------------------------------------------------
    # case:
    # - db index table contains a copy of an Index file
    # - an Index file exists on Filesystem
    # - but length are different

    reset()

    path = set_path("indexes_gen_test_2.bin")

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
    # case:
    # - no Index file on Filesyste
    # - db index table contains Inde file
    # => file is loaded from db

    reset()

    {:ok, _index_db} =
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

    # -------------------------------------------------
    # case:
    # - no Index file in FileSystem
    # - db index table is not empty but does not contain a file.
    # => this simulates the state when the process has been stopped without uploading an image

    reset()

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

    # -------------------------------------------------
    # case:
    # - load a bad index file

    reset()

    path = set_path("indexes_gen_test_3.bin")
    {:ok, file} = File.read(path)

    %App.HnswlibIndex{}
    |> App.HnswlibIndex.changeset(%{
      lock_version: next_lock,
      file: file,
      id: 1
    })
    |> App.Repo.insert()

    assert :error ==
             Supervisor.start_child(
               App.Supervisor,
               {App.KnnIndex, [space: :cosine, index: path]}
             )
             |> elem(0)

    # -------------------------------------------------
    # case:
    # - knn_search with empty Index
    # - knn_search with no index file
    # - Hnwslib error adding embedding, above limit
    # - failure on saving Index to db
    reset()

    path = set_path("indexes_empty.bin")

    %App.HnswlibIndex{}
    |> App.HnswlibIndex.changeset(%{
      lock_version: next_lock,
      file: File.read!(path),
      id: 1
    })
    |> App.Repo.insert()

    {:ok, state} = App.KnnIndex.init(space: :cosine, index: path)

    assert {:reply, {:error, "no index found"}, state} ==
             App.KnnIndex.handle_call({:knn_search, nil}, self(), state)

    # capture Hnwslib error: "number above limit" because returned number is less than k=1
    # check issue <https://github.com/nmslib/hnswlib/issues/244>
    emb = Nx.iota({384}, type: :f32)

    assert :error ==
             App.KnnIndex.handle_call({:knn_search, emb}, self(), state)
             |> elem(1)
             |> elem(0)

    # -------------------------------
    # test ok inserting embedding
    reset()
    path = set_path("indexes_gen_test_1.bin")

    %App.HnswlibIndex{}
    |> App.HnswlibIndex.changeset(%{
      lock_version: next_lock,
      file: File.read!(path),
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

    {:ok, state} = App.KnnIndex.init(space: :cosine, index: path)

    # error embedding limit
    emb = Nx.iota({384}, type: :f32)

    assert {:ok, 2} ==
             App.KnnIndex.handle_call({:add_item, emb}, self(), state)
             |> elem(1)

    # -------------------------------
    # test error save_in_db if file does not exist
    reset()
    path = set_path("indexes_empty.bin")

    %App.HnswlibIndex{}
    |> App.HnswlibIndex.changeset(%{
      lock_version: next_lock,
      file: File.read!(path),
      id: 1
    })
    |> App.Repo.insert()

    {:ok, state} = App.KnnIndex.init(space: :cosine, index: path)

    assert :error ==
             App.KnnIndex.handle_call({:add_item, emb}, self(), state)
             |> elem(1)
             |> elem(0)

    # Index file does not exist any more on FileSystem
    {index, _, space} = state
    set_path("indexes_test.bin") |> File.rm()

    assert :error ==
             App.KnnIndex.handle_call(
               :save_index_to_db,
               self(),
               {index, %App.HnswlibIndex{id: 1, lock_version: 2}, space}
             )
             |> elem(1)
             |> elem(0)
  end

  # -------------
  ### Helpers functions
  def set_path(name) do
    Application.app_dir(:app, ["priv", "static", "uploads"])
    |> Path.join(name)
  end

  def reset do
    Supervisor.stop(App.Supervisor)
    App.Application.start(:normal, [])
    App.Repo.delete_all(App.HnswlibIndex)
    App.Repo.delete_all(App.Image)
  end

  ############################################################
  # GUARD TEST ON AUDIO -------------------------------------
  ############################################################

  test "do not run audio if image bank is empty", %{conn: conn} do
    path = set_path("indexes_empty.bin")
    next_lock = 2

    App.Application.start(:normal, [])
    # Supervisor.which_children(App.Supervisor)

    {:ok, lv, _html} = live(conn, ~p"/")
    assert render_hook(lv, "show_examples", %{})

    App.Repo.delete_all(App.HnswlibIndex)
    App.Repo.delete_all(App.Image)

    %App.HnswlibIndex{}
    |> App.HnswlibIndex.changeset(%{
      lock_version: next_lock,
      file: File.read!(path),
      id: 1
    })
    |> App.Repo.insert()

    Supervisor.start_child(
      App.Supervisor,
      {App.KnnIndex, [space: :cosine, index: path]}
    )

    # Get audio file and add it to the form
    file =
      [:code.priv_dir(:app), "static", "audio", "itwillallbeok.mp3"]
      |> Path.join()
      |> build_upload("audio/mp3")

    audio = file_input(lv, "#audio-upload-form", :speech, [file])

    # Should show an uploaded local file
    assert render_upload(audio, file.name)

    # Wait for the audio prediction to end
    AppWeb.SupervisorSupport.wait_for_completion()

    # Wait for the audio transcription to end.
    # This will spawn another async task
    assert render_async(lv)

    # Wait for the embedding knn search to end
    AppWeb.SupervisorSupport.wait_for_completion()

    # A prediction should have occurred and the label should be shown with the audio transcription
    assert render_async(lv) |> Floki.find("#output") |> Floki.text() =~
             "!! The image bank is empty. Please upload some !!"
  end
end
