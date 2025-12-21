require "ISUI/ISPanel"

local iconUI = nil
local enduranceUI = nil

local CONFIG = {
    iconSize = 64,
    baseIconSize = 64,
    bottomOffset = 15,
    rightOffset = 15,
    arrowSize = 16,
    updateThreshold = 1.0,
    temperatureUpdateThreshold = 0.5,
    arrowDuration = 10000,
    separatorSize = 32,

    separatorOffsets = {
        [64] = { [1] = -7, [2] = -21 },
        [56] = { [1] = -6, [2] = -18 },
        [48] = { [1] = -5, [2] = -16 }
    },

    groups = {
        { icons = { "fatigue" },                         spacing = 0 },
        { icons = { "thirst", "hunger", "temperature" }, spacing = -5 },
        { icons = { "infection", "sickness", "health" }, spacing = 15 }
    },
    groupSpacing = { 15, 20 }
}

local ENDURANCE_CONFIG = {
    width = 256,
    height = 8,
    leftOffset = 20,
    bottomOffset = 40,
    iconSize = 32,
    iconSpacing = 10,
    textSpacing = 8,
    bgColor = { r = 51, g = 51, b = 51, a = 255 },
    barColors = {
        high = { r = 230, g = 230, b = 230, a = 255 },  -- > 75%
        medium = { r = 204, g = 204, b = 0, a = 255 },  -- <= 75%
        low = { r = 255, g = 102, b = 0, a = 255 },     -- <= 50%
        veryLow = { r = 255, g = 51, b = 51, a = 255 }, -- <= 25%
        critical = { r = 255, g = 0, b = 0, a = 255 }   -- <= 10%
    }
}

local STAT_NAMES = {
    fatigue = "Tooltip_SH_Fatigue",
    thirst = "Tooltip_SH_Thirst",
    hunger = "Tooltip_SH_Hunger",
    temperature = "Tooltip_SH_Temperature",
    infection = "Tooltip_SH_Infection",
    sickness = "Tooltip_SH_Sickness",
    health = "Tooltip_SH_Health",
    endurance = "Tooltip_SH_Endurance",
    weight = "Tooltip_SH_Weight"
}

local MOODLE_NAMES = {
    fatigue = "Moodles_tired",
    thirst = "Moodles_thirst",
    hunger = "Moodles_hungry",
    temperature_hot = "Moodles_hyperthermia",
    temperature_cold = "Moodles_hypothermia",
    infection = "Moodles_sick",
    sickness = "Moodles_sick",
    health = "Moodles_injured",
    endurance = "Moodles_endurance"
}

local TOOLTIP_CONFIG = {
    maxWidth = 300,
    padding = 8
}

local function delayedCallback(delay, func)
    local endTime = os.time() + delay
    local function check()
        if os.time() >= endTime then
            func(); Events.OnTick.Remove(check)
        end
    end
    Events.OnTick.Add(check)
end

local function checkHotbarCollision()
    local hotbar = getPlayerHotbar(0)
    if not hotbar or not iconUI or not hotbar:getIsVisible() then
        return false
    end
    
    if hotbar:getWidth() <= 0 or hotbar:getHeight() <= 0 then
        return false
    end
    
    local hotbarX = hotbar:getAbsoluteX()
    local hotbarY = hotbar:getAbsoluteY()
    local hotbarWidth = hotbar:getWidth()
    local hotbarHeight = hotbar:getHeight()
    
    local iconX = iconUI:getAbsoluteX()
    local iconY = iconUI:getAbsoluteY()
    local iconWidth = iconUI:getWidth()
    local iconHeight = CONFIG.iconSize
    
    return not (iconX + iconWidth < hotbarX or
                iconX > hotbarX + hotbarWidth or
                iconY + iconHeight < hotbarY or
                iconY > hotbarY + hotbarHeight)
end

local function checkDashboardCollision()
    local player = getSpecificPlayer(0)
    if not player then return false end

    local dashboard = getPlayerVehicleDashboard(player:getPlayerNum())
    if not dashboard or not dashboard:getIsVisible() or dashboard:getWidth() <= 0 or dashboard:getHeight() <= 0 then
        return false
    end

    local vehicle = player:getVehicle()
    if not vehicle or not vehicle:isDriver(player) then
        return false
    end

    local dashX = dashboard:getAbsoluteX()
    local dashY = dashboard:getAbsoluteY()
    local dashWidth = dashboard:getWidth()
    local dashHeight = dashboard:getHeight()

    if iconUI then
        local iconX = iconUI:getAbsoluteX()
        local iconY = iconUI:getAbsoluteY()
        local iconWidth = iconUI:getWidth()
        local iconHeight = CONFIG.iconSize
        if not (iconX + iconWidth < dashX or
                iconX > dashX + dashWidth or
                iconY + iconHeight < dashY or
                iconY > dashY + dashHeight) then
            return true
        end
    end

    if enduranceUI then
        local enduranceX = enduranceUI:getAbsoluteX()
        local enduranceY = enduranceUI:getAbsoluteY()
        local enduranceWidth = enduranceUI:getWidth()
        local enduranceHeight = enduranceUI:getHeight()
        if not (enduranceX + enduranceWidth < dashX or
                enduranceX > dashX + dashWidth or
                enduranceY + enduranceHeight < dashY or
                enduranceY > dashY + dashHeight) then
            return true
        end
    end

    return false
end

