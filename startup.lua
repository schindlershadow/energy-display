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

    return formatted, selected.suffix, scaled
end

local function chooseTextScale()
    monitor.setTextScale(1)
    local width, height = monitor.getSize()

    if width >= 60 and height >= 14 then
        local ok = pcall(monitor.setTextScale, 2)
        if ok then
            local scaleWidth, scaleHeight = monitor.getSize()
            if scaleWidth >= 32 and scaleHeight >= 10 then
                return 2, scaleWidth, scaleHeight
            end
        end
        monitor.setTextScale(1)
        return 1, width, height
    elseif width >= 24 and height >= 8 then
        return 1, width, height
    end

    local ok = pcall(monitor.setTextScale, 0.5)
    if ok then
        local scaleWidth, scaleHeight = monitor.getSize()
        return 0.5, scaleWidth, scaleHeight
    end

    return 1, width, height
end

local powerHistory = {}
local maxHistory = 30
local overallMax = 0

local function pushPower(value)
    table.insert(powerHistory, math.abs(value))
    if #powerHistory > maxHistory then
        table.remove(powerHistory, 1)
    end
    if math.abs(value) > overallMax then
        overallMax = math.abs(value)
    end
end

local function computeThresholds()
    if #powerHistory == 0 then
        local high = math.max(0, overallMax)
        return 0, 0, high, 0, overallMax
    end

    local sum = 0
    for _, value in ipairs(powerHistory) do
        sum = sum + value
    end

    local avg = sum / #powerHistory
    local maxValue = overallMax

    local low = math.max(0.1, avg * 0.35, maxValue * 0.12)
    local medium = math.max(low * 1.4, avg * 0.85, maxValue * 0.35)
    local high = math.max(maxValue, medium * 1.2, avg * 1.2)

    return low, medium, high, avg, maxValue
end

local function centerText(monitor, width, row, text, textColor, bgColor)
    monitor.setBackgroundColor(bgColor or colors.blue)
    monitor.setTextColor(textColor or colors.white)
    monitor.setCursorPos(math.floor((width - #text) / 2) + 1, row)
    monitor.write(text)
end

local textScale, monitorWidth, monitorHeight = chooseTextScale()
monitor.setTextScale(textScale)
monitor.clear()
monitor.setBackgroundColor(colors.blue)

while true do
    local power = energyDetector.getTransferRate()
    pushPower(power)
    local valueText, unitSuffix, scaledValue = formatPower(power)
    local displayText = valueText .. " " .. unitSuffix
    local width, height = monitorWidth, monitorHeight

    local lowThreshold, mediumThreshold, highThreshold, avgPower, maxPower = computeThresholds()
    local fillPercent = 0
    if highThreshold > 0 then
        fillPercent = math.min(math.max(power / highThreshold, 0), 1)
    end

    local barColor = colors.lime
    if power > mediumThreshold then
        barColor = colors.yellow
    end
    if power > highThreshold then
        barColor = colors.red
    end

    monitor.setBackgroundColor(colors.blue)
    monitor.clear()

    local titleRow = 2
    local valueRow = titleRow + 2
    local barRow = valueRow + 2
    local detailRow = barRow + 2
    local barWidth = math.max(10, width - 12)
    local barX = math.floor((width - barWidth) / 2) + 1

    centerText(monitor, width, titleRow, displayName, colors.yellow, colors.blue)
    centerText(monitor, width, valueRow, displayText, colors.white, colors.blue)
    centerText(monitor, width, detailRow, string.format("Raw: %s RF/T", tostring(power)), colors.lightGray, colors.blue)

    monitor.setBackgroundColor(colors.gray)
    monitor.setTextColor(colors.black)
    monitor.setCursorPos(barX, barRow)
    monitor.write(string.rep(" ", barWidth))

    if fillPercent > 0 then
        local fillWidth = math.floor(barWidth * fillPercent)
        monitor.setBackgroundColor(barColor)
        monitor.setTextColor(colors.black)
        monitor.setCursorPos(barX, barRow)
        monitor.write(string.rep(" ", fillWidth))
    end

    local barText = string.format("%d%%", math.floor(fillPercent * 100 + 0.5))
    if #barText < barWidth then
        centerText(monitor, width, barRow, barText, colors.black, colors.gray)
    end

    if height >= 12 then
        local thresholdsText = string.format("Low %s | Med %s | High %s",
            formatPower(lowThreshold),
            formatPower(mediumThreshold),
            formatPower(highThreshold)
        )
        centerText(monitor, width, detailRow + 1, thresholdsText, colors.lightGray, colors.blue)
    end

    sleep(1)
end