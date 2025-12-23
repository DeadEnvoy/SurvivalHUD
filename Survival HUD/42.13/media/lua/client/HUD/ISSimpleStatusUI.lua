require "ISUI/ISPanel"

ISSimpleStatusTooltip = ISPanel:derive("ISSimpleStatusTooltip")

function ISSimpleStatusTooltip:initialise()
    ISPanel.initialise(self); self:instantiate()
    self.javaObject:setConsumeMouseEvents(false)
    
    self.backgroundColor = {r=0.9, g=0.1, b=0.1, a=0.1}
    self.borderColor = {r=1, g=0.7, b=0.7, a=0.7}
    
    self.currentOwner = nil
end

function ISSimpleStatusTooltip:updateData(text, type, currentValues, weightArrowInfo)
    self.tooltipText = text
    self.iconType = type
    self.currentValues = currentValues
    self.weightArrowInfo = weightArrowInfo
    
    self:calculateLayout()
end

function ISSimpleStatusTooltip:calculateLayout()
    if not self.tooltipText then return end

    local mx, my = getMouseX(), getMouseY()
    local font, fh = UIFont.Small, getTextManager():getFontHeight(UIFont.Small)
    
    local lines = {}
    for line in string.gmatch(self.tooltipText, "[^\n]+") do
        table.insert(lines, line)
    end
    self.lines = lines
    
    local maxW = 0
    for _, line in ipairs(lines) do
        local w = getTextManager():MeasureStringX(font, line)
        if self.iconType == "hunger" and string.find(line, getText("Tooltip_HUD_Weight")) then
             if self.weightArrowInfo then
                 w = w + 20
             end
        end
        if w > maxW then maxW = w end
    end
    
    local pad = 8
    local w, h = maxW + pad * 2, #lines * fh + pad * 2

    local rx = mx + 12
    local screenW = getCore():getScreenWidth()
    if rx + w > screenW then
        rx = mx - w - 12
        if rx < 0 then rx = screenW - w end
    end
    
    local ry = my - h - 12
    if ry < 0 then
        ry = my + 12
    end

    local screenH = getCore():getScreenHeight()
    if ry + h > screenH then
        ry = screenH - h
    end
    
    self:setX(rx); self:setY(ry)
    self:setWidth(w); self:setHeight(h)
end

function ISSimpleStatusTooltip:prerender()
    if not self.tooltipText then return end

    self:drawRect(0, 0, self.width, self.height, 0.9, 0.1, 0.1, 0.1)
    self:drawRectBorder(0, 0, self.width, self.height, 1, 0.7, 0.7, 0.7)
    
    local font = UIFont.Small
    local fh = getTextManager():getFontHeight(font)
    local pad = 8
    local cy = pad
    
    for i, line in ipairs(self.lines) do
        local r, g, b = 0.8, 0.8, 0.8
        
        if i == 1 then
             if self.iconType == "endurance" then
                 if ISEnduranceBarUI.instance then
                     local val = self.currentValues["endurance"]
                     local p = ISEnduranceBarUI.instance:getPhase(val)
                     
                     if p == 1 then r,g,b = 1,1,0.2
                     elseif p == 2 then r,g,b = 1,0.6,0.2
                     elseif p == 3 then r,g,b = 1,0.5,0.47
                     elseif p == 4 then r,g,b = 1,0,0
                     else r,g,b = 1,1,1 end
                 end
             else
                 local phase = ISSimpleStatusUI.instance:getPhaseData(self.currentValues[self.iconType], self.iconType)
                 if phase then
                     local p = phase[3]
                     if self.iconType ~= "temperature" then
                         if p == 1 then r,g,b = 1,1,0.2
                         elseif p == 2 then r,g,b = 1,0.6,0.2
                         elseif p == 3 then r,g,b = 1,0.5,0.47
                         elseif p == 4 then r,g,b = 1,0,0
                         else r,g,b = 1,1,1 end
                     else
                         local tmap = {["-4"]={0.5,0.6,0.75}, ["-3"]={0.1,0.67,0.86}, ["-2"]={0.43,0.78,0.91}, ["-1"]={0.62,0.8,0.9}, ["+0"]={1,1,1}, ["+1"]={1,1,0.2}, ["+2"]={1,0.6,0.2}, ["+3"]={1,0.5,0.47}, ["+4"]={1,0,0}}
                         local c = tmap[p] or {1,1,1}
                         r,g,b = c[1],c[2],c[3]
                     end
                 end
             end
        end
        
        self:drawText(line, pad, cy, r, g, b, 1, font)
        
        if self.iconType == "hunger" and string.find(line, getText("Tooltip_HUD_Weight")) and self.weightArrowInfo then
            local tex = nil
            if self.weightArrowInfo.isIncWeightLot then tex = ISSimpleStatusUI.instance.textures.chevronDouble
            elseif self.weightArrowInfo.isIncWeight then tex = ISSimpleStatusUI.instance.textures.chevronUp
            elseif self.weightArrowInfo.isDecWeight then tex = ISSimpleStatusUI.instance.textures.chevronDown end
            
            if tex then
                local tw = getTextManager():MeasureStringX(font, line)
                self:drawTextureScaled(tex, pad + tw + 5, cy + (fh - tex:getHeight())/2, tex:getWidth(), tex:getHeight(), 1, 1, 1, 1)
            end
        end
        
        cy = cy + fh
    end
end

