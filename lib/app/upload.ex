defmodule App.Upload do
  def run_task(path, filename, type) do
    bucket = Application.fetch_env!(:ex_aws, :bucket)

    Task.Supervisor.async_nolink(App.TaskSupervisor, fn ->
      path
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(bucket, filename,
        acl: :public_read,
        content_type: type,
        content_disposition: "inline"
      )
      |> ExAws.request()
    end)

  rescue
    e ->
      {:error, e}
  end
end
