defmodule LiveSup.Test.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveSup.Core.Todos` context.
  """

  alias LiveSup.Queries.TaskQuery
  alias LiveSup.Schemas.Todo

  def task_fixture(%Todo{} = todo, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(default_attrs(todo))

    TaskQuery.create!(attrs)
    |> TaskQuery.get!()
  end

  defp default_attrs(%{id: todo_id}) do
    %{
      description: "Some generic description - #{System.unique_integer()}",
      todo_id: todo_id
    }
  end
end