defmodule MsiyspWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component

  @doc """
  Renders a simple table for activities.
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_click, :any, default: nil

  slot :col, required: true do
    attr :label, :string
  end

  def table(assigns) do
    ~H"""
    <div>
      <table id={@id}>
        <thead>
          <tr>
            <th :for={col <- @col}><%= col[:label] %></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @rows}>
            <td :for={col <- @col}>
              <%= render_slot(col, row) %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders flash notices.
  """
  attr :flash, :map, default: %{}, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <div :if={msg = Phoenix.Flash.get(@flash, :info)} class="flash info">
        <%= msg %>
      </div>
      <div :if={msg = Phoenix.Flash.get(@flash, :error)} class="flash error">
        <%= msg %>
      </div>
    </div>
    """
  end
end
