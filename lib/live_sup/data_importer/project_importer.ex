defmodule LiveSup.DataImporter.ProjectImporter do
  alias LiveSup.Core.{Projects, Dashboards, Datasources, Widgets, Teams}
  alias LiveSup.Schemas.Project

  def import(%{"projects" => projects} = data) do
    projects
    |> Enum.each(fn project_attrs ->
      project_attrs
      |> get_or_create_project()
      |> import_dashboards(project_attrs)
    end)

    data
  end

  defp get_or_create_project(%{"id" => id} = attrs) do
    Projects.get(id) || Projects.create_public_project(attrs)
  end

  defp import_dashboards({:ok, %Project{} = project}, %{"dashboards" => dashboards}) do
    dashboards
    |> Enum.each(fn dashboard_attrs ->
      project
      |> get_or_create_dashboard(dashboard_attrs)
      |> import_widget(dashboard_attrs)
    end)
  end

  defp import_dashboards(nil, _args), do: :ok
  defp import_dashboards({:ok, %Project{} = _project}, _args), do: :ok
  defp import_dashboards(%Project{} = project, args), do: import_dashboards({:ok, project}, args)

  def get_or_create_dashboard(project, %{"id" => id} = attrs) do
    case Dashboards.get(id) do
      {:error, :not_found} -> Dashboards.create(project, attrs)
      {:ok, dashboard} -> {:ok, dashboard}
    end
  end

  def import_widget({:ok, dashboard}, %{"widgets" => widgets}) do
    widgets
    |> Enum.each(fn widget_attrs ->
      %{"id" => widget_instance_id} = widget_attrs
      widget_instance = Widgets.get_instance(widget_instance_id)

      if widget_instance == nil do
        dashboard
        |> create_widget_instance(widget_attrs)
      end
    end)
  end

  def create_widget_instance(
        dashboard,
        %{
          "datasource_slug" => datasource_slug,
          "widget_slug" => widget_slug,
          "id" => widget_instance_id
        } = attrs
      ) do
    settings = attrs["settings"] || %{}
    datasource = Datasources.get_by_slug!(datasource_slug)
    {:ok, datasource_instance} = Datasources.create_instance(datasource)
    widget = Widgets.get_by_slug!(widget_slug)

    widget_instance_attrs = Widgets.build_instance_attrs(widget, datasource_instance)

    widget_instance =
      Map.merge(widget_instance_attrs, %{
        settings: settings,
        id: widget_instance_id
      })

    {:ok, widget_instance} = Widgets.create_instance(widget_instance)

    dashboard
    |> Dashboards.add_widget(widget_instance)
  end

  def find_or_create_widget_instance(_, _), do: :ok
end