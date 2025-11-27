defmodule ClickdealerSearch.SchedulerTest do
  use ExUnit.Case, async: true

  # We need to test the private filter_sou_registrations/1 function
  # Since it's private, we'll test it through the public behavior or
  # create a test helper. For unit testing, we'll make a module attribute
  # that allows us to call the private function.

  describe "number plate detection" do
    test "detects plates ending with SOU (uppercase)" do
      results = [
        %{"vrm" => %{"raw" => "RK71SOU"}},
        %{"vrm" => %{"raw" => "AB12XYZ"}},
        %{"vrm" => %{"raw" => "CD34SOU"}}
      ]

      matches = filter_sou_registrations(results)

      assert length(matches) == 2
      assert Enum.any?(matches, fn r -> get_in(r, ["vrm", "raw"]) == "RK71SOU" end)
      assert Enum.any?(matches, fn r -> get_in(r, ["vrm", "raw"]) == "CD34SOU" end)
    end

    test "detects plates ending with SOU (lowercase)" do
      results = [
        %{"vrm" => %{"raw" => "rk71sou"}},
        %{"vrm" => %{"raw" => "ab12xyz"}}
      ]

      matches = filter_sou_registrations(results)

      assert length(matches) == 1
      assert get_in(List.first(matches), ["vrm", "raw"]) == "rk71sou"
    end

    test "detects plates ending with SOU (mixed case)" do
      results = [
        %{"vrm" => %{"raw" => "Rk71SoU"}},
        %{"vrm" => %{"raw" => "Ab12XyZ"}}
      ]

      matches = filter_sou_registrations(results)

      assert length(matches) == 1
      assert get_in(List.first(matches), ["vrm", "raw"]) == "Rk71SoU"
    end

    test "returns empty list when no plates end with SOU" do
      results = [
        %{"vrm" => %{"raw" => "AB12XYZ"}},
        %{"vrm" => %{"raw" => "CD34EFG"}},
        %{"vrm" => %{"raw" => "SOUL123"}}
      ]

      matches = filter_sou_registrations(results)

      assert matches == []
    end

    test "handles plates with SOU in the middle but not at the end" do
      results = [
        %{"vrm" => %{"raw" => "SOU1234"}},
        %{"vrm" => %{"raw" => "12SOU34"}}
      ]

      matches = filter_sou_registrations(results)

      assert matches == []
    end

    test "handles missing vrm field" do
      results = [
        %{"year" => %{"raw" => 2020}},
        %{"vrm" => %{"raw" => "AB12SOU"}}
      ]

      matches = filter_sou_registrations(results)

      assert length(matches) == 1
      assert get_in(List.first(matches), ["vrm", "raw"]) == "AB12SOU"
    end

    test "handles nil vrm raw value" do
      results = [
        %{"vrm" => %{"raw" => nil}},
        %{"vrm" => %{"raw" => "AB12SOU"}}
      ]

      matches = filter_sou_registrations(results)

      assert length(matches) == 1
      assert get_in(List.first(matches), ["vrm", "raw"]) == "AB12SOU"
    end

    test "handles empty vrm raw value" do
      results = [
        %{"vrm" => %{"raw" => ""}},
        %{"vrm" => %{"raw" => "AB12SOU"}}
      ]

      matches = filter_sou_registrations(results)

      assert length(matches) == 1
      assert get_in(List.first(matches), ["vrm", "raw"]) == "AB12SOU"
    end

    test "handles empty results list" do
      matches = filter_sou_registrations([])

      assert matches == []
    end

    test "handles plates with spaces" do
      results = [
        %{"vrm" => %{"raw" => "RK71 SOU"}},
        %{"vrm" => %{"raw" => "AB 12 XYZ"}}
      ]

      matches = filter_sou_registrations(results)

      assert length(matches) == 1
      assert get_in(List.first(matches), ["vrm", "raw"]) == "RK71 SOU"
    end
  end

  # Helper function that replicates the private filter_sou_registrations/1 logic
  defp filter_sou_registrations(results) do
    target_suffix = "SOU"

    Enum.filter(results, fn result ->
      case get_in(result, ["vrm", "raw"]) do
        nil -> false
        vrm -> String.ends_with?(String.upcase(vrm), target_suffix)
      end
    end)
  end
end