function ISSimpleStatusTooltip:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self); self.__index = self
    o:setAlwaysOnTop(true)
    return o
end


ISSimpleStatusUI = ISPanel:derive("ISSimpleStatusUI")
ISEnduranceBarUI = ISPanel:derive("ISEnduranceBarUI")

ISSimpleStatusUI.instance = nil
ISEnduranceBarUI.instance = nil

ISSimpleStatusUI.IconSize = 64
ISSimpleStatusUI.BaseIconSize = 64
ISSimpleStatusUI.BottomOffset = 15
ISSimpleStatusUI.RightOffset = 15
ISSimpleStatusUI.ArrowSize = 16
ISSimpleStatusUI.UpdateThreshold = 1.0
ISSimpleStatusUI.TempUpdateThreshold = 0.5
ISSimpleStatusUI.ArrowDuration = 10000
ISSimpleStatusUI.SeparatorSize = 32
ISSimpleStatusUI.SkipRender = 0 

ISSimpleStatusUI.Phases = {
    fatigue = {
        { 40, 100, 0, { 100, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45 } },
        { 30, 40, 1, { 40, 35 } },
        { 20, 30, 2, { 30, 25 } },
        { 10, 20, 3, { 20, 15 } },
        { 5, 10, 4, { 10, 5 } }
    },
    hunger = {
        { 85, 100, 0, { 100, 95, 90 } },
        { 75, 85, 1, { 85, 80 } },
        { 55, 75, 2, { 75, 70, 65, 60 } },
        { 30, 55, 3, { 55, 50, 45, 40, 35 } },
        { 0, 30, 4, { 30, 25, 20, 15, 10, 5 } }
    },
    thirst = {
        { 88, 100, 0, { 100, 95, 90 } },
        { 75, 88, 1, { 88, 85, 80 } },
        { 30, 75, 2, { 75, 70, 65, 60, 55, 50, 45, 40, 35 } },
        { 16, 30, 3, { 30, 25, 20 } },
        { 0, 16, 4, { 16, 10, 5 } }
    },
    temperature = {
        { 20, 25, "-4", { 25 } },
        { 25, 30, "-3", { 26.5, 27, 28, 29, 30 } },
        { 30, 35, "-2", { 30.5, 31.5, 32, 33, 33.5, 34.5, 35 } },
        { 35, 36.5, "-1", { 36.5 } },
        { 36.5, 37.5, "+0", { 37 } },
        { 37.5, 39, "+1", { 37.5, 38 } },
        { 39, 40, "+2", { 39 } },
        { 40, 41, "+3", { 40 } },
        { 41, 42, "+4", { 41 } }
    },
    sickness = {
        { 0, 25, 0, { 0, 5, 10, 15, 20, 25 } },
        { 25, 50, 1, { 26, 30, 35, 40, 45, 50 } },
        { 50, 75, 2, { 51, 55, 60, 65, 70, 75 } },
        { 75, 90, 3, { 76, 80, 85, 90 } },
        { 90, 100, 4, { 91, 95, 100 } }
    },
    infection = {
        { 0, 25, 0, { 0, 5, 10, 15, 20, 25 } },
        { 25, 50, 1, { 26, 30, 35, 40, 45, 50 } },
        { 50, 75, 2, { 51, 55, 60, 65, 70, 75 } },
        { 75, 90, 3, { 76, 80, 85, 90 } },
        { 90, 100, 4, { 91, 95, 100 } }
    },
    health = {
        { 80, 100, 0, { 100, 95, 90, 85 } },
        { 60, 80, 1, { 80, 75, 70, 65 } },
        { 40, 60, 2, { 60, 55, 50, 45 } },
        { 25, 40, 3, { 40, 35, 30 } },
        { 0, 25, 4, { 25, 20, 15, 10, 5 } }
    }
}

ISSimpleStatusUI.Groups = {
    { icons = { "fatigue" }, spacing = 0 },
    { icons = { "thirst", "hunger", "temperature" }, spacing = -5 },
    { icons = { "infection", "sickness", "health" }, spacing = 15 }
}

ISSimpleStatusUI.GroupSpacing = { 15, 20 }

function ISSimpleStatusUI:initialise()
    ISPanel.initialise(self)
    self:initTextures()
    self:configSetup()
    
    self.tooltipUI = ISSimpleStatusTooltip:new(0, 0, 0, 0)
    self.tooltipUI:initialise()
    self.tooltipUI:addToUIManager()
    self.tooltipUI:setVisible(false)
end

function ISSimpleStatusUI:configSetup()
    local sw = getCore():getScreenWidth()
    if sw < 1650 then
        ISSimpleStatusUI.BaseIconSize = 56
    else
        ISSimpleStatusUI.BaseIconSize = 64
    end
    ISSimpleStatusUI.IconSize = ISSimpleStatusUI.BaseIconSize
    self.layoutDirty = true
end

function ISSimpleStatusUI:initTextures()
    self.textures = {}
    for type, phases in pairs(ISSimpleStatusUI.Phases) do
        local isTemp = (type == "temperature")
        for _, phase in ipairs(phases) do
            local bgSuffix = phase[3]
            local bgKey = type .. "_bg_" .. bgSuffix
            local bgPath = "media/ui/Needs/" .. type .. "/" .. (isTemp and ("background" .. bgSuffix) or ("background-" .. bgSuffix)) .. ".png"
            self.textures[bgKey] = getTexture(bgPath)
            for _, val in ipairs(phase[4]) do
                local texKey = type .. "_" .. val
                self.textures[texKey] = getTexture("media/ui/Needs/" .. type .. "/" .. val .. ".png")
            end
        end
    end
    self.textures.arrowUp = getTexture("media/ui/arrow_up.png")
    self.textures.arrowDown = getTexture("media/ui/arrow_down.png")
    self.textures.separator = getTexture("media/ui/separator.png")
    self.textures.chevronUp = getTexture("media/ui/chevron_up.png")
    self.textures.chevronDown = getTexture("media/ui/chevron_down.png")
    self.textures.chevronDouble = getTexture("media/ui/chevron_double.png")
