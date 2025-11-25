defmodule ClickdealerSearch.Search do
  @moduledoc """
  Handles search functionality for Clickdealer API.
  """

  @doc """
  Executes a search query against the Clickdealer API.

  ## Examples

      iex> ClickdealerSearch.Search.run()
      :world

  """
  def run do
    case run_silent() do
      {:ok, results} -> display_results(results)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Executes a search query and returns results without printing.
  Returns {:ok, results} or {:error, reason}.
  """
  def run_silent do
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

    HTTPoison.post(url, body, headers)
    |> handle_response_silent()
  end


  defp handle_response_silent({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  defp handle_response_silent({:ok, %HTTPoison.Response{status_code: 200, body: response_body}}) do
    decoded = Jason.decode!(response_body)
    transformed = transform_results(decoded)
    {:ok, transformed["results"]}
  end

  defp handle_response_silent({:ok, %HTTPoison.Response{status_code: status_code}}) do
    {:error, "Unexpected status code: #{status_code}"}
  end

  defp display_results(results) when is_list(results) do
    response = %{"results" => results}
    display_table(response)
    :ok
  end

  defp transform_results(%{"results" => results} = response) do
    transformed_results = Enum.map(results, &transform_result/1)
    Map.put(response, "results", transformed_results)
  end

  defp transform_result(result) do
    result
    |> Map.update("year", nil, fn year_data ->
      case year_data do
        %{"raw" => raw} -> %{"raw" => round(raw)}
        _ -> year_data
      end
    end)
    |> Map.update("vrm", nil, fn vrm_data ->
      case vrm_data do
        %{"raw" => raw} -> %{"raw" => raw}
        _ -> vrm_data
      end
    end)
    |> Map.update("mileage", nil, fn mileage_data ->
      case mileage_data do
        %{"raw" => raw} -> %{"raw" => format_thousands(raw)}
        _ -> mileage_data
      end
    end)
  end

  defp format_thousands(number) when is_number(number) do
    number
    |> trunc()
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_thousands(value), do: value

  defp display_table(%{"results" => results}) do
    # Print header
    IO.puts(
      "\n" <>
        String.pad_trailing("Registration", 15) <>
        String.pad_trailing("Year", 10) <> String.pad_trailing("Mileage", 15) <> "Price"
    )

    IO.puts(String.duplicate("-", 55))

    # Print each result
    Enum.each(results, fn result ->
      registration = get_in(result, ["vrm", "raw"]) || "N/A"
      year = get_in(result, ["year", "raw"]) || "N/A"
      mileage = get_in(result, ["mileage", "raw"]) || "N/A"
      price = get_in(result, ["price", "raw"]) || 0
      price_formatted = "£ #{format_thousands(round(price))}"

      IO.puts(
        String.pad_trailing(to_string(registration), 15) <>
          String.pad_trailing(to_string(year), 10) <>
          String.pad_trailing(to_string(mileage), 15) <>
          price_formatted
      )
    end)

    IO.puts("Found #{length(results)} results.")
    IO.puts("End of search results.")
  end
end
