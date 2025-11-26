defmodule ClickdealerSearch.Search do
  @moduledoc """
  Handles search functionality for Clickdealer API.

  This module exposes `run/0` which performs the HTTP request, prints a
  human-readable results table to STDOUT, and returns `{:ok, results}` or
  `{:error, reason}` so callers (like the scheduler) can act on the results.
  """

  @doc """
  Execute a search query against the Clickdealer API, print a table of results,
  and return `{:ok, results}` or `{:error, reason}`.

  Example:

      iex> ClickdealerSearch.Search.run()
      {:ok, [%{"vrm" => %{"raw" => "RK71SOU"}, ...}, ...]}

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
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        decoded = Jason.decode!(response_body)
        transformed = transform_results(decoded)
        results = transformed["results"] || []

        # Print table for human consumption
        display_table(%{"results" => results})

        # Return results to caller for programmatic use
        {:ok, results}

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        # Provide some context if available
        message =
          case response_body do
            body when is_binary(body) and body != "" ->
              "Unexpected status code: #{status_code} - #{body}"

            _ ->
              "Unexpected status code: #{status_code}"
          end

        {:error, message}
    end
  end

  # Transform the results in-place to make presentation nicer
  defp transform_results(%{"results" => results} = response) when is_list(results) do
    transformed_results = Enum.map(results, &transform_result/1)
    Map.put(response, "results", transformed_results)
  end

  defp transform_results(other), do: other

  defp transform_result(result) when is_map(result) do
    result
    |> Map.update("year", nil, fn year_data ->
      case year_data do
        %{"raw" => raw} when is_number(raw) -> %{"raw" => round(raw)}
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
        %{"raw" => raw} when is_number(raw) -> %{"raw" => format_thousands(raw)}
        _ -> mileage_data
      end
    end)
  end

  defp transform_result(other), do: other

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

  # Display a simple table to stdout. Accepts a map with "results" => list.
  defp display_table(%{"results" => results}) when is_list(results) do
    # Header
    IO.puts(
      "\n" <>
        String.pad_trailing("Registration", 15) <>
        String.pad_trailing("Year", 10) <>
        String.pad_trailing("Mileage", 15) <>
        "Price"
    )

    IO.puts(String.duplicate("-", 55))

    Enum.each(results, fn result ->
      registration = get_in(result, ["vrm", "raw"]) || "N/A"
      year = get_in(result, ["year", "raw"]) || "N/A"
      mileage = get_in(result, ["mileage", "raw"]) || "N/A"

      price_raw = get_in(result, ["price", "raw"]) || 0

      price_number =
        case price_raw do
          n when is_number(n) ->
            round(n)

          s when is_binary(s) ->
            case Integer.parse(String.replace(s, ",", "")) do
              {int, _} -> int
              :error -> 0
            end

          _ ->
            0
        end

      price_formatted = "£ #{format_thousands(price_number)}"

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

  defp display_table(_), do: IO.puts("No results to display.")
end
