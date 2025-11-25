defmodule ClickdealerSearch.Notifier do
  @moduledoc """
  Handles sending notifications via WhatsApp.
  
  Supports multiple providers:
  - Twilio (recommended for production)
  - CallMeBot (simple, free, but less reliable)
  
  Configure via environment variables:
  - NOTIFIER_TYPE: "twilio" or "callmebot"
  - For Twilio:
    - TWILIO_ACCOUNT_SID
    - TWILIO_AUTH_TOKEN
    - TWILIO_WHATSAPP_FROM (e.g., "whatsapp:+14155238886")
    - WHATSAPP_TO (e.g., "whatsapp:+447700900000")
  - For CallMeBot:
    - CALLMEBOT_PHONE (your phone number with country code, no + or spaces)
    - CALLMEBOT_API_KEY (get from https://www.callmebot.com/blog/free-api-whatsapp-messages/)
  """
  require Logger

  @doc """
  Sends a WhatsApp notification with vehicle details.
  """
  def send_alert(matches) do
    notifier_type = System.get_env("NOTIFIER_TYPE", "callmebot")
    
    case notifier_type do
      "twilio" -> send_via_twilio(matches)
      "callmebot" -> send_via_callmebot(matches)
      _ -> Logger.error("Unknown notifier type: #{notifier_type}")
    end
  end

  defp send_via_twilio(matches) do
    account_sid = System.get_env("TWILIO_ACCOUNT_SID")
    auth_token = System.get_env("TWILIO_AUTH_TOKEN")
    from = System.get_env("TWILIO_WHATSAPP_FROM")
    to = System.get_env("WHATSAPP_TO")

    if !account_sid || !auth_token || !from || !to do
      Logger.error("Twilio credentials not configured. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_FROM, and WHATSAPP_TO")
      {:error, :missing_credentials}
    else

    message = format_message(matches)
    
    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json"
    
    body = URI.encode_query(%{
      "From" => from,
      "To" => to,
      "Body" => message
    })
    
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic #{Base.encode64("#{account_sid}:#{auth_token}")}"}
    ]
    
    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 201}} ->
        Logger.info("WhatsApp message sent via Twilio")
        :ok
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Twilio API error (#{status_code}): #{body}")
        {:error, status_code}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to send WhatsApp via Twilio: #{inspect(reason)}")
        {:error, reason}
    end
    end
  end

  defp send_via_callmebot(matches) do
    phone = System.get_env("CALLMEBOT_PHONE")
    api_key = System.get_env("CALLMEBOT_API_KEY")

    if !phone || !api_key do
      Logger.error("CallMeBot credentials not configured. Set CALLMEBOT_PHONE and CALLMEBOT_API_KEY")
      {:error, :missing_credentials}
    else

    message = format_message(matches)
    
    # CallMeBot has a message length limit
    message = String.slice(message, 0, 1000)
    
    url = "https://api.callmebot.com/whatsapp.php?" <>
          URI.encode_query(%{
            "phone" => phone,
            "text" => message,
            "apikey" => api_key
          })
    
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("WhatsApp message sent via CallMeBot")
        :ok
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("CallMeBot API error (#{status_code}): #{body}")
        {:error, status_code}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to send WhatsApp via CallMeBot: #{inspect(reason)}")
        {:error, reason}
    end
    end
  end

  defp format_message(matches) do
    header = "🚨 *Car Alert!*\nFound #{length(matches)} vehicle(s) with registration ending in SOU:\n\n"
    
    vehicles = Enum.map_join(matches, "\n---\n", fn result ->
      registration = get_in(result, ["vrm", "raw"]) || "N/A"
      year = get_in(result, ["year", "raw"]) || "N/A"
      mileage = get_in(result, ["mileage", "raw"]) || "N/A"
      price = get_in(result, ["price", "raw"]) || 0
      
      """
      *#{registration}*
      Year: #{year}
      Mileage: #{mileage}
      Price: £#{format_price(price)}
      """
    end)
    
    header <> vehicles
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