end

function ISSimpleStatusUI:getPhaseData(val, type)
    if not ISSimpleStatusUI.Phases[type] then return nil end
    for _, phase in ipairs(ISSimpleStatusUI.Phases[type]) do
        if val >= phase[1] and val <= phase[2] then
            return phase
        end
    end
    return ISSimpleStatusUI.Phases[type][#ISSimpleStatusUI.Phases[type]]
end

function ISSimpleStatusUI:getBestTexture(val, type, current)
    if (type == "infection" or type == "sickness") and val <= 0 then return nil end
    if (type ~= "infection" and type ~= "sickness" and type ~= "temperature" and type ~= "fatigue") and val <= 0 then return nil end
    if type == "fatigue" and val <= 0 then return nil end
    
    local threshold = (type == "temperature") and ISSimpleStatusUI.TempUpdateThreshold or ISSimpleStatusUI.UpdateThreshold
    if current ~= -1 and math.abs(val - current) < threshold then
        local phase = self:getPhaseData(val, type)
        if phase then
            for _, tVal in ipairs(phase[4]) do
                if tVal == current then return current end
            end
        end
    end
    
    local phase = self:getPhaseData(val, type)
    if not phase then return nil end
    
    local textures = phase[4]
    if #textures == 0 then return (type == "temperature" and 37 or nil) end
    
    local best = textures[1]
    local minDiff = math.abs(val - best)
    for _, tVal in ipairs(textures) do
        local diff = math.abs(val - tVal)
        if diff < minDiff then
            minDiff = diff
            best = tVal
        end
    end
    return best
end

function ISSimpleStatusUI:isIntersecting(x1, y1, w1, h1, x2, y2, w2, h2)
    return not (x1 + w1 < x2 or x2 + w2 < x1 or y1 + h1 < y2 or y2 + h2 < y1)
end

function ISSimpleStatusUI:checkUICollision(ui)
    if not ui then return false end
    if not ui:isReallyVisible() then return false end
    if ui:getWidth() <= 0 or ui:getHeight() <= 0 then return false end

    local x = ui:getAbsoluteX()
    local y = ui:getAbsoluteY()
    local w = ui:getWidth()
    local h = ui:getHeight()
    
    local myW = self:getWidth()
    local myH = ISSimpleStatusUI.IconSize
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local myX = sw - myW - ISSimpleStatusUI.RightOffset
    local myY = sh - ISSimpleStatusUI.BottomOffset - myH
    
    return self:isIntersecting(myX, myY, myW, myH, x, y, w, h)
end

function ISSimpleStatusUI:updateLayout(forceInfVis, forceSickVis)
    local player = getPlayer()
    if not player then return end
    
    if forceInfVis == nil then
        local body = player:getBodyDamage()
        forceInfVis = body:getApparentInfectionLevel() > 0
    end
    
    if forceSickVis == nil then
        local stats = player:getStats()
        forceSickVis = stats:get(CharacterStat.SICKNESS) > 0
    end
    
    local hotbar = getPlayerHotbar(player:getPlayerNum())
    local dash = getPlayerVehicleDashboard(player:getPlayerNum())
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(player:getPlayerNum()) or nil
    local vehicle = player:getVehicle()

    ISSimpleStatusUI.IconSize = ISSimpleStatusUI.BaseIconSize
    self:recalcDimensions(forceInfVis, forceSickVis)
    
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    
    self:setX(sw - self:getWidth() - ISSimpleStatusUI.RightOffset)
    self:setY(sh - ISSimpleStatusUI.BottomOffset - ISSimpleStatusUI.IconSize)
    
    local overlapUI = nil

    if vehicle and vehicle:isDriver(player) and pscDash then
        if self:checkUICollision(pscDash) then
            if ISSimpleStatusUI.IconSize == 64 then
                ISSimpleStatusUI.IconSize = 56
                self:recalcDimensions(forceInfVis, forceSickVis)
                self:setX(sw - self:getWidth() - ISSimpleStatusUI.RightOffset)
                self:setY(sh - ISSimpleStatusUI.BottomOffset - ISSimpleStatusUI.IconSize)
            end
            
            if self:checkUICollision(pscDash) then
                ISSimpleStatusUI.IconSize = 48
                self:recalcDimensions(forceInfVis, forceSickVis)
                self:setX(sw - self:getWidth() - ISSimpleStatusUI.RightOffset)
                self:setY(sh - ISSimpleStatusUI.BottomOffset - ISSimpleStatusUI.IconSize)
                
                if self:checkUICollision(pscDash) then
                    overlapUI = pscDash
                    ISSimpleStatusUI.IconSize = 56
                    self:recalcDimensions(forceInfVis, forceSickVis)
                end
            end
        end
    end

    if not overlapUI and vehicle and vehicle:isDriver(player) and dash then
        if self:checkUICollision(dash) then
            if ISSimpleStatusUI.IconSize == 64 then
                ISSimpleStatusUI.IconSize = 56
                self:recalcDimensions(forceInfVis, forceSickVis)
                self:setX(sw - self:getWidth() - ISSimpleStatusUI.RightOffset)
                self:setY(sh - ISSimpleStatusUI.BottomOffset - ISSimpleStatusUI.IconSize)
            end
            
            if self:checkUICollision(dash) then
                ISSimpleStatusUI.IconSize = 48
                self:recalcDimensions(forceInfVis, forceSickVis)
                self:setX(sw - self:getWidth() - ISSimpleStatusUI.RightOffset)
                self:setY(sh - ISSimpleStatusUI.BottomOffset - ISSimpleStatusUI.IconSize)
                
                if self:checkUICollision(dash) then
                    overlapUI = dash
                    ISSimpleStatusUI.IconSize = 56
                    self:recalcDimensions(forceInfVis, forceSickVis)
                end
            end
        end
    end

    if not overlapUI and hotbar then
        if self:checkUICollision(hotbar) then
            ISSimpleStatusUI.IconSize = 56
            self:recalcDimensions(forceInfVis, forceSickVis)
            self:setX(sw - self:getWidth() - ISSimpleStatusUI.RightOffset)
            self:setY(sh - ISSimpleStatusUI.BottomOffset - ISSimpleStatusUI.IconSize)
            
            if self:checkUICollision(hotbar) then
                ISSimpleStatusUI.IconSize = 48
                self:recalcDimensions(forceInfVis, forceSickVis)
                self:setX(sw - self:getWidth() - ISSimpleStatusUI.RightOffset)
                self:setY(sh - ISSimpleStatusUI.BottomOffset - ISSimpleStatusUI.IconSize)
                
                if self:checkUICollision(hotbar) then
                    overlapUI = hotbar
                    ISSimpleStatusUI.IconSize = 56
                    self:recalcDimensions(forceInfVis, forceSickVis)
                end
            end
        end
    end
    
    if overlapUI then
        self:setX((sw - self:getWidth()) / 2)
        self:setY(overlapUI:getAbsoluteY() - self:getHeight() - 20)
        
        if ISEnduranceBarUI.instance then
            if vehicle then
                ISEnduranceBarUI.instance:setVisible(false)
            else
                ISEnduranceBarUI.instance:setVisible(true)
                ISEnduranceBarUI.instance:setMinimalMode(true)
            end
        end
    else
        if ISEnduranceBarUI.instance then
            ISEnduranceBarUI.instance:setVisible(true)
            ISEnduranceBarUI.instance:setMinimalMode(false)
        end
    end
    
    ISSimpleStatusUI.ArrowSize = math.floor(ISSimpleStatusUI.IconSize * 0.25)
    ISSimpleStatusUI.SeparatorSize = math.floor(ISSimpleStatusUI.IconSize * 0.5)
    
    self.cachedHotbarVis = hotbar and hotbar:isReallyVisible()
    self.cachedDashVis = dash and dash:isReallyVisible()
    self.cachedPscDashVis = pscDash and pscDash:isReallyVisible()
end

function ISSimpleStatusUI:recalcDimensions(showInfection, showSickness)
    local totalW = 0
    local groupW = {}
    local visibleGroups = {}
    
    for i, group in ipairs(ISSimpleStatusUI.Groups) do
        local count = 0
        for _, type in ipairs(group.icons) do
            if (type ~= "infection" or showInfection) and (type ~= "sickness" or showSickness) then
                count = count + 1
            end
        end
        
        visibleGroups[i] = count > 0
        if count > 0 then
            local w = count * ISSimpleStatusUI.IconSize + math.max(0, (count - 1) * group.spacing)
            groupW[i] = w
            totalW = totalW + w
        else
            groupW[i] = 0
        end
    end
    
    for i = 1, #ISSimpleStatusUI.Groups - 1 do
        if visibleGroups[i] then
            local nextVis = false
            for j = i + 1, #ISSimpleStatusUI.Groups do
                if visibleGroups[j] then nextVis = true; break end
            end
            if nextVis and ISSimpleStatusUI.GroupSpacing[i] then
                totalW = totalW + ISSimpleStatusUI.GroupSpacing[i]
            end
        end
    end
    
    self:setWidth(totalW); self:setHeight(ISSimpleStatusUI.IconSize)
    
    self.groupWidths = groupW; self.visibleGroups = visibleGroups
end

function ISSimpleStatusUI:update()
    if self.layoutDirty then
        self:configSetup()
        self:updateLayout()
        self.layoutDirty = false
    end
end

function ISSimpleStatusUI:prerender()
    local player = getPlayer()
    if not player or player:isDead() then
        self:setVisible(false)
        return
    end
    self:setVisible(true)
end

function ISSimpleStatusUI:isMouseOverSelf()
    local mx, my = getMouseX(), getMouseY()
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    return mx >= ax and mx < ax + self:getWidth() and my >= ay and my < ay + self:getHeight()
end

function ISSimpleStatusUI:render()
    if ISSimpleStatusUI.SkipRender > 0 then
        ISSimpleStatusUI.SkipRender = ISSimpleStatusUI.SkipRender - 1
        return
    end

    local player = getPlayer()
    if not player then return end
    
    local hotbar = getPlayerHotbar(player:getPlayerNum())
    local dash = getPlayerVehicleDashboard(player:getPlayerNum())
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(player:getPlayerNum()) or nil
    
    local anyVisible = (hotbar and hotbar:isReallyVisible()) or (dash and dash:isReallyVisible()) or (pscDash and pscDash:isReallyVisible())
    if not anyVisible then
        return
    end

    local currentHotbarVis = hotbar and hotbar:isReallyVisible()
    local currentDashVis, currentPscDashVis = dash and dash:isReallyVisible(), pscDash and pscDash:isReallyVisible()
    
    if self.cachedHotbarVis ~= currentHotbarVis or self.cachedDashVis ~= currentDashVis or self.cachedPscDashVis ~= currentPscDashVis then
        self.layoutDirty = true
        self:updateLayout()
    end
    
    local isAiming = player:isAiming()
    local isMouseOver = self:isMouseOverSelf()
    if isAiming and isMouseOver then
        self.fade:setFadeIn(false)
    else
        self.fade:setFadeIn(true)
    end
    self.fade:update()
    local globalAlpha = self.fade:fraction()
    
    if globalAlpha <= 0 then return end
    
    local stats = player:getStats()
    local body = player:getBodyDamage()
    
    local vals = {
        fatigue = math.max(0, math.min(100, (1 - stats:get(CharacterStat.FATIGUE)) * 100)),
        thirst = math.max(0, math.min(100, (1 - stats:get(CharacterStat.THIRST)) * 100)),
        hunger = math.max(0, math.min(100, (1 - stats:get(CharacterStat.HUNGER)) * 100)),
        temperature = stats:get(CharacterStat.TEMPERATURE),
        infection = math.max(0, math.min(100, body:getApparentInfectionLevel())),
        sickness = math.max(0, math.min(100, (stats:get(CharacterStat.SICKNESS)) * 100)),
        health = math.max(0, math.min(100, body:getHealth()))
    }
    
    local infVis = vals.infection > 0
    local sickVis = vals.sickness > 0
    
    if self.lastInfVis ~= infVis or self.lastSickVis ~= sickVis then
        self.lastInfVis = infVis
        self.lastSickVis = sickVis
        self:updateLayout(infVis, sickVis)
    end
    
    self.currentValues = vals
    local time = getTimestampMs()
    
    for type, val in pairs(vals) do
        local icon = self.icons[type]
        if val ~= icon.lastVal and icon.lastVal ~= -1 then
            icon.arrow.vis = true
            icon.arrow.time = time
            icon.arrow.dir = (val > icon.lastVal) and "up" or "down"
        end
        
        local hide = false
        if type == "infection" or type == "sickness" then hide = val <= 0
        elseif type == "temperature" then hide = (val >= 36.55 and val <= 37.45)
        else hide = val >= 99 end
        
        if icon.arrow.vis and (time - icon.arrow.time >= ISSimpleStatusUI.ArrowDuration or hide) then
            icon.arrow.vis = false
        end
        icon.lastVal = val
    end
    
    local curX = 0
    self.iconPos = {}
    
    for i, group in ipairs(ISSimpleStatusUI.Groups) do
        if self.visibleGroups and self.visibleGroups[i] then
            local count = 0
            for _, type in ipairs(group.icons) do
                if (type ~= "infection" or infVis) and (type ~= "sickness" or sickVis) then
                    count = count + 1
                    local x = curX + (count - 1) * (ISSimpleStatusUI.IconSize + group.spacing)
                    self:drawStatusIcon(x, 0, type, vals[type], globalAlpha)
                end
            end
            
            curX = curX + self.groupWidths[i]
            
            if i < #ISSimpleStatusUI.Groups then
                local hasNext = false
                for j = i + 1, #ISSimpleStatusUI.Groups do
                    if self.visibleGroups[j] then hasNext = true; break end
                end
                
                if hasNext and ISSimpleStatusUI.GroupSpacing[i] then
                    local sepOff = 0
                    if ISSimpleStatusUI.IconSize == 64 then sepOff = (i==1 and -7 or -21)
                    elseif ISSimpleStatusUI.IconSize == 56 then sepOff = (i==1 and -6 or -18)
                    else sepOff = (i==1 and -5 or -16) end
                    
                    local sepX = curX + sepOff
                    local sepY = (ISSimpleStatusUI.IconSize - ISSimpleStatusUI.SeparatorSize) / 2
                    if self.textures.separator then
                        self:drawTextureScaled(self.textures.separator, sepX, sepY, ISSimpleStatusUI.SeparatorSize, ISSimpleStatusUI.SeparatorSize, globalAlpha, 1, 1, 1)
                    end
                    curX = curX + ISSimpleStatusUI.GroupSpacing[i]
                end
            end
        end
    end
    
    if globalAlpha > 0.9 and self:isMouseOverSelf() and not player:isAiming() then
        local mx = self:getMouseX()
        local my = self:getMouseY()
        for type, pos in pairs(self.iconPos) do
            if mx >= pos.x and mx <= pos.x + ISSimpleStatusUI.IconSize and my >= pos.y and my <= pos.y + ISSimpleStatusUI.IconSize then
                if not ((type == "infection" and not infVis) or (type == "sickness" and not sickVis)) then
                    self:prepareTooltip(type, vals[type])
                    self.tooltipUI.currentOwner = "icons"
                end
                break
            end
        end
    else
        if self.tooltipUI and self.tooltipUI.currentOwner == "icons" then
            self.tooltipUI:setVisible(false)
            self.tooltipUI.currentOwner = nil
        end
    end
end

function ISSimpleStatusUI:onMouseDown(x, y)
    if getPlayer():isAiming() then return false end return true
end

function ISSimpleStatusUI:onMouseUp(x, y)
    if getPlayer():isAiming() then return false end return true
end

function ISSimpleStatusUI:onRightMouseDown(x, y)
    if getPlayer():isAiming() then return false end return true
end

function ISSimpleStatusUI:onRightMouseUp(x, y)
    if getPlayer():isAiming() then return false end return true
end

function ISSimpleStatusUI:drawStatusIcon(x, y, type, val, alpha)
    local icon, phase = self.icons[type], self:getPhaseData(val, type)
    if not phase then return end

    self.iconPos[type] = { x = x, y = y }
    
    local bgKey = type .. "_bg_" .. phase[3]
    if self.textures[bgKey] then
        self:drawTextureScaled(self.textures[bgKey], x, y, ISSimpleStatusUI.IconSize, ISSimpleStatusUI.IconSize, alpha, 1, 1, 1)
    end
    
    local texVal = self:getBestTexture(val, type, icon.texVal)
    if texVal then
        icon.texVal = texVal
        local key = type .. "_" .. texVal; if self.textures[key] then
            self:drawTextureScaled(self.textures[key], x, y, ISSimpleStatusUI.IconSize, ISSimpleStatusUI.IconSize, alpha, 1, 1, 1)
        end
    end
    
    if icon.arrow.vis then
        local key = (icon.arrow.dir == "up") and "arrowUp" or "arrowDown"
        if self.textures[key] then
            local ax = x + (ISSimpleStatusUI.IconSize - ISSimpleStatusUI.ArrowSize) / 2
            local ay = (icon.arrow.dir == "up") and (y - ISSimpleStatusUI.ArrowSize + 5.25) or (y + ISSimpleStatusUI.IconSize - 5.25)
            self:drawTextureScaled(self.textures[key], ax, ay, ISSimpleStatusUI.ArrowSize, ISSimpleStatusUI.ArrowSize, alpha, 1, 1, 1)
        end
    end
end

function ISSimpleStatusUI:prepareTooltip(type, val)
    local title = getText("Tooltip_HUD_" .. string.gsub(" "..type, "%W%l", string.upper):sub(2))
    if not title then title = type end
    
    local desc = ""
    if type == "temperature" then
        if getCore():getOptionDisplayAsCelsius() then
            desc = string.format("%s: %.1f C.", title, val)
        else
            desc = string.format("%s: %.1f F.", title, val * 9 / 5 + 32)
        end
    else
        if (type == "infection" or type == "sickness") and val <= 0 then
            desc = string.format("%s: %s.", title, getText("Tooltip_HUD_None"))
        else
            desc = string.format("%s: %d%%", title, val)
        end
    end
    
    local weightArrowInfo = nil
    
    if type == "hunger" then
        local player, nutrition = getPlayer(), getPlayer():getNutrition(); local weight = nutrition:getWeight()
        
        desc = desc .. string.format("\n%s: %.1f %s", getText("Tooltip_HUD_Weight"), weight, getText("Tooltip_HUD_Weight_Value"))
        
        if nutrition:isIncWeight() or nutrition:isIncWeightLot() or nutrition:isDecWeight() then
            weightArrowInfo = {
                isIncWeight = nutrition:isIncWeight() and not nutrition:isIncWeightLot(),
                isIncWeightLot = nutrition:isIncWeightLot(),
                isDecWeight = nutrition:isDecWeight()
            }
        end
        
        if player:hasTrait(CharacterTrait.NUTRITIONIST) then
            desc = desc .. string.format("\n%s: %.1f", getText("Tooltip_food_Calories"), nutrition:getCalories())
            desc = desc .. string.format("\n%s: %.1f", getText("Tooltip_food_Carbs"), nutrition:getCarbohydrates())
            desc = desc .. string.format("\n%s: %.1f", getText("Tooltip_food_Prots"), nutrition:getProteins())
            desc = desc .. string.format("\n%s: %.1f", getText("Tooltip_food_Fat"), nutrition:getLipids())
        end
    end
    
    local phase = self:getPhaseData(val, type)
    if phase then
        local pVal = phase[3]
        local showMood = false
        local moodName = ""
        
        if type == "temperature" then
            if pVal ~= "+0" then
                showMood = true
                moodName = (string.sub(pVal, 1, 1) == "+") and "Moodles_Hyperthermia" or "Moodles_Hypothermia"
            end
        elseif pVal ~= 0 then
            showMood = true
            local mapping = { fatigue="Tired", thirst="Thirst", hunger="Hungry", infection="Sick", sickness="Sick", health="Injured" }
            moodName = "Moodles_" .. (mapping[type] or type)
        end
        
        if showMood then
            local suffix = (type == "temperature") and string.sub(pVal, 2) or tostring(pVal)
            local mDesc = getText(moodName .. "_desc_lvl" .. suffix)
            if mDesc then
                desc = desc .. "\n\n" .. mDesc
            end
        end
    end
    
    if self.tooltipUI then
        self.tooltipUI:updateData(desc, type, self.currentValues, weightArrowInfo)
        self.tooltipUI:setVisible(true)
        self.tooltipUI:bringToTop()
    end
end

function ISSimpleStatusUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self); self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.fade = UITransition.new(); o.icons = {}
    for _, group in ipairs(ISSimpleStatusUI.Groups) do
        for _, type in ipairs(group.icons) do
            o.icons[type] = {
                texVal = (type == "infection" and 0 or (type == "temperature" and 37 or 100)),
                lastVal = -1,
                arrow = { vis = false, dir = "up", time = 0 }
            }
        end
    end
    return o
