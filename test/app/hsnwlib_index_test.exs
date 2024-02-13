defmodule AppWeb.HSNWLIBIndexTest do
  use AppWeb.ConnCase

  alias App.{Repo, HnswlibIndex}

  test "if an index is found in the table but the file is empty, we force the index to be recreated" do

    # Reset the table and add the row where the file is empty
    Repo.delete_all(HnswlibIndex)
    Repo.insert!(%HnswlibIndex{id: 1, file: nil})

    # We call the functiont o load the index from the DB
    space = :cosine
    dim = 384
    max_elements = 200
    HnswlibIndex.maybe_load_index_from_db(space, dim, max_elements)

    # Get the recreated index file at the table
    index_row = Repo.get(HnswlibIndex, 1)

    refute index_row == nil
  end

  test "load index where the file is not empty" do

    # We call the functiont o load the index from the DB
    space = :cosine
    dim = 384
    max_elements = 200
    HnswlibIndex.maybe_load_index_from_db(space, dim, max_elements)

    # Get the recreated index file at the table
    index_row = Repo.get(HnswlibIndex, 1)

    refute index_row == nil
  end

end
