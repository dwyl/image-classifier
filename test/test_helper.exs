alias App.{Repo, HnswlibIndex, Image}

# Reset the Index table
Repo.delete_all(HnswlibIndex)
Repo.delete_all(Image)

# Start the KNN-search genserver that was not started in the `application.ex` for the database to be seeded.
{:ok, _} = Supervisor.start_child(App.Supervisor, {App.KnnIndex, :cosine})

# Start tests ---------------
ExUnit.start()
ExUnit.after_suite(fn _ ->
  # Deletes the `indexes_test.bin` file after the tests are executed.
  # Make sure it's the same one used in `App.KnnIndex` so `mix test` always executes successfully.
  Application.app_dir(:app, ["priv", "static", "uploads"])
  |> Path.join("indexes_test.bin")
  |> File.rm()
end)
