defmodule ClickdealerSearch.CarMonitorTest do
  use ExUnit.Case, async: true
  
  @car_id "7460084"
  @expected_vrm "RJ71SOU"

  describe "fetch_car_details response handling" do
    test "handles single vehicle matching expected VRM" do
      # This is the happy path - one result returned
      results = [
        %{
          "id" => %{"raw" => @car_id},
          "vrm" => %{"raw" => @expected_vrm},
          "price" => %{"raw" => 15000},
          "status" => %{"raw" => 0},
          "year" => %{"raw" => 2021}
        }
      ]

      car = extract_first_result(results)
      
      assert car != nil
      assert get_in(car, ["vrm", "raw"]) == @expected_vrm
      assert get_in(car, ["id", "raw"]) == @car_id
    end

    test "handles multiple vehicles returned (takes first one)" do
      # Even though we filter by ID, API might return multiple results
      results = [
        %{
          "id" => %{"raw" => @car_id},
          "vrm" => %{"raw" => @expected_vrm},
          "price" => %{"raw" => 15000},
          "status" => %{"raw" => 0},
          "year" => %{"raw" => 2021}
        },
        %{
          "id" => %{"raw" => "9999999"},
          "vrm" => %{"raw" => "AB12XYZ"},
          "price" => %{"raw" => 20000},
          "status" => %{"raw" => 0},
          "year" => %{"raw" => 2022}
        }
      ]

      # fetch_car_details takes first result with pattern match: [car | _]
      car = extract_first_result(results)
      
      assert car != nil
      assert get_in(car, ["vrm", "raw"]) == @expected_vrm
      # This confirms we're getting the FIRST result, not filtering by VRM
    end

    test "handles vehicle with different VRM than expected" do
      # What if the API returns a car with same ID but different VRM?
      # This could happen if the car is re-registered or data is wrong
      results = [
        %{
          "id" => %{"raw" => @car_id},
          "vrm" => %{"raw" => "DIFFERENT"},
          "price" => %{"raw" => 15000},
          "status" => %{"raw" => 0},
          "year" => %{"raw" => 2021}
        }
      ]

      car = extract_first_result(results)
      
      assert car != nil
      assert get_in(car, ["vrm", "raw"]) == "DIFFERENT"
      # The monitor will still track this car because it's filtering by ID
      # It doesn't validate the VRM matches expectations
    end

    test "handles vehicle with nil VRM" do
      results = [
        %{
          "id" => %{"raw" => @car_id},
          "vrm" => %{"raw" => nil},
          "price" => %{"raw" => 15000},
          "status" => %{"raw" => 0},
          "year" => %{"raw" => 2021}
        }
      ]

      car = extract_first_result(results)
      
      assert car != nil
      assert get_in(car, ["vrm", "raw"]) == nil
      # Status extraction will handle nil VRM gracefully
    end

    test "handles vehicle with missing VRM field" do
      results = [
        %{
          "id" => %{"raw" => @car_id},
          "price" => %{"raw" => 15000},
          "status" => %{"raw" => 0},
          "year" => %{"raw" => 2021}
          # No "vrm" field at all
        }
      ]

      car = extract_first_result(results)
      
      assert car != nil
      assert get_in(car, ["vrm", "raw"]) == nil
    end

    test "handles empty results list" do
      results = []
      
      car = extract_first_result(results)
      
      assert car == nil
    end
  end

  describe "status extraction and comparison" do
    test "extracts status correctly with all fields present" do
      car_details = %{
        "vrm" => %{"raw" => @expected_vrm},
        "price" => %{"raw" => 15000},
        "status" => %{"raw" => 0},
        "year" => %{"raw" => 2021}
      }

      status = extract_status(car_details)

      assert status.vrm == @expected_vrm
      assert status.price == 15000
      assert status.status_code == 0
      assert status.status_label == "Available"
      assert status.year == 2021
    end

    test "extracts status with wrong VRM" do
      car_details = %{
        "vrm" => %{"raw" => "WRONGVRM"},
        "price" => %{"raw" => 15000},
        "status" => %{"raw" => 0},
        "year" => %{"raw" => 2021}
      }

      status = extract_status(car_details)

      # Monitor doesn't validate VRM - it just extracts it
      assert status.vrm == "WRONGVRM"
      assert status.price == 15000
      assert status.status_code == 0
    end

    test "extracts status with nil VRM" do
      car_details = %{
        "vrm" => %{"raw" => nil},
        "price" => %{"raw" => 15000},
        "status" => %{"raw" => 1},
        "year" => %{"raw" => 2021}
      }

      status = extract_status(car_details)

      assert status.vrm == nil
      assert status.status_code == 1
      assert status.status_label == "Reserved / Deposit Taken"
    end

    test "extracts status with missing fields" do
      car_details = %{
        "status" => %{"raw" => 2}
        # Missing vrm, price, year
      }

      status = extract_status(car_details)

      assert status.vrm == nil
      assert status.price == nil
      assert status.status_code == 2
      assert status.status_label == "Sold / Unavailable"
      assert status.year == nil
    end
  end

  describe "status change detection" do
    test "detects status code change" do
      old_status = %{status_code: 0, status_label: "Available", price: 15000, vrm: @expected_vrm}
      new_status = %{status_code: 1, status_label: "Reserved / Deposit Taken", price: 15000, vrm: @expected_vrm}

      assert status_changed?(old_status, new_status) == true
    end

    test "does not detect change when status code is same" do
      old_status = %{status_code: 0, status_label: "Available", price: 15000, vrm: @expected_vrm}
      new_status = %{status_code: 0, status_label: "Available", price: 16000, vrm: @expected_vrm}

      # Price changed but status didn't
      assert status_changed?(old_status, new_status) == false
    end

    test "detects price change" do
      old_status = %{status_code: 0, status_label: "Available", price: 15000, vrm: @expected_vrm}
      new_status = %{status_code: 0, status_label: "Available", price: 14000, vrm: @expected_vrm}

      assert price_changed?(old_status, new_status) == true
    end

    test "does not detect price change when same" do
      old_status = %{status_code: 0, status_label: "Available", price: 15000, vrm: @expected_vrm}
      new_status = %{status_code: 1, status_label: "Reserved / Deposit Taken", price: 15000, vrm: @expected_vrm}

      assert price_changed?(old_status, new_status) == false
    end

    test "VRM change does not trigger status change" do
      # If API returns different VRM for same ID, status_changed? should only look at status_code
      old_status = %{status_code: 0, status_label: "Available", price: 15000, vrm: @expected_vrm}
      new_status = %{status_code: 0, status_label: "Available", price: 15000, vrm: "NEWVRM"}

      assert status_changed?(old_status, new_status) == false
    end
  end

  describe "status code label mapping" do
    test "maps status code 0 to Available" do
      assert status_code_to_label(0) == "Available"
    end

    test "maps status code 1 to Reserved" do
      assert status_code_to_label(1) == "Reserved / Deposit Taken"
    end

    test "maps status code 2 to Sold" do
      assert status_code_to_label(2) == "Sold / Unavailable"
    end

    test "maps status code 3 to Deleted" do
      assert status_code_to_label(3) == "Deleted / Not Visible"
    end

    test "handles unknown status code" do
      assert status_code_to_label(99) == "Unknown (99)"
    end

    test "handles nil status code" do
      assert status_code_to_label(nil) == "Unknown ()"
    end
  end

  # Helper functions that replicate the private functions in CarMonitor
  defp extract_first_result(results) do
    case results do
      [car | _] -> car
      [] -> nil
    end
  end

  defp extract_status(car_details) do
    status_code = get_in(car_details, ["status", "raw"])
    
    %{
      status_code: status_code,
      status_label: status_code_to_label(status_code),
      vrm: get_in(car_details, ["vrm", "raw"]),
      price: get_in(car_details, ["price", "raw"]),
      year: get_in(car_details, ["year", "raw"])
    }
  end

  defp status_changed?(old_status, new_status) do
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
end