end

function ISEnduranceBarUI:initialise()
    ISPanel.initialise(self)
    self:initTextures()
    self:updateLayout()
end

function ISEnduranceBarUI:initTextures()
    self.runTextures = {}
    for i = 0, 4 do
        self.runTextures[i] = getTexture("media/ui/Needs/endurance/run-" .. i .. ".png")
    end
end

function ISEnduranceBarUI:setMinimalMode(minimal)
    if self.minimalMode ~= minimal then
        self.minimalMode = minimal
        if minimal then
            self.checkInstantHide = true
        end
        self.layoutDirty = true
    end
end

function ISEnduranceBarUI:updateLayout()
    local scale = ISSimpleStatusUI.IconSize / 64
    local w, h = 256 * scale, 8 * scale
    local iconSize, spacing = 32 * scale, 10 * scale
    local txtW = getTextManager():MeasureStringX(UIFont.Small, "100%")
    
    local totalW = iconSize + spacing + w + 8 * scale + txtW
    
    if self.minimalMode then
        self:setWidth(w); self:setHeight(h)
    else
        self:setWidth(totalW); self:setHeight(math.max(h, iconSize))
        self:setX(20); self:setY(getCore():getScreenHeight() - 40 - h)
    end
end

function ISEnduranceBarUI:getPhase(val)
    if val <= 0.10 then return 4
    elseif val <= 0.25 then return 3
    elseif val <= 0.50 then return 2
    elseif val <= 0.75 then return 1
    else return 0 end
