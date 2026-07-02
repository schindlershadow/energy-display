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