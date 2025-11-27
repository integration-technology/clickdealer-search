defmodule ClickdealerSearch.NotifierIntegrationTest do
  use ExUnit.Case

  @moduletag :integration

  @moduledoc """
  Integration test that sends a real WhatsApp message via the configured notifier.

  This test is intended to be run explicitly and will perform a live send.
  Run it with:

      mix test test/notifier_integration_test.exs --only integration

  Ensure your notifier is configured (the project currently defaults to CallMeBot
  with hardcoded credentials in the notifier module).
  """

  test "sends whatsapp via CallMeBot (integration)" do
    match = %{
      "vrm" => %{"raw" => "INTEG SOU"},
      "year" => %{"raw" => 2022},
      "mileage" => %{"raw" => "10,000"},
      "price" => %{"raw" => 10000}
    }

    # Perform the live send. This should return :ok when the provider accepts the message.
    result = ClickdealerSearch.Notifier.send_alert([match])

    assert result == :ok
  end
end