end

function ISEnduranceBarUI:getColor(val)
    if val <= 0.10 then return {r=1,g=0,b=0}
    elseif val <= 0.25 then return {r=1,g=0.2,b=0.2}
    elseif val <= 0.50 then return {r=1,g=0.4,b=0}
    elseif val <= 0.75 then return {r=0.8,g=0.8,b=0}
    else return {r=0.9,g=0.9,b=0.9} end
end

function ISEnduranceBarUI:isMouseOverSelf()
    local mx = getMouseX()
    local my = getMouseY()
    local ax = self:getAbsoluteX()
    local ay = self:getAbsoluteY()
    return mx >= ax and mx < ax + self:getWidth() and my >= ay and my < ay + self:getHeight()
end

function ISEnduranceBarUI:render()
    if ISSimpleStatusUI.SkipRender > 0 then return end

    local player = getPlayer()
    if not player or player:isDead() then
        self:setVisible(false)
        return
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum())
    local dash = getPlayerVehicleDashboard(player:getPlayerNum())
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(player:getPlayerNum()) or nil
    
    local anyVisible = (hotbar and hotbar:isReallyVisible()) or (dash and dash:isReallyVisible()) or (pscDash and pscDash:isReallyVisible())
    if not anyVisible then
        return
    end

    self:setVisible(true)
    
    local val = player:getStats():get(CharacterStat.ENDURANCE)
    local scale = ISSimpleStatusUI.IconSize / 64
    local w, h = 256 * scale, 8 * scale
    
    local isAiming, shouldFade = player:isAiming(), false
    
    if self.minimalMode and val >= 0.99 then
        shouldFade = true
    end

    if self.minimalMode and val >= 0.99 and self.checkInstantHide then
        self.fade = UITransition.new(); self.fade:setFadeIn(false)
        self.checkInstantHide = false
        return
    end
    self.checkInstantHide = false

    if not shouldFade and isAiming then
        if self.minimalMode then
            local mx, my = getMouseX(), getMouseY()
            local px = isoToScreenX(player:getPlayerNum(), player:getX(), player:getY(), player:getZ())
            local py = isoToScreenY(player:getPlayerNum(), player:getX(), player:getY(), player:getZ())
            
            local hitW, hitH = 250, 160
            local hitX, hitY = px - (hitW / 2), py - 60
            
            if mx >= hitX and mx <= hitX + hitW and my >= hitY and my <= hitY + hitH then
                shouldFade = true
            end
        else
            if self:isMouseOverSelf() then
                shouldFade = true
            end
        end
    end
    
    if shouldFade then
        self.fade:setFadeIn(false)
    else
        self.fade:setFadeIn(true)
    end
    self.fade:update()
    local globalAlpha = self.fade:fraction()
    
    if globalAlpha <= 0 then return end
    
    if self.minimalMode then
        local px = isoToScreenX(player:getPlayerNum(), player:getX(), player:getY(), player:getZ())
        local py = isoToScreenY(player:getPlayerNum(), player:getX(), player:getY(), player:getZ())
        self:setX(px - w/2); self:setY(py + 40)
        
        self:drawRect(0, 0, w, h, globalAlpha, 0.2, 0.2, 0.2)
        local fillW, col = math.max(0, w * val), self:getColor(val)
        if fillW > 0 then
            self:drawRect(0, 0, fillW, h, globalAlpha, col.r, col.g, col.b)
        end
    else
        local iconSize = 32 * scale
        local phase = self:getPhase(val)
        if self.runTextures[phase] then
            self:drawTextureScaled(self.runTextures[phase], 0, (self:getHeight() - iconSize)/2, iconSize, iconSize, globalAlpha, 1, 1, 1)
        end
        
        local barX, barY = iconSize + 10 * scale, (self:getHeight() - h) / 2
        
        self:drawRect(barX, barY, w, h, globalAlpha, 0.2, 0.2, 0.2)
        local fillW = math.max(0, w * val)
        local col = self:getColor(val)
        if fillW > 0 then
            self:drawRect(barX, barY, fillW, h, globalAlpha, col.r, col.g, col.b)
        end
        
        local txt = string.format("%d%%", math.floor(val * 100 + 0.5))
        local txtX, txtY = barX + w + 8 * scale, barY + (h - getTextManager():getFontHeight(UIFont.Small))/2
        
        self:drawText(txt, txtX + 1, txtY + 1, 0, 0, 0, 0.75 * globalAlpha, UIFont.Small)
        self:drawText(txt, txtX, txtY, col.r, col.g, col.b, 1 * globalAlpha, UIFont.Small)
        
        if globalAlpha > 0.9 and self:isMouseOverSelf() and not player:isAiming() then
            local title = getText("Tooltip_HUD_Endurance")
            local desc = string.format("%s: %d%%", title, math.floor(val * 100 + 0.5))
            if phase > 0 then
                local mDesc = getText("Moodles_Endurance_desc_lvl" .. phase)
                if mDesc then desc = desc .. "\n" .. mDesc end
            end
            
            local currentValues = {}
            currentValues["endurance"] = val
            ISSimpleStatusUI.instance.tooltipUI:updateData(desc, "endurance", currentValues, nil)
            ISSimpleStatusUI.instance.tooltipUI:setVisible(true)
            ISSimpleStatusUI.instance.tooltipUI:bringToTop()
            ISSimpleStatusUI.instance.tooltipUI.currentOwner = "endurance"
        else
            if ISSimpleStatusUI.instance.tooltipUI and ISSimpleStatusUI.instance.tooltipUI.currentOwner == "endurance" then
                ISSimpleStatusUI.instance.tooltipUI:setVisible(false)
                ISSimpleStatusUI.instance.tooltipUI.currentOwner = nil
            end
        end
    end
