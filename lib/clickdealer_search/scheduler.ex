defmodule ClickdealerSearch.Scheduler do
  @moduledoc """
  Schedules periodic searches for vehicles with registration ending in SOU.
  Runs every 30 minutes between 8am and 6pm.
  """
  use GenServer
  require Logger

  # 30 minutes in milliseconds
  @interval_ms 5 * 60 * 1000
  @target_suffix "SOU"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule first check
    schedule_next_check()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check, state) do
    if within_operating_hours?() do
      Logger.info("Running scheduled search check")
      perform_check()
    else
      Logger.debug("Outside operating hours (8am-6pm), skipping check")
    end

    # Schedule next check
    schedule_next_check()
    {:noreply, state}
  end

  defp schedule_next_check do
    Process.send_after(self(), :check, @interval_ms)
  end

  defp within_operating_hours? do
    now = DateTime.now!("Europe/London", Tzdata.TimeZoneDatabase)
    hour = now.hour
    hour >= 8 and hour < 18
  end

  defp perform_check do
    case ClickdealerSearch.Search.run() do
      {:ok, results} ->
        matches = filter_sou_registrations(results)

        if length(matches) > 0 do
          send_alert(matches)
        else
          Logger.info(
            "No vehicles with registration ending in #{@target_suffix} found.  Currently #{length(results)} vehicles live online."
          )
        end

      {:error, reason} ->
        Logger.error("Search failed: #{inspect(reason)}")
    end
  end

  defp filter_sou_registrations(results) do
    Enum.filter(results, fn result ->
      case get_in(result, ["vrm", "raw"]) do
        nil -> false
        vrm -> String.ends_with?(String.upcase(vrm), @target_suffix)
      end
    end)
  end

  defp send_alert(matches) do
    Logger.warning(
      "🚨 ALERT: Found #{length(matches)} vehicle(s) with registration ending in #{@target_suffix}"
    )

    # Log details
    Enum.each(matches, fn result ->
      registration = get_in(result, ["vrm", "raw"]) || "N/A"
      year = get_in(result, ["year", "raw"]) || "N/A"
      mileage = get_in(result, ["mileage", "raw"]) || "N/A"
      price = get_in(result, ["price", "raw"]) || 0

      message = """
      Registration: #{registration}
      Year: #{year}
      Mileage: #{mileage}
      Price: £#{format_price(price)}
      """

      Logger.warning(message)
    end)

    # Send WhatsApp notification
    ClickdealerSearch.Notifier.send_alert(matches)
  end

  defp format_price(price) when is_number(price) do
    price
    |> round()
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_price(_), do: "N/A"
end
