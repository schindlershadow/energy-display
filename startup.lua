local displayName = "RF Controller"
local energyDetector = peripheral.find("energy_detector")
while energyDetector == nil do
    print("energyDetector not found, please connect an energy detector and try again.")
    sleep(1)
end

local monitor = peripheral.find("monitor")
while monitor == nil do
    print("Monitor not found, please connect a monitor and try again.")
    monitor = peripheral.find("monitor")
    sleep(1)
end

monitor.setTextScale(2)
monitor.setBackgroundColor(colors.blue)

local function formatPower(value)
    local absValue = math.abs(value)
    local units = {
        {suffix = "RF/T", factor = 1},
        {suffix = "kRF/T", factor = 1e3},
        {suffix = "mRF/T", factor = 1e6},
        {suffix = "gRF/T", factor = 1e9},
        {suffix = "tRF/T", factor = 1e12},
    }

    local selected = units[1]
    for i = 1, #units do
        if absValue >= units[i].factor then
            selected = units[i]
        else
            break
        end
    end

    local scaled = value / selected.factor
    local formatted = string.format("%.1f", scaled)
    if formatted:match("%.0$") then
        formatted = formatted:sub(1, -3)
    end

    return formatted .. selected.suffix
end

while true do
    local power = energyDetector.getTransferRate()
    local text = displayName
    local powerText = formatPower(power)
    x, y = monitor.getSize()
    monitor.clear()
    monitor.setCursorPos(math.floor(1 + (x / 2) - (#text / 2)), math.floor(y / 2))
    monitor.write(text)
    monitor.setCursorPos(math.floor(1 + (x / 2) - (#powerText / 2)), 1 + math.floor(y / 2))
    monitor.write(powerText)
    sleep(1)
end