defmodule ClickdealerSearch do
  @moduledoc """
  Documentation for `ClickdealerSearch`.
  """

  @doc """
  Executes a search query against the Clickdealer API.

  ## Examples

      iex> ClickdealerSearch.run()
      :world

  """
  def run do
    ClickdealerSearch.Search.run()
  end
end
