defmodule AppWeb.SupervisorSupport do
  @moduledoc """
    This is a support module helper that is meant to wait for all the children of a supervisor to complete.
    If you go to `lib/app/application.ex`, you'll see that we created a `TaskSupervisor`, where async tasks are spawned.
    This module helps us to wait for all the children to finish during tests.
  """

  @doc """
    Find all children spawned by this supervisor and wait until they finish.
  """
  def wait_for_completion() do
    pids = Task.Supervisor.children(App.TaskSupervisor)
    Enum.each(pids, &Process.monitor/1)
    wait_for_pids(pids)
  end

  defp wait_for_pids([]), do: nil

  defp wait_for_pids(pids) do
    receive do
      {:DOWN, _ref, :process, pid, _reason} -> wait_for_pids(List.delete(pids, pid))
    end
  end
end
