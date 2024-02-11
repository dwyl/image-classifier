alias App.{Repo, HnswlibIndex}

# Reset the Index table
Repo.delete_all(HnswlibIndex)

# Reading the indexes_test.bin index file
{:ok, file} =
  Application.app_dir(:app, ["priv", "static", "uploads"])
  |> Path.join("indexes_test.bin")
  |> File.read()

  # Add it to the index table
Repo.insert!(%HnswlibIndex{
  id: 1,
  lock_version: 3,
  file: file
})

# Start the KNN-search genserver that was not started in the `application.ex` for the database to be seeded ----------
{:ok, _} = Supervisor.start_child(App.Supervisor, {App.KnnIndex, :cosine}) |> dbg()

# Start tests ---------------
ExUnit.start()
# Ecto.Adapters.SQL.Sandbox.mode(App.Repo, :manual)
