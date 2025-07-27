local displayName = "RF Controller"
local energyDetector = peripheral.wrap("energy_detector_1")
local monitor = peripheral.wrap("monitor_3")

monitor.setTextScale(2)
monitor.setBackgroundColor(colors.blue)

while true do
    local power = energyDetector.getTransferRate()
    local text = displayName
    local powerText = power .. "RF/T"
    x, y = monitor.getSize()
    monitor.clear()
    monitor.setCursorPos(math.floor(1 + (x / 2) - (#text / 2)), math.floor(y / 2))
    monitor.write(text)
    monitor.setCursorPos(math.floor(1 + (x / 2) - (#powerText / 2)), 1 + math.floor(y / 2))
    monitor.write(powerText)
    sleep(1)
end