end

function ISEnduranceBarUI:onMouseDown(x, y)
    if getPlayer():isAiming() then return false end return true
end

function ISEnduranceBarUI:onMouseUp(x, y)
    if getPlayer():isAiming() then return false end return true
end

function ISEnduranceBarUI:onRightMouseDown(x, y)
    if getPlayer():isAiming() then return false end return true
end

function ISEnduranceBarUI:onRightMouseUp(x, y)
    if getPlayer():isAiming() then return false end return true
end

function ISEnduranceBarUI:update()
    if self.layoutDirty then
        self:updateLayout()
        self.layoutDirty = false
    end
end

function ISEnduranceBarUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self); self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.minimalMode = false
    o.fade = UITransition.new()
    o.checkInstantHide = false
    return o
end

ISSimpleStatusUI.OnGameStart = function()
    if ISSimpleStatusUI.instance then
        ISSimpleStatusUI.instance:removeFromUIManager()
        ISEnduranceBarUI.instance:removeFromUIManager()
    end
    
    local sw = getCore():getScreenWidth()
    if sw < 1650 then ISSimpleStatusUI.BaseIconSize = 56
    else ISSimpleStatusUI.BaseIconSize = 64 end
    
    ISSimpleStatusUI.instance = ISSimpleStatusUI:new(0, 0, 100, 100)
    ISSimpleStatusUI.instance:initialise()
    ISSimpleStatusUI.instance:addToUIManager()
    ISSimpleStatusUI.instance:backMost()
    
    ISEnduranceBarUI.instance = ISEnduranceBarUI:new(0, 0, 100, 100)
    ISEnduranceBarUI.instance:initialise()
    ISEnduranceBarUI.instance:addToUIManager()
    ISEnduranceBarUI.instance:backMost()
    
    ISSimpleStatusUI.instance.layoutDirty = true
    ISEnduranceBarUI.instance.layoutDirty = true
