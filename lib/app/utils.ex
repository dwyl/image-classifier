defmodule App.Utils do
  @doc """
  Computes the SHA256 from a binary file and shortens the name
  """
  def short_name(binary, type) do
    ext = String.split(type, "/") |> List.last()
    sha256 = :crypto.hash(:sha256, binary)

    basename =
      :crypto.macN(:hmac, :sha256, "tiny URL", sha256, 16)
      |> Base.encode16()

    basename <> "." <> ext
  end

  @doc """
  Given a name, it copies a file at a given path into a new in the "priv/Static/image_uploads" folder.
  """
  def copy_path_into(name, path) do
    tmp_path =
      Application.app_dir(:app, ["priv", "static", "uploads", name])

    path
    |> File.stream!([], 64_000)
    |> Stream.into(File.stream!(tmp_path))
    |> Stream.run()

    tmp_path
  end

  @doc """
  Hash of a file
  """
  def hash(path) when is_binary(path) do
    case File.exists?(path) do
      true ->
        File.stream!(path, [], 2048)
        |> Enum.reduce(:crypto.hash_init(:sha256), fn curr_chunk, prev ->
          :crypto.hash_update(prev, curr_chunk)
        end)
        |> :crypto.hash_final()
        |> terminate()

      false ->
        nil
    end
  end

  @doc """
  HMAC hash used to produce a short name
  """
  def terminate(string) when is_binary(string) do
    :crypto.macN(:hmac, :sha256, "tiny URL", string, 16)
    |> Base.encode16()
  end
end