local function adaptIconSize()
    if not iconUI then return end

    local originalSize = CONFIG.iconSize
    CONFIG.iconSize = CONFIG.baseIconSize

    iconUI.dimensions = nil
    iconUI:updatePosition()

    local hotbar = getPlayerHotbar(0)
    local shouldCheckHotbarCollision = hotbar and hotbar:getIsVisible() and hotbar:getWidth() > 0 and hotbar:getHeight() > 0

    local player = getSpecificPlayer(0)
    local dashboard = getPlayerVehicleDashboard(0)
    local shouldCheckDashboard = player and player:getVehicle() and player:getVehicle():isDriver(player) and dashboard and dashboard:getIsVisible() and dashboard:getWidth() > 0 and dashboard:getHeight() > 0

    if shouldCheckHotbarCollision and checkHotbarCollision() then
        CONFIG.iconSize = 56
        iconUI.dimensions = nil
        iconUI:updatePosition()

        if checkHotbarCollision() then
            CONFIG.iconSize = 48
            iconUI.dimensions = nil
            iconUI:updatePosition()
        end
    end

    if shouldCheckDashboard and checkDashboardCollision() then
        if CONFIG.iconSize == 64 then
            CONFIG.iconSize = 56
        elseif CONFIG.iconSize == 56 then
            CONFIG.iconSize = 48
        end
        iconUI.dimensions = nil
        iconUI:updatePosition()
    end

    CONFIG.arrowSize = math.floor(CONFIG.iconSize * 0.25)
    CONFIG.separatorSize = math.floor(CONFIG.iconSize * 0.5)

    if originalSize ~= CONFIG.iconSize then
        iconUI.dimensions = nil
        iconUI.iconPositions = {}
        iconUI:updatePosition()
    end
end

local function getSeparatorOffset(groupIndex)
    local offsets = CONFIG.separatorOffsets[CONFIG.iconSize]
    return offsets and offsets[groupIndex] or 0
end

local function getScaleFactor()
    return CONFIG.iconSize / 64
end

local function wrapText(text, font, maxWidth)
    local lines = {}

    for paragraph in text:gmatch("[^\n]+") do
        if paragraph:trim() == "" then
            table.insert(lines, "")
        else
            local words = {}
            for word in paragraph:gmatch("%S+") do
                table.insert(words, word)
            end

            local currentLine = ""
            for _, word in ipairs(words) do
                local testLine = currentLine == "" and word or (currentLine .. " " .. word)
                local testWidth = getTextManager():MeasureStringX(font, testLine)

                if testWidth <= maxWidth then
                    currentLine = testLine
                else
                    if currentLine ~= "" then
                        table.insert(lines, currentLine)
                        currentLine = word
                    else
                        table.insert(lines, word)
                        currentLine = ""
                    end
                end
            end

            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
        end
    end

    return lines
end

local PHASES = {
    fatigue = {
        { 40, 100, 0, { 100, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45 } },
        { 30, 40,  1, { 40, 35 } },
        { 20, 30,  2, { 30, 25 } },
        { 10, 20,  3, { 20, 15 } },
        { 5,  10,  4, { 10, 5 } }
    },
    hunger = {
        { 85, 100, 0, { 100, 95, 90 } },
        { 75, 85,  1, { 85, 80 } },
        { 55, 75,  2, { 75, 70, 65, 60 } },
        { 30, 55,  3, { 55, 50, 45, 40, 35 } },
        { 0,  30,  4, { 30, 25, 20, 15, 10, 5 } }
    },
    thirst = {
        { 88, 100, 0, { 100, 95, 90 } },
        { 75, 88,  1, { 88, 85, 80 } },
        { 30, 75,  2, { 75, 70, 65, 60, 55, 50, 45, 40, 35 } },
        { 16, 30,  3, { 30, 25, 20 } },
        { 0,  16,  4, { 16, 10, 5 } }
    },
    temperature = {
        { 20,   25,   "-4", { 25 } },
        { 25,   30,   "-3", { 26.5, 27, 28, 29, 30 } },
        { 30,   35,   "-2", { 30.5, 31.5, 32, 33, 33.5, 34.5, 35 } },
        { 35,   36.5, "-1", { 36.5 } },
        { 36.5, 37.5, "+0", { 37 } },
        { 37.5, 39,   "+1", { 37.5, 38 } },
        { 39,   40,   "+2", { 39 } },
        { 40,   41,   "+3", { 40 } },
        { 41,   42,   "+4", { 41 } }
    },
    sickness = {
        { 0,  25,  0, { 0, 5, 10, 15, 20, 25 } },
        { 25, 50,  1, { 26, 30, 35, 40, 45, 50 } },
        { 50, 75,  2, { 51, 55, 60, 65, 70, 75 } },
        { 75, 90,  3, { 76, 80, 85, 90 } },
        { 90, 100, 4, { 91, 95, 100 } }
    },
    infection = {
        { 0,  25,  0, { 0, 5, 10, 15, 20, 25 } },
        { 25, 50,  1, { 26, 30, 35, 40, 45, 50 } },
        { 50, 75,  2, { 51, 55, 60, 65, 70, 75 } },
        { 75, 90,  3, { 76, 80, 85, 90 } },
        { 90, 100, 4, { 91, 95, 100 } }
    },
    health = {
        { 80, 100, 0, { 100, 95, 90, 85 } },
        { 60, 80,  1, { 80, 75, 70, 65 } },
        { 40, 60,  2, { 60, 55, 50, 45 } },
        { 25, 40,  3, { 40, 35, 30 } },
        { 0,  25,  4, { 25, 20, 15, 10, 5 } }
    }
}

local function celsiusToFahrenheit(celsius)
    if type(celsius) == "number" then
        local fahrenheit = celsius * 9 / 5 + 32
        return fahrenheit
    end
end

EnduranceBarUI = ISPanel:derive("EnduranceBarUI")

function EnduranceBarUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    o.runTextures = {}
    o.currentValues = {}

    return o
end

function EnduranceBarUI:initialise()
    ISPanel.initialise(self)
    self:setVisible(true)
    self:updatePosition()
    self:preloadRunTextures()
end

function EnduranceBarUI:preloadRunTextures()
    for i = 0, 4 do
        self.runTextures[i] = getTexture("media/textures/ui/needs/endurance/run-" .. i .. ".png")
    end
end

function EnduranceBarUI:updatePosition()
    local screenHeight = getCore():getScreenHeight()
    local scale = getScaleFactor()
    
    local scaledWidth = ENDURANCE_CONFIG.width * scale
    local scaledHeight = ENDURANCE_CONFIG.height * scale
    local scaledIconSize = ENDURANCE_CONFIG.iconSize * scale
    local scaledIconSpacing = ENDURANCE_CONFIG.iconSpacing * scale
    local scaledTextSpacing = ENDURANCE_CONFIG.textSpacing * scale
    
    local font = UIFont.Small
    local textWidth = getTextManager():MeasureStringX(font, "100%")
    
    local totalWidth = scaledIconSize + scaledIconSpacing + scaledWidth + scaledTextSpacing + textWidth
    
    local x = ENDURANCE_CONFIG.leftOffset
    local y = screenHeight - ENDURANCE_CONFIG.bottomOffset - scaledHeight
    
    self:setX(x)
    self:setY(y)
    self:setWidth(totalWidth)
    self:setHeight(math.max(scaledHeight, scaledIconSize))
end

function EnduranceBarUI:getEnduranceColor(endurancePercent)
    if endurancePercent <= 0.10 then
        return ENDURANCE_CONFIG.barColors.critical
    elseif endurancePercent <= 0.25 then
        return ENDURANCE_CONFIG.barColors.veryLow
    elseif endurancePercent <= 0.50 then
        return ENDURANCE_CONFIG.barColors.low
    elseif endurancePercent <= 0.75 then
        return ENDURANCE_CONFIG.barColors.medium
    else
        return ENDURANCE_CONFIG.barColors.high
    end
end

function EnduranceBarUI:getEndurancePhase(endurancePercent)
    if endurancePercent <= 0.10 then
        return 4
    elseif endurancePercent <= 0.25 then
        return 3
    elseif endurancePercent <= 0.50 then
        return 2
    elseif endurancePercent <= 0.75 then
        return 1
    else
        return 0
    end
end

function EnduranceBarUI:getTooltip()
    if self.currentValues.endurance then
        local statName = getText(STAT_NAMES.endurance)
        local value = math.floor(self.currentValues.endurance * 100 + 0.5)
        local phase = self:getEndurancePhase(self.currentValues.endurance)

        local tooltip = string.format("%s: %d%%", statName, value)

        if phase > 0 then
            local moodleName = getText(MOODLE_NAMES.endurance .. "_lvl" .. phase)
            local moodleDesc = getText(MOODLE_NAMES.endurance .. "_desc_lvl" .. phase)

            if moodleName and moodleDesc then
                tooltip = tooltip .. "\n" .. moodleDesc
            end
        end

        return tooltip
    end
    return nil
end

function EnduranceBarUI:render()
    ISPanel.render(self)
    
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then
        self:setVisible(false)
        return
    end
    
    self:setVisible(true)
    
    local stats = player:getStats()
    if not stats then return end
    
    local endurance = stats:getEndurance()
    self.currentValues.endurance = endurance
    
    local scale = getScaleFactor()
    local scaledWidth = ENDURANCE_CONFIG.width * scale
    local scaledHeight = ENDURANCE_CONFIG.height * scale
    local scaledIconSize = ENDURANCE_CONFIG.iconSize * scale
    local scaledIconSpacing = ENDURANCE_CONFIG.iconSpacing * scale
    local scaledTextSpacing = ENDURANCE_CONFIG.textSpacing * scale
    
    local phase = self:getEndurancePhase(endurance)
    local runTexture = self.runTextures[phase]
    if runTexture then
        local iconY = (self:getHeight() - scaledIconSize) / 2
        self:drawTextureScaled(runTexture, 0, iconY, scaledIconSize, scaledIconSize, 1, 1, 1, 1)
    end
    
    local barX = scaledIconSize + scaledIconSpacing
    local barY = (self:getHeight() - scaledHeight) / 2
    
    self:drawRect(barX, barY, scaledWidth, scaledHeight,
        ENDURANCE_CONFIG.bgColor.a / 255.0,
        ENDURANCE_CONFIG.bgColor.r / 255.0,
        ENDURANCE_CONFIG.bgColor.g / 255.0,
        ENDURANCE_CONFIG.bgColor.b / 255.0)
    
    local barWidth = math.max(0, scaledWidth * endurance)
    local barColor = self:getEnduranceColor(endurance)
    
    if barWidth > 0 then
        self:drawRect(barX, barY, barWidth, scaledHeight,
            barColor.a / 255.0,
            barColor.r / 255.0,
            barColor.g / 255.0,
            barColor.b / 255.0)
    end
    
    local percentageText = string.format("%d%%", math.floor(endurance * 100 + 0.5))
    local textX = barX + scaledWidth + scaledTextSpacing
    local textY = barY + (scaledHeight - getTextManager():getFontHeight(UIFont.Small)) / 2
    
    self:drawText(percentageText, textX + 1, textY + 1, 0, 0, 0, 0.75, UIFont.Small)
    
    self:drawText(percentageText, textX, textY,
        barColor.r / 255.0,
        barColor.g / 255.0,
        barColor.b / 255.0,
        barColor.a / 255.0,
        UIFont.Small)
    
    if self:isMouseOver() and not player:isAiming() then
        local tooltip = self:getTooltip()
        if tooltip then
            local mouseX = getMouseX()
            local mouseY = getMouseY()
            self:drawTooltip(mouseX, mouseY, tooltip)
        end
    end
end

