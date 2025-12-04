defmodule ClickdealerSearch.CarMonitor do
  @moduledoc """
  Monitors a specific car (ID: 7460084) and notifies when its status changes.
  Checks every 15 minutes using OTP recursion (via GenServer).
  """
  use GenServer
  require Logger

  # 15 minutes in milliseconds
  @check_interval 15 * 60 * 1000

  # Car ID to monitor
  @car_id "7460084"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("CarMonitor started - monitoring car ID: #{@car_id}")
    
    # Perform initial check
    send(self(), :check_car)
    
    # Initial state with no previous status
    {:ok, %{last_status: nil, last_details: nil}}
  end

  @impl true
  def handle_info(:check_car, state) do
    Logger.debug("Checking car status for ID: #{@car_id}")
    
    new_state = 
      case fetch_car_details() do
        {:ok, car_details} ->
          handle_car_details(car_details, state)
        
        {:error, reason} ->
          Logger.error("Failed to fetch car details: #{inspect(reason)}")
          state
      end
    
    # Schedule next check (OTP recursion)
    schedule_next_check()
    
    {:noreply, new_state}
  end

  @doc """
  Manually trigger a check (useful for testing).
  """
  def check_now do
    send(__MODULE__, :check_car)
  end

  @doc """
  Get the current state (last known status).
  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Private functions

  defp schedule_next_check do
    Process.send_after(self(), :check_car, @check_interval)
  end

  defp fetch_car_details do
    body =
      %{
        query: "",
        filters: %{
          all: [
            %{id: @car_id}
          ]
        },
        page: %{size: 1, current: 1}
      }
      |> Jason.encode!()

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer search-jbcneo5evs3fed4wvgz1hx8n"}
    ]

    url = "https://advanced-search-v2.clickdealer.co.uk/api/as/v1/engines/prod-3729-v1/search.json"

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        decoded = Jason.decode!(response_body)
        results = get_in(decoded, ["results"]) || []
        
        case results do
          [car | _] -> {:ok, car}
          [] -> {:ok, nil}  # Car not found
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        {:error, "HTTP #{status_code}: #{response_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp handle_car_details(nil, state) do
    # Car not found in results
    if state.last_status != :not_found do
      Logger.warning("🚨 Car #{@car_id} is NO LONGER AVAILABLE in search results!")
      notify_status_change(:not_found, state.last_details, nil)
      %{state | last_status: :not_found, last_details: nil}
    else
      state
    end
  end

  defp handle_car_details(car_details, state) do
    current_status = extract_status(car_details)
    
    if state.last_status == nil do
      # First check - just store the status
      formatted_status = format_status_for_logging(current_status)
      Logger.info("Initial car status: #{inspect(formatted_status)}")
      %{state | last_status: current_status, last_details: car_details}
    else
      # Check if status or price changed
      status_changed = status_changed?(state.last_status, current_status)
      price_changed = price_changed?(state.last_status, current_status)
      
      cond do
        status_changed and price_changed ->
          Logger.warning("🚨 Car status AND price CHANGED")
          notify_status_change(current_status, state.last_details, car_details)
          notify_price_change(current_status, state.last_status)
          %{state | last_status: current_status, last_details: car_details}
        
        status_changed ->
          Logger.warning("🚨 Car status CHANGED from #{inspect(state.last_status)} to #{inspect(current_status)}")
          notify_status_change(current_status, state.last_details, car_details)
          %{state | last_status: current_status, last_details: car_details}
        
        price_changed ->
          Logger.warning("💰 Car price CHANGED from #{format_price(state.last_status.price)} to #{format_price(current_status.price)}")
          notify_price_change(current_status, state.last_status)
          %{state | last_status: current_status, last_details: car_details}
        
        true ->
          Logger.debug("Car status unchanged: #{inspect(current_status)}")
          %{state | last_status: current_status, last_details: car_details}
      end
    end
  end

  defp extract_status(car_details) do
    status_code = get_in(car_details, ["status", "raw"]) |> to_integer()
    price = get_in(car_details, ["price", "raw"]) |> to_integer()
    year = get_in(car_details, ["year", "raw"]) |> to_integer()
    
    %{
      status_code: status_code,
      status_label: status_code_to_label(status_code),
      vrm: get_in(car_details, ["vrm", "raw"]),
      price: price,
      year: year
    }
  end

  defp to_integer(val) when is_number(val), do: round(val)
  defp to_integer(val) when is_binary(val), do: String.to_integer(val)
  defp to_integer(nil), do: 0

  defp format_price(price) when is_number(price) do
    "£ #{format_number(price)}"
  end
  
  defp format_price(price), do: to_string(price)

  defp format_status_for_logging(status) do
    %{
      status | 
      price: format_price(status.price)
    }
  end

  defp status_changed?(old_status, new_status) do
    # Only trigger alert if status_code changed
    old_status.status_code != new_status.status_code
  end

  defp price_changed?(old_status, new_status) do
    old_status.price != new_status.price
  end

  defp status_code_to_label(0), do: "Available"
  defp status_code_to_label(1), do: "Reserved / Deposit Taken"
  defp status_code_to_label(2), do: "Sold / Unavailable"
  defp status_code_to_label(3), do: "Deleted / Not Visible"
  defp status_code_to_label(code), do: "Unknown (#{code})"

  defp notify_status_change(new_status, old_details, new_details) do
    message = format_change_message(new_status, old_details, new_details)
    
    Logger.warning(IO.ANSI.yellow() <> message <> IO.ANSI.reset())
    
    # Send WhatsApp notification
    send_whatsapp_notification(message)
  end

  defp format_change_message(:not_found, old_details, _new_details) do
    old_vrm = get_in(old_details, ["vrm", "raw"]) || "Unknown"
    """
    🚨 CAR STATUS CHANGE ALERT 🚨
    
    Car #{@car_id} (#{old_vrm}) is NO LONGER AVAILABLE!
    The car has been removed from the search results.
    """
  end

  defp format_change_message(new_status, old_details, _new_details) do
    vrm = new_status.vrm || "Unknown"
    old_status_code = old_details && get_in(old_details, ["status", "raw"])
    old_status_label = status_code_to_label(old_status_code)
    
    """
    🚨 CAR STATUS CHANGE ALERT 🚨
    
    Car: #{vrm} (#{@car_id})
    Year: #{new_status.year || "N/A"}
    Price: #{format_price(new_status.price)}
    
    Status Changed:
    FROM: #{old_status_label} (#{old_status_code})
    TO:   #{new_status.status_label} (#{new_status.status_code})
    """
  end

  defp format_number(num) when is_number(num) do
    num
    |> round()
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_number(val), do: to_string(val)

  defp notify_price_change(new_status, old_status) do
    message = format_price_change_message(new_status, old_status)
    
    Logger.warning(IO.ANSI.yellow() <> message <> IO.ANSI.reset())
    
    # Send WhatsApp notification
    send_whatsapp_notification(message)
  end

  defp format_price_change_message(new_status, old_status) do
    vrm = new_status.vrm || "Unknown"
    
    """
    💰 CAR PRICE CHANGE ALERT 💰
    
    Car: #{vrm} (#{@car_id})
    Year: #{new_status.year || "N/A"}
    Status: #{new_status.status_label}
    
    Price Changed:
    FROM: #{format_price(old_status.price)}
    TO:   #{format_price(new_status.price)}
    """
  end

  defp send_whatsapp_notification(message) do
    ClickdealerSearch.Notifier.send_custom_message(message)
  end
end
