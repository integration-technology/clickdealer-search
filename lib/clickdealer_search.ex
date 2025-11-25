defmodule ClickdealerSearch do
  @moduledoc """
  Documentation for `ClickdealerSearch`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ClickdealerSearch.run()
      :world

  """
  def run do
    body =
      %{
        query: "",
        filters: %{
          all: [
            %{manufacturer: "Volvo"},
            %{range: "Xc90"}
          ]
        },
        sort: [
          %{"_score" => "desc"},
          %{"price" => "desc"}
        ],
        page: %{size: 24, current: 1}
      }
      |> Jason.encode!()

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer search-jbcneo5evs3fed4wvgz1hx8n"}
    ]

    url =
      "https://advanced-search-v2.clickdealer.co.uk/api/as/v1/engines/prod-3729-v1/search.json"

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        IO.puts("Success!")
        IO.inspect(Jason.decode!(response_body))

      {:ok, %HTTPoison.Response{status_code: code, body: response_body}} ->
        IO.puts("HTTP error: #{code}")
        IO.inspect(response_body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("HTTPoison error:")
        IO.inspect(reason)
    end
  end
end