function EnduranceBarUI:drawTooltip(x, y, text)
    local font = UIFont.Small
    local fontHeight = getTextManager():getFontHeight(font)

    local lines = {}
    local colorInfo = {}

    local parts = {}
    for part in text:gmatch("[^\n]+") do
        table.insert(parts, part)
    end

    local phaseColor = { 1, 1, 1 }
    if self.currentValues.endurance then
        local phase = self:getEndurancePhase(self.currentValues.endurance)
        local phaseColors = {
            [0] = { 1, 1, 1 },
            [1] = { 1, 1, 51 / 255 },
            [2] = { 1, 153 / 255, 51 / 255 },
            [3] = { 1, 126 / 255, 121 / 255 },
            [4] = { 1, 0, 0 }
        }
        phaseColor = phaseColors[phase] or { 1, 1, 1 }
    end

    if parts[1] then
        local wrappedLines = wrapText(parts[1], font, TOOLTIP_CONFIG.maxWidth - TOOLTIP_CONFIG.padding * 2)
        for _, line in ipairs(wrappedLines) do
            table.insert(lines, line)
            table.insert(colorInfo, phaseColor)
        end
    end

    for i = 2, #parts do
        local wrappedLines = wrapText(parts[i], font, TOOLTIP_CONFIG.maxWidth - TOOLTIP_CONFIG.padding * 2)
        for _, line in ipairs(wrappedLines) do
            table.insert(lines, line)
            table.insert(colorInfo, { 0.8, 0.8, 0.8 })
        end
    end

    local actualWidth = 0
    for _, line in ipairs(lines) do
        local lineWidth = getTextManager():MeasureStringX(font, line)
        if lineWidth > actualWidth then
            actualWidth = lineWidth
        end
    end

    local tooltipWidth = actualWidth + TOOLTIP_CONFIG.padding * 2
    local tooltipHeight = (#lines * fontHeight) + TOOLTIP_CONFIG.padding * 2

    local screenWidth = getCore():getScreenWidth()

    if x + tooltipWidth > screenWidth then
        x = screenWidth - tooltipWidth
    end
    if y - tooltipHeight < 0 then
        y = tooltipHeight
    end

    self:drawRect(x - self:getAbsoluteX(), y - tooltipHeight - self:getAbsoluteY(),
        tooltipWidth, tooltipHeight, 0.9, 0.1, 0.1, 0.1)

    self:drawRectBorder(x - self:getAbsoluteX(), y - tooltipHeight - self:getAbsoluteY(),
        tooltipWidth, tooltipHeight, 1.0, 0.7, 0.7, 0.7)

    for i, line in ipairs(lines) do
        local lineY = y - tooltipHeight - self:getAbsoluteY() + TOOLTIP_CONFIG.padding + ((i - 1) * fontHeight)
        local color = colorInfo[i]

        self:drawText(line, x - self:getAbsoluteX() + TOOLTIP_CONFIG.padding, lineY, color[1], color[2], color[3], 1,
            font)
    end
end

function EnduranceBarUI:update()
    ISPanel.update(self)
end

function EnduranceBarUI:onMouseDown() return false end

function EnduranceBarUI:onRightMouseDown() return false end

function EnduranceBarUI:onMouseMove() return false end

IconHungerThirstUI = ISPanel:derive("IconHungerThirstUI")

function IconHungerThirstUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    o.textureCache = {}
    o.icons = {}
    o.lastUpdate = 0
    o.dimensions = nil
    o.iconPositions = {}
    o.currentValues = {}
    o.lastVisibilityState = nil

    for _, group in ipairs(CONFIG.groups) do
        for _, iconType in ipairs(group.icons) do
            o.icons[iconType] = {
                phase = -1,
                textureValue = iconType == "infection" and 0 or (iconType == "temperature" and 37 or 100),
                lastValue = -1,
                arrow = { visible = false, direction = "up", time = 0 }
            }
        end
    end

    return o
end

function IconHungerThirstUI:initialise()
    ISPanel.initialise(self)
    self:setVisible(true)
    self:updatePosition()
    self:preloadTextures()
end

function IconHungerThirstUI:preloadTextures()
    for iconType, phases in pairs(PHASES) do
        local isTemperature = iconType == "temperature"

        for _, phase in ipairs(phases) do
            local bgSuffix = isTemperature and phase[3] or phase[3]
            local bgKey = iconType .. "_bg_" .. bgSuffix
            local bgPath = "media/textures/ui/needs/" .. iconType .. "/" ..
                (isTemperature and ("background" .. bgSuffix) or ("background-" .. bgSuffix)) .. ".png"
            self.textureCache[bgKey] = getTexture(bgPath)

            for _, value in ipairs(phase[4]) do
                local textureKey = iconType .. "_" .. value
                self.textureCache[textureKey] = getTexture("media/textures/ui/needs/" ..
                    iconType .. "/" .. value .. ".png")
            end
        end
    end

    self.textureCache.arrow_up = getTexture("media/textures/ui/arrow_up.png")
    self.textureCache.arrow_down = getTexture("media/textures/ui/arrow_down.png")
    self.textureCache.separator = getTexture("media/textures/ui/separator.png")
end

function IconHungerThirstUI:calculateDimensions()
    local player = getSpecificPlayer(0)
    if not player then return self.dimensions or { groupWidths = {}, totalWidth = 0, totalHeight = CONFIG.iconSize } end

    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    if not stats or not bodyDamage then return self.dimensions or
        { groupWidths = {}, totalWidth = 0, totalHeight = CONFIG.iconSize } end

    local infectionLevel = math.max(bodyDamage:getInfectionLevel() or 0, bodyDamage:getFakeInfectionLevel() or 0)
    local sicknessLevel = stats:getSickness()

    local showInfection = infectionLevel > 0
    local showSickness = sicknessLevel > 0

    local totalWidth = 0
    local groupWidths = {}
    local hasVisibleGroups = {}

    for i, group in ipairs(CONFIG.groups) do
        local visibleIcons = {}

        for _, iconType in ipairs(group.icons) do
            local shouldShow = true

            if iconType == "infection" and not showInfection then
                shouldShow = false
            elseif iconType == "sickness" and not showSickness then
                shouldShow = false
            end

            if shouldShow then
                table.insert(visibleIcons, iconType)
            end
        end

        hasVisibleGroups[i] = #visibleIcons > 0

        if hasVisibleGroups[i] then
            local width = #visibleIcons * CONFIG.iconSize + math.max(0, (#visibleIcons - 1) * group.spacing)
            groupWidths[i] = width
            totalWidth = totalWidth + width
        else
            groupWidths[i] = 0
        end
    end

    for i = 1, #CONFIG.groups - 1 do
        if hasVisibleGroups[i] then
            local hasNextVisibleGroup = false
            for j = i + 1, #CONFIG.groups do
                if hasVisibleGroups[j] then
                    hasNextVisibleGroup = true
                    break
                end
            end

            if hasNextVisibleGroup and CONFIG.groupSpacing[i] then
                totalWidth = totalWidth + CONFIG.groupSpacing[i]
            end
        end
    end

    local oldDimensions = self.dimensions
    local newDimensions = {
        groupWidths = groupWidths,
        totalWidth = totalWidth,
        totalHeight = CONFIG.iconSize,
        showInfection = showInfection,
        showSickness = showSickness,
        hasVisibleGroups = hasVisibleGroups
    }

    local dimensionsChanged = false
    if not oldDimensions or oldDimensions.totalWidth ~= newDimensions.totalWidth then
        dimensionsChanged = true
    end

    self.dimensions = newDimensions

    if dimensionsChanged then
        self:setWidth(newDimensions.totalWidth)
        self:updatePosition()
    end

    return self.dimensions
end

function IconHungerThirstUI:updatePosition()
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local dimensions = self:calculateDimensions()

    local x = screenWidth - dimensions.totalWidth - CONFIG.rightOffset
    local y = screenHeight - CONFIG.bottomOffset - CONFIG.iconSize

    self:setX(x)
    self:setY(y)
    self:setWidth(dimensions.totalWidth)
    self:setHeight(dimensions.totalHeight)

    self.iconPositions = {}
end

function IconHungerThirstUI:getPhaseData(value, iconType)
    for _, phase in ipairs(PHASES[iconType]) do
        if value >= phase[1] and value <= phase[2] then
            return phase
        end
    end
    return PHASES[iconType][#PHASES[iconType]]
end

function IconHungerThirstUI:getBestTexture(value, iconType, currentTextureValue)
    if (iconType == "infection" and value <= 0) or (iconType == "sickness" and value <= 0) or
        (iconType ~= "infection" and iconType ~= "sickness" and iconType ~= "temperature" and iconType ~= "fatigue" and value <= 0) then
        return nil
    end

    if iconType == "fatigue" and value <= 0 then
        return nil
    end

    local threshold = iconType == "temperature" and CONFIG.temperatureUpdateThreshold or CONFIG.updateThreshold

    if currentTextureValue ~= -1 and math.abs(value - currentTextureValue) < threshold then
        local phaseData = self:getPhaseData(value, iconType)
        for _, textureValue in ipairs(phaseData[4]) do
            if textureValue == currentTextureValue then
                return currentTextureValue
            end
        end
    end

    local phaseData = self:getPhaseData(value, iconType)
    local textures = phaseData[4]

    if #textures == 0 then
        return iconType == "temperature" and 37 or nil
    end

    local best = textures[1]
    local minDiff = math.abs(value - best)

    for _, texture in ipairs(textures) do
        local diff = math.abs(value - texture)
        if diff < minDiff then
            minDiff = diff
            best = texture
        end
    end

    return best
end

function IconHungerThirstUI:updateArrow(icon, currentValue, iconType)
    local currentTime = getTimestampMs()

    if currentValue ~= icon.lastValue and icon.lastValue ~= -1 then
        icon.arrow.visible = true
        icon.arrow.time = currentTime
        icon.arrow.direction = currentValue > icon.lastValue and "up" or "down"
    end

    local hideConditions = {
        infection = currentValue <= 0,
        sickness = currentValue <= 0,
        temperature = currentValue >= 36.55 and currentValue <= 37.45,
        fatigue = currentValue >= 99,
        hunger = currentValue >= 99,
        thirst = currentValue >= 99,
        health = currentValue >= 99
    }

    local hideCondition = hideConditions[iconType] or currentValue >= 99

    if icon.arrow.visible and ((currentTime - icon.arrow.time) >= CONFIG.arrowDuration or hideCondition) then
        icon.arrow.visible = false
    end

    icon.lastValue = currentValue
end

function IconHungerThirstUI:getTooltipForIcon(iconType, value)
    local statName, tooltip = getText(STAT_NAMES[iconType]) or iconType, nil

    if iconType == "temperature" then
        if not getCore():getOptionDisplayAsCelsius() then
            tooltip = string.format("%s: %.1f F.", statName, celsiusToFahrenheit(value))
        else
            tooltip = string.format("%s: %.1f C.", statName, value)
        end
    else
        if (iconType == "infection" or iconType == "sickness") and value <= 0 then
            tooltip = string.format("%s: %s.", statName, getText("Tooltip_SH_None") or "None.")
        else
            tooltip = string.format("%s: %d%%", statName, value)
        end
    end

    if iconType == "hunger" then
        local player = getSpecificPlayer(0)
        if player and player:getNutrition() then
            local nutrition = player:getNutrition()
            local weight = nutrition:getWeight()

            local weightName = getText(STAT_NAMES.weight) or "Weight"
            tooltip = tooltip ..
            string.format("\n%s: %.1f %s", weightName, weight, getText("Tooltip_SH_Weight_Value") or "kg.")
            
            if nutrition:isIncWeight() or nutrition:isIncWeightLot() or nutrition:isDecWeight() then
                self.weightArrowInfo = {
                    isIncWeight = nutrition:isIncWeight() and not nutrition:isIncWeightLot(),
                    isIncWeightLot = nutrition:isIncWeightLot(),
                    isDecWeight = nutrition:isDecWeight()
                }
            else
                self.weightArrowInfo = nil
            end

            if player:HasTrait("Nutritionist") then
                local calories = nutrition:getCalories()
                local carbs = nutrition:getCarbohydrates()
                local lipids = nutrition:getLipids()
                local proteins = nutrition:getProteins()

                local caloriesName = getText("Tooltip_food_Calories") or "Calories"
                tooltip = tooltip .. string.format("\n%s: %.1f", caloriesName, calories)

                local carbsName = getText("Tooltip_food_Carbs") or "Carbs"
                tooltip = tooltip .. string.format("\n%s: %.1f", carbsName, carbs)

                local proteinsName = getText("Tooltip_food_Prots") or "Proteins"
                tooltip = tooltip .. string.format("\n%s: %.1f", proteinsName, proteins)

                local lipidsName = getText("Tooltip_food_Fat") or "Fats"
                tooltip = tooltip .. string.format("\n%s: %.1f", lipidsName, lipids)
            end
        end
    end

    local phaseData = self:getPhaseData(value, iconType)
    local phase = phaseData[3]

    local shouldAddPhaseInfo = false
    local moodleBaseName = ""

    if iconType == "temperature" then
        if phase == "+0" then
            shouldAddPhaseInfo = false
        elseif string.sub(phase, 1, 1) == "+" then
            shouldAddPhaseInfo = true
            moodleBaseName = MOODLE_NAMES.temperature_hot
        elseif string.sub(phase, 1, 1) == "-" then
            shouldAddPhaseInfo = true
            moodleBaseName = MOODLE_NAMES.temperature_cold
        end
    else
        if phase ~= 0 then
            shouldAddPhaseInfo = true
            moodleBaseName = MOODLE_NAMES[iconType]
        end
    end

    if shouldAddPhaseInfo and moodleBaseName then
        local levelSuffix = iconType == "temperature" and string.sub(phase, 2) or tostring(phase)
        local moodleName = getText(moodleBaseName .. "_lvl" .. levelSuffix)
        local moodleDesc = getText(moodleBaseName .. "_desc_lvl" .. levelSuffix)

        if moodleName and moodleDesc then
            if iconType == "hunger" then
                tooltip = tooltip .. "\n\n" .. moodleDesc
            else
                tooltip = tooltip .. "\n" .. moodleDesc
            end
        end
    end

    return tooltip
end

function IconHungerThirstUI:getIconAtPosition(x, y)
    local mouseX = x
    local mouseY = y

    for iconType, pos in pairs(self.iconPositions) do
        if mouseX >= pos.x and mouseX <= pos.x + CONFIG.iconSize and
            mouseY >= pos.y and mouseY <= pos.y + CONFIG.iconSize then
            return iconType
        end
    end

    return nil
end

function IconHungerThirstUI:drawIcon(x, y, iconType, value)
    local icon = self.icons[iconType]
    local phaseData = self:getPhaseData(value, iconType)

    self.iconPositions[iconType] = { x = x, y = y }

    local bgKey = iconType .. "_bg_" .. phaseData[3]
    local bgTexture = self.textureCache[bgKey]
    if bgTexture then
        self:drawTextureScaled(bgTexture, x, y, CONFIG.iconSize, CONFIG.iconSize, 1, 1, 1, 1)
    end

    local newTextureValue = self:getBestTexture(value, iconType, icon.textureValue)
    if newTextureValue then
        icon.textureValue = newTextureValue
        local stateTexture = self.textureCache[iconType .. "_" .. newTextureValue]
        if stateTexture then
            self:drawTextureScaled(stateTexture, x, y, CONFIG.iconSize, CONFIG.iconSize, 1, 1, 1, 1)
        end
    end

    if icon.arrow.visible then
        local arrowTexture = self.textureCache["arrow_" .. icon.arrow.direction]
        if arrowTexture then
            local arrowX = x + (CONFIG.iconSize - CONFIG.arrowSize) / 2
            local arrowY = icon.arrow.direction == "up" and (y - CONFIG.arrowSize + 5.25) or (y + CONFIG.iconSize - 5.25)
            self:drawTextureScaled(arrowTexture, arrowX, arrowY, CONFIG.arrowSize, CONFIG.arrowSize, 1, 1, 1, 1)
        end
    end
end

function IconHungerThirstUI:drawTooltip(x, y, text)
    local font = UIFont.Small
    local fontHeight = getTextManager():getFontHeight(font)

    local lines = {}
    local colorInfo = {}

    local parts = {}
    local currentPos = 1
    while currentPos <= #text do
        local nextNewline = text:find("\n", currentPos)
        if nextNewline then
            local part = text:sub(currentPos, nextNewline - 1)
            table.insert(parts, part)
            currentPos = nextNewline + 1
        else
            local part = text:sub(currentPos)
            if part ~= "" then
                table.insert(parts, part)
            end
            break
        end
    end

    local phaseColor = { 1, 1, 1 }
    local mouseX = getMouseX()
    local mouseY = getMouseY()
    local relativeX = mouseX - self:getAbsoluteX()
    local relativeY = mouseY - self:getAbsoluteY()
    local hoveredIcon = self:getIconAtPosition(relativeX, relativeY)

    if hoveredIcon and self.currentValues[hoveredIcon] then
        local value = self.currentValues[hoveredIcon]

        if hoveredIcon == "temperature" then
            local phaseData = self:getPhaseData(value, hoveredIcon)
            local phase = phaseData[3]
            local tempPhaseColors = {
                ["-4"] = { 135 / 255, 152 / 255, 192 / 255 },
                ["-3"] = { 23 / 255, 171 / 255, 221 / 255 },
                ["-2"] = { 111 / 255, 199 / 255, 234 / 255 },
                ["-1"] = { 158 / 255, 205 / 255, 232 / 255 },
                ["+0"] = { 1, 1, 1 },
                ["+1"] = { 1, 1, 51 / 255 },
                ["+2"] = { 1, 153 / 255, 51 / 255 },
                ["+3"] = { 1, 126 / 255, 121 / 255 },
                ["+4"] = { 1, 0, 0 }
            }
            phaseColor = tempPhaseColors[phase] or { 1, 1, 1 }
        else
            local phaseData = self:getPhaseData(value, hoveredIcon)
            local phase = phaseData[3]
            local generalPhaseColors = {
                [0] = { 1, 1, 1 },
                [1] = { 1, 1, 51 / 255 },
                [2] = { 1, 153 / 255, 51 / 255 },
                [3] = { 1, 126 / 255, 121 / 255 },
                [4] = { 1, 0, 0 }
            }
            phaseColor = generalPhaseColors[phase] or { 1, 1, 1 }
        end
    end

    if parts[1] then
        local wrappedLines = wrapText(parts[1], font, TOOLTIP_CONFIG.maxWidth - TOOLTIP_CONFIG.padding * 2)
        for _, line in ipairs(wrappedLines) do
            table.insert(lines, line)
            table.insert(colorInfo, phaseColor)
        end
    end

    for i = 2, #parts do
        local part = parts[i]
        if part == "" then
            table.insert(lines, "")
            table.insert(colorInfo, { 0.8, 0.8, 0.8 })
        else
            local wrappedLines = wrapText(part, font, TOOLTIP_CONFIG.maxWidth - TOOLTIP_CONFIG.padding * 2)
            for _, line in ipairs(wrappedLines) do
                table.insert(lines, line)
                table.insert(colorInfo, { 0.8, 0.8, 0.8 })
            end
        end
    end

    local actualWidth = 0
    local weightLineIndex = nil
    local hasWeightArrow = false
    
    if hoveredIcon == "hunger" and self.weightArrowInfo then
        hasWeightArrow = true
    end
    
    for i, line in ipairs(lines) do
        if line ~= "" then
            local lineWidth = getTextManager():MeasureStringX(font, line)
            if line:find("Weight:") or line:find(getText("Tooltip_SH_Weight") or "Weight") then
                weightLineIndex = i
                if hasWeightArrow then
                    local arrowTexture = nil
                    if self.weightArrowInfo.isIncWeightLot then
                        arrowTexture = getTexture("media/ui/chevron_double.png")
                    elseif self.weightArrowInfo.isIncWeight then
                        arrowTexture = getTexture("media/ui/chevron_up.png")
                    elseif self.weightArrowInfo.isDecWeight then
                        arrowTexture = getTexture("media/ui/chevron_down.png")
                    end
                    
                    if arrowTexture then
                        lineWidth = lineWidth + 5 + arrowTexture:getWidth()
                    end
                end
            end
            
            if lineWidth > actualWidth then
                actualWidth = lineWidth
            end
        end
    end

    local tooltipWidth = actualWidth + TOOLTIP_CONFIG.padding * 2
    local tooltipHeight = (#lines * fontHeight) + TOOLTIP_CONFIG.padding * 2

    local screenWidth = getCore():getScreenWidth()

    if x + tooltipWidth > screenWidth then
        x = screenWidth - tooltipWidth
    end
    if y - tooltipHeight < 0 then
        y = tooltipHeight
    end

    self:drawRect(x - self:getAbsoluteX(), y - tooltipHeight - self:getAbsoluteY(),
        tooltipWidth, tooltipHeight, 0.9, 0.1, 0.1, 0.1)

    self:drawRectBorder(x - self:getAbsoluteX(), y - tooltipHeight - self:getAbsoluteY(),
        tooltipWidth, tooltipHeight, 1.0, 0.7, 0.7, 0.7)

    for i, line in ipairs(lines) do
        local lineY = y - tooltipHeight - self:getAbsoluteY() + TOOLTIP_CONFIG.padding + ((i - 1) * fontHeight)
        local color = colorInfo[i]

        if line ~= "" then
            self:drawText(line, x - self:getAbsoluteX() + TOOLTIP_CONFIG.padding, lineY, color[1], color[2], color[3], 1,
                font)
            
            if i == weightLineIndex and self.weightArrowInfo and hoveredIcon == "hunger" then
                local textWidth = getTextManager():MeasureStringX(font, line)
                local arrowX = x - self:getAbsoluteX() + TOOLTIP_CONFIG.padding + textWidth + 5
                
                local arrowTexture = nil
                if self.weightArrowInfo.isIncWeightLot then
                    arrowTexture = getTexture("media/ui/chevron_double.png")
                elseif self.weightArrowInfo.isIncWeight then
                    arrowTexture = getTexture("media/ui/chevron_up.png")
                elseif self.weightArrowInfo.isDecWeight then
                    arrowTexture = getTexture("media/ui/chevron_down.png")
                end
                
                if arrowTexture then
                    local arrowWidth = arrowTexture:getWidth()
                    local arrowHeight = arrowTexture:getHeight()
                    
                    local arrowY = lineY + (fontHeight - arrowHeight) / 2
                    
                    self:drawTextureScaled(arrowTexture, arrowX, arrowY, arrowWidth, arrowHeight, 1, 1, 1, 1)
                end
            end
        end
    end
end

function IconHungerThirstUI:render()
    ISPanel.render(self)

    local player = getSpecificPlayer(0)
    if not player or player:isDead() then
        self:setVisible(false)
        return
    end

    self:setVisible(true)

    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    if not stats or not bodyDamage then return end

    local values = {
        fatigue = math.max(0, math.min(100, (1 - stats:getFatigue()) * 100)),
        thirst = math.max(0, math.min(100, (1 - stats:getThirst()) * 100)),
        hunger = math.max(0, math.min(100, (1 - stats:getHunger()) * 100)),
        temperature = player:getTemperature(),
        infection = math.max(0,
            math.min(100, math.max(bodyDamage:getInfectionLevel() or 0, bodyDamage:getFakeInfectionLevel() or 0))),
        sickness = math.max(0, math.min(100, (stats:getSickness() / 1) * 100)),
        health = math.max(0, math.min(100, bodyDamage:getHealth()))
    }

    local currentVisibilityState = {
        infection = values.infection > 0,
        sickness = values.sickness > 0
    }

    local needsRecalculation = not self.lastVisibilityState or
        self.lastVisibilityState.infection ~= currentVisibilityState.infection or
        self.lastVisibilityState.sickness ~= currentVisibilityState.sickness

    if needsRecalculation then
        self.lastVisibilityState = currentVisibilityState
        self.dimensions = nil
        self.iconPositions = {}
        self:updatePosition()
        if self.parent then
            self.parent:setDrawOrder(self, self.drawOrder or 0)
        end
    end

    self.currentValues = values

    for iconType, value in pairs(values) do
        self:updateArrow(self.icons[iconType], value, iconType)
    end

    local currentX = 0
    local dimensions = self.dimensions or self:calculateDimensions()
    local showInfection = values.infection > 0
    local showSickness = values.sickness > 0

    for i, group in ipairs(CONFIG.groups) do
        if dimensions.hasVisibleGroups[i] then
            local visibleIcons = {}

            for _, iconType in ipairs(group.icons) do
                if not ((iconType == "infection" and not showInfection) or 
                       (iconType == "sickness" and not showSickness)) then
                    table.insert(visibleIcons, iconType)
                end
            end

            if #visibleIcons > 0 then
                for j, iconType in ipairs(visibleIcons) do
                    local iconX = currentX + (j - 1) * (CONFIG.iconSize + group.spacing)
                    self:drawIcon(iconX, 0, iconType, values[iconType])
                end

                currentX = currentX + dimensions.groupWidths[i]

                if i < #CONFIG.groups then
                    local hasNextVisibleGroup = false
                    for j = i + 1, #CONFIG.groups do
                        if dimensions.hasVisibleGroups[j] then
                            hasNextVisibleGroup = true
                            break
                        end
                    end

                    if hasNextVisibleGroup and CONFIG.groupSpacing[i] then
                        local separatorOffset = getSeparatorOffset(i)
                        local separatorX = currentX + separatorOffset
                        local separatorY = (CONFIG.iconSize - CONFIG.separatorSize) / 2
                        local separatorTexture = self.textureCache.separator
                        
                        if separatorTexture then
                            self:drawTextureScaled(separatorTexture, separatorX, separatorY, 
                                CONFIG.separatorSize, CONFIG.separatorSize, 1, 1, 1, 1)
                        end
                        currentX = currentX + CONFIG.groupSpacing[i]
                    end
                end
            end
        end
    end

    if self:isMouseOver() and not player:isAiming() then
        local mouseX = getMouseX()
        local mouseY = getMouseY()
        local relativeX = mouseX - self:getAbsoluteX()
        local relativeY = mouseY - self:getAbsoluteY()

        local hoveredIcon = self:getIconAtPosition(relativeX, relativeY)
        if hoveredIcon and self.currentValues[hoveredIcon] then
            local shouldShowTooltip = not ((hoveredIcon == "infection" and not showInfection) or 
                                         (hoveredIcon == "sickness" and not showSickness))

            if shouldShowTooltip then
                local tooltip = self:getTooltipForIcon(hoveredIcon, self.currentValues[hoveredIcon])
                self:drawTooltip(mouseX, mouseY, tooltip)
            end
        end
    end
end

function IconHungerThirstUI:update()
    ISPanel.update(self)
end

function IconHungerThirstUI:onMouseDown() return false end

function IconHungerThirstUI:onRightMouseDown() return false end

function IconHungerThirstUI:onMouseMove() return false end

local function createIconUI()
    if iconUI then
        iconUI:removeFromUIManager()
    end

    iconUI = IconHungerThirstUI:new(0, 0, 100, 100)
    iconUI:initialise()
    iconUI:addToUIManager()
    
    delayedCallback(0.1, adaptIconSize)
end

local function createEnduranceUI()
    if enduranceUI then
        enduranceUI:removeFromUIManager()
    end

    enduranceUI = EnduranceBarUI:new(0, 0, ENDURANCE_CONFIG.width, ENDURANCE_CONFIG.height)
    enduranceUI:initialise()
    enduranceUI:addToUIManager()
end

local function onPlayerDeath(player)
    if player == getSpecificPlayer(0) then
        if iconUI then
            iconUI:setVisible(false)
        end
        if enduranceUI then
            enduranceUI:setVisible(false)
        end
    end
end

local function configSetup()
    local screenWidth = getCore():getScreenWidth()
    
    if screenWidth < 1650 then
        CONFIG.baseIconSize = 56
    else
        CONFIG.baseIconSize = 64
    end
    
    CONFIG.iconSize = CONFIG.baseIconSize
end

local function onResolutionChange()
    configSetup(); delayedCallback(0.1, adaptIconSize)
    if enduranceUI then
        enduranceUI:updatePosition()
    end
end

Events.OnGameStart.Add(function()
    if WaterMarkUI and WaterMarkUI.render then
        WaterMarkUI.render = function(self)
            ISPanel.render(self); self:setVisible(false)
        end
    end
end)

Events.OnGameStart.Add(configSetup)
Events.OnGameStart.Add(createIconUI)
Events.OnGameStart.Add(createEnduranceUI)

Events.OnCreatePlayer.Add(createIconUI)
Events.OnCreatePlayer.Add(createEnduranceUI)
Events.OnPlayerDeath.Add(onPlayerDeath)

Events.OnResolutionChange.Add(onResolutionChange)

Events.OnClothingUpdated.Add(function(character)
    if character == getSpecificPlayer(0) then
        delayedCallback(0.1, adaptIconSize)
    end
end)

Events.OnEnterVehicle.Add(function(character)
    if character == getSpecificPlayer(0) then
        delayedCallback(0.1, adaptIconSize)
    end
end)

Events.OnExitVehicle.Add(function(character)
    if character == getSpecificPlayer(0) then
        delayedCallback(0.1, adaptIconSize)
    end
end)

Events.OnSwitchVehicleSeat.Add(function(character)
    if character == getSpecificPlayer(0) then
        delayedCallback(0.1, adaptIconSize)
    end
end)