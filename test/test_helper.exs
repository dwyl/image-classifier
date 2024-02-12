alias App.{Repo, HnswlibIndex, Image}

# Reset the Index table
Repo.delete_all(HnswlibIndex)
Repo.delete_all(Image)

# Reading the indexes_test_base.bin index file for the tests
{:ok, file} =
  Application.app_dir(:app, ["priv", "static", "uploads"])
  |> Path.join("indexes_test_base.bin")
  |> File.read()

# Add it to the index table
Repo.insert!(%HnswlibIndex{
  id: 1,
  lock_version: 3,
  file: file
})

# Add an image to the images table (the `indexes_test.bin` file was created with this image)
Repo.insert!(%Image{
  id: 1,
  url:
    "https://github.com/dwyl/image-classifier/assets/17494745/21a6bddd-eb4d-480e-9fa9-40ab00b1ac0b",
  description: "a silver car parked on the side of a road",
  width: 960,
  height: 656,
  idx: 1,
  sha1: "9546FDAE19F282AB8B2F5E8AB7D860F5789E83AE"
})

# Start the KNN-search genserver that was not started in the `application.ex` for the database to be seeded.
{:ok, _} = Supervisor.start_child(App.Supervisor, {App.KnnIndex, :cosine}) |> dbg()

# Start tests ---------------
ExUnit.start()
ExUnit.after_suite(fn _ ->
  Application.app_dir(:app, ["priv", "static", "uploads"])
  |> Path.join("indexes_test.bin")
  |> File.rm!()
end)