end

ISSimpleStatusUI.OnResolutionChange = function()
    ISSimpleStatusUI.SkipRender = 10
    if ISSimpleStatusUI.instance then ISSimpleStatusUI.instance.layoutDirty = true end
    if ISEnduranceBarUI.instance then ISEnduranceBarUI.instance.layoutDirty = true end
end

ISSimpleStatusUI.OnPlayerUpdate = function(player)
    if player == getPlayer() and ISSimpleStatusUI.instance then
        ISSimpleStatusUI.instance.layoutDirty = true
    end
end

Events.OnGameStart.Add(ISSimpleStatusUI.OnGameStart)
Events.OnPlayerDeath.Add(function(player)
    if player == getPlayer() then
        ISSimpleStatusUI.instance:setVisible(false); ISEnduranceBarUI.instance:setVisible(false)
    end
end)
Events.OnCreatePlayer.Add(ISSimpleStatusUI.OnGameStart)

Events.OnResolutionChange.Add(ISSimpleStatusUI.OnResolutionChange)
Events.OnClothingUpdated.Add(ISSimpleStatusUI.OnPlayerUpdate)
Events.OnEnterVehicle.Add(ISSimpleStatusUI.OnPlayerUpdate)
Events.OnExitVehicle.Add(ISSimpleStatusUI.OnPlayerUpdate)
Events.OnSwitchVehicleSeat.Add(ISSimpleStatusUI.OnPlayerUpdate)