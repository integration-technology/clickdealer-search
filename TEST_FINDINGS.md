# CarMonitor Test Findings

## Test Coverage Summary

Created comprehensive tests for `CarMonitor` to understand behavior in edge cases.

### Key Findings

#### 1. Multiple Vehicles Returned
**Test:** `handles multiple vehicles returned (takes first one)`

**Behavior:** When the API returns multiple results (even though filtered by ID), the monitor uses pattern matching `[car | _]` and takes **only the first result**.

**Implication:** 
- If the API mistakenly returns multiple vehicles, only the first one is tracked
- No validation that the correct car is being monitored
- This is generally safe since the search filters by specific ID: `7460084`

#### 2. Different VRM Than Expected (RJ71SOU)
**Test:** `handles vehicle with different VRM than expected`

**Behavior:** The monitor tracks by **ID only**, not by VRM. If the API returns a car with ID `7460084` but a different VRM (e.g., "DIFFERENT"), the monitor will:
- Accept and track this vehicle
- Extract whatever VRM is in the data
- Include that VRM in notifications
- **NOT validate** that VRM matches `RJ71SOU`

**Implication:**
- If the car is re-registered with a new plate, the monitor will continue tracking it by ID
- If there's a data error in the API (wrong VRM for this ID), you'll get notifications with the wrong VRM
- The VRM in notifications comes from the API data, not hardcoded

#### 3. Missing or Nil VRM
**Tests:** 
- `handles vehicle with nil VRM`
- `handles vehicle with missing VRM field`

**Behavior:** The monitor handles missing/nil VRMs gracefully:
- Extracts `nil` for the VRM field
- Status tracking continues normally based on status code and price
- Notifications will show "Unknown" for the car description

**Implication:** If the API has incomplete data, the monitor continues working but with less useful notifications.

### Status and Price Change Detection

#### Status Changes
- Triggered **only** when `status.raw` code changes (0→1, 1→2, etc.)
- Ignores changes to VRM, price, year, or other fields
- Maps status codes to human-readable labels in notifications

#### Price Changes  
- Triggered when `price.raw` value changes
- Sends separate notification from status changes
- If both change at once, sends two notifications

#### Mileage
- **Not tracked** - intentionally excluded from status extraction
- Mileage changes will never trigger notifications

### Status Code Mapping
- `0` = Available
- `1` = Reserved / Deposit Taken  
- `2` = Sold / Unavailable
- `3` = Deleted / Not Visible
- Any other value = "Unknown (N)"

## Recommendations

### Current Implementation is Safe IF:
1. The API reliably returns only one result when filtering by ID `7460084`
2. The VRM for car ID `7460084` doesn't change (or you don't care if it does)
3. You're okay with notifications showing whatever VRM the API returns

### Potential Improvements:
If you want stricter validation, consider:

1. **VRM Validation:** Add a check to ensure returned VRM matches `RJ71SOU`
   ```elixir
   defp validate_vrm(car_details) do
     vrm = get_in(car_details, ["vrm", "raw"])
     if vrm != "RJ71SOU" do
       Logger.warning("VRM mismatch! Expected RJ71SOU, got #{vrm}")
     end
   end
   ```

2. **Multiple Results Warning:** Log a warning if more than one result is returned
   ```elixir
   case results do
     [car] -> {:ok, car}  # Expected: exactly one
     [car | rest] -> 
       Logger.warning("Multiple results returned (#{length(rest) + 1}), using first")
       {:ok, car}
     [] -> {:ok, nil}
   end
   ```

3. **Result Count Validation:** Alert if the count doesn't match expectations

## Test Execution
All 21 tests pass, covering:
- Multiple result handling (6 tests)
- Status extraction edge cases (4 tests)  
- Change detection logic (5 tests)
- Status code mapping (6 tests)

Run tests with: `mix test test/clickdealer_search/car_monitor_test.exs`
