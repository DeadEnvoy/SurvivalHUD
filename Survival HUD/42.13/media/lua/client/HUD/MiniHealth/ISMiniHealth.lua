local OVERRIDE_X, OVERRIDE_Y = 20, 60

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function ISMiniHealth:isIntersecting(x1, y1, w1, h1, x2, y2, w2, h2)
    return not (x1 + w1 < x2 or x2 + w2 < x1 or y1 + h1 < y2 or y2 + h2 < y1)
end

function ISMiniHealth:checkUICollision(ui)
    if not ui or not ui:isReallyVisible() or ui:getWidth() <= 0 or ui:getHeight() <= 0 then
        return false
    end

    local x, y, w, h = ui:getAbsoluteX(), ui:getAbsoluteY(), ui:getWidth(), ui:getHeight()
    local myX, myY, myW, myH = self:getAbsoluteX(), self:getAbsoluteY(), self:getWidth(), self:getHeight()

    return self:isIntersecting(myX, myY, myW, myH, x, y, w, h)
end

function ISMiniHealth:checkNewResolution()
    self:setX(OVERRIDE_X); self:setY(getCore():getScreenHeight() - self.height - OVERRIDE_Y)
end

function ISMiniHealth:createChildren()
end

function ISMiniHealth:addSettingsPanel()
    self.settingsPanel = {
        getOpen = function() return false end,
        setOpen = function() end
    }
end

function ISMiniHealth:writeConfig() end

function ISMiniHealth:initConfig()
    self.alwaysShow = false; self.moveWithMouse = false
end

function ISMiniHealth:onMouseDown(x, y) return false end
function ISMiniHealth:onMouseMove(dx, dy) self.dragging = false end

function ISMiniHealth:prerender()
    local y_offset = 60; if ISEnduranceBarUI and ISEnduranceBarUI.instance then
        if ISEnduranceBarUI.instance.minimalMode or not ISEnduranceBarUI.instance:isReallyVisible() then
            y_offset = 20
        end
    end
    self:setY(getCore():getScreenHeight() - self:getHeight() - y_offset)

    self:setX(20); if ISEquippedItem and ISEquippedItem.instance and self:checkUICollision(ISEquippedItem.instance) then
        self:setX(80)
    end

    if self:isMouseOver() then
        self.isHover = true
        self.hideTimer = 30
        self.alpha = 1
    else
        self.isHover = false
    end
    
    if self.backgroundTex and self.backgroundTex[self.isFemale] then
        self:drawTexture(self.backgroundTex[self.isFemale], 0, 0, 0.5 * self.alpha, 0, 0, 0)
    end
    
    if self.outlineTex and self.outlineTex[self.isFemale] then
        local outlineColor = (self.health / 80) - 0.2
        self:drawTexture(self.outlineTex[self.isFemale], 0, 0, 1 * self.alpha, 1, outlineColor, outlineColor)
    end
    
    if self:isMouseOver() then
        self:renderTooltip()
    else
        self:hideTooltip()
    end
end

function ISMiniHealth:hideTooltip()
    if self.tooltip then
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

function ISMiniHealth:getDamagedParts()
    local result = {}
    local bodyParts = self.player:getBodyDamage():getBodyParts()
    for i=1,bodyParts:size() do
        local bodyPart = bodyParts:get(i-1)
        if bodyPart:HasInjury() or bodyPart:bandaged() or bodyPart:stitched() or bodyPart:getSplintFactor() > 0 or
        bodyPart:getAdditionalPain() > 10 or bodyPart:getStiffness() > 5  or (ISHealthPanel.cheat and bodyPart:getStiffness() > 0) then
            table.insert(result, bodyPart)
        end
    end
    return result
end

function ISMiniHealth:getBodyPartStatusText(bodyPart)
    local text = ""
    local doctorLevel = self.player:getPerkLevel(Perks.Doctor)
    local cheat = ISHealthPanel.cheat

    text = text .. "<RGB:1,1,1>" .. BodyPartType.getDisplayName(bodyPart:getType())
    if cheat then
        text = text .. " (health=" .. round(bodyPart:getHealth(), 4) .. ")"
    end
    text = text .. "\n"

    local injuryText = ""

    if bodyPart:getPlantainFactor() > 0 then
        injuryText = injuryText .. "<RGB:0.28,0.89,0.28>- " .. getText("ContextMenu_PlantainCataplasm") .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - factor " .. round(bodyPart:getPlantainFactor(),2) .. "\n" end
    end
    if bodyPart:getComfreyFactor() > 0 then
        injuryText = injuryText .. "<RGB:0.28,0.89,0.28>- " .. getText("ContextMenu_ComfreyCataplasm") .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - factor " .. round(bodyPart:getComfreyFactor(),2) .. "\n" end
    end
    if bodyPart:getGarlicFactor() > 0 then
        injuryText = injuryText .. "<RGB:0.28,0.89,0.28>- " .. getText("ContextMenu_GarlicCataplasm") .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - factor " .. round(bodyPart:getGarlicFactor(),2) .. "\n" end
    end

    if bodyPart:scratched() then
        local extraText = "";
        if doctorLevel > 2 or cheat then
            if bodyPart:getScratchTime() > 17 then extraText = " (" .. getText("IGUI_health_Severe") ..")";
            elseif bodyPart:getScratchTime() > 14 then extraText = " (" .. getText("IGUI_health_Moderate") ..")"; end
        end
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_Scratched") .. extraText .. "\n"
        if cheat and bodyPart:getScratchTime() > 0 then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - scratch Time " .. round(bodyPart:getScratchTime(),2) .. "\n" end
    end

    if bodyPart:isCut() then
        local extraText = "";
        if doctorLevel > 2 or cheat then
            if bodyPart:getCutTime() > 17 then extraText = " (" .. getText("IGUI_health_Severe") ..")";
            elseif bodyPart:getCutTime() > 14 then extraText = " (" .. getText("IGUI_health_Moderate") ..")"; end
        end
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_Cut") .. extraText .. "\n"
        if cheat and bodyPart:getCutTime() > 0 then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - cut Time " .. round(bodyPart:getCutTime(),2) .. "\n" end
    end

    if bodyPart:deepWounded() then
        local extraText = "";
        if doctorLevel > 4 or cheat then
            if bodyPart:getDeepWoundTime() > 10 then extraText = " (" .. getText("IGUI_health_Severe") ..")";
            elseif bodyPart:getDeepWoundTime() > 8 then extraText = " (" .. getText("IGUI_health_Moderate") ..")"; end
        end
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_DeepWound") .. " " .. extraText .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - deepWound Time " .. round(bodyPart:getDeepWoundTime(),2) .. "\n" end
    end

    if bodyPart:bitten() then
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_Bitten") .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - bite Time " .. round(bodyPart:getBiteTime(),2) .. "\n" end
    end

    if bodyPart:getAdditionalPain() > 10 then
        if bodyPart:getAdditionalPain() > 50 then
            injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_HeavyPain") .. "\n"
        else
            injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_Pain") .. "\n"
        end
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - additional pain " .. round(bodyPart:getAdditionalPain(),2) .. "\n" end
    end

    local showStiffness = false;
    local minorStiffness = false;
    local showDebugStiffness = false;
    if bodyPart:getStiffness() >= 5 then showStiffness = true
    elseif ISHealthPanel.cheat and bodyPart:getStiffness() > 0 then showDebugStiffness = true end
    if showStiffness and bodyPart:getStiffness() < 20 then minorStiffness = true end

    if minorStiffness then
        injuryText = injuryText .. "<RGB:1,0.58,0>- " .. getText("IGUI_health_MinorStiffness") .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:1,0.58,0>- " .. getText("(Debug - HAS NO EFFECT ON THE PLAYER!)") .. round(bodyPart:getStiffness(),2) .. "/100\n" end
    elseif showStiffness then
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_Stiffness") .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("(Debug) ") .. round(bodyPart:getStiffness(),2) .. "/100\n" end
    elseif showDebugStiffness then
        injuryText = injuryText .. "<RGB:0.89,0.89,0.28>- " .. getText("IGUI_health_DebugInvisibleStiffness") .. round(bodyPart:getStiffness(),2) .. "/100\n"
    end

    if bodyPart:bleeding() then
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_Bleeding") .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - bleeding Time " .. round(bodyPart:getBleedingTime(),2) .. "\n" end
    end

    if bodyPart:getFractureTime() > 0 and bodyPart:getSplintFactor() == 0 then
        local extraText = ""
        if doctorLevel > 6 or cheat then
            if bodyPart:getFractureTime() > 50 then extraText = " (" .. getText("IGUI_health_Severe") ..")"
            elseif bodyPart:getFractureTime() > 20 then extraText = " (" .. getText("IGUI_health_Moderate") ..")" end
        end
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_Fracture") .. " " .. extraText .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - fracture Time " .. round(bodyPart:getFractureTime(),2) .. "\n" end
    end

    if bodyPart:getSplintFactor() > 0 then
        local extraText = ""
        if doctorLevel > 4 or cheat then
            if bodyPart:getSplintFactor() > 4 then extraText = " (" .. getText("IGUI_health_Good") ..")"
            elseif bodyPart:getFractureTime() > 2 then extraText = " (" .. getText("IGUI_health_Moderate") ..")" end
        end
        injuryText = injuryText .. "<RGB:0.28,0.89,0.28>- " .. getText("IGUI_health_Splinted") .. " " .. extraText .. "\n"
        if cheat then injuryText = injuryText .. "<RGB:0.89,0.28,0.28>     - splint Factor " .. round(bodyPart:getSplintFactor(),2) .. "\n" end
    end

    if bodyPart:bandaged() then
        if bodyPart:getBandageLife() > 0 then
            injuryText = injuryText .. "<RGB:0.28,0.89,0.28>- " .. getText("IGUI_health_Bandaged") .. "\n"
        else
            injuryText = injuryText .. "<RGB:1,0.28,0>- " .. getText("IGUI_health_DirtyBandage") .. "\n"
        end
        if cheat then
            if bodyPart:getBandageLife() > 0 then
                injuryText = injuryText .. "<RGB:0.28,0.89,0.28>     - Bandage Life " .. round(bodyPart:getBandageLife(), 4) .. "\n"
            end
            if bodyPart:getBleedingTime() > 0 then
                injuryText = injuryText .. "<RGB:0.28,0.89,0.28>     - bleeding Time " .. round(bodyPart:getBleedingTime(), 4) .. "\n"
            end
            if bodyPart:getScratchTime() > 0 then
                injuryText = injuryText .. "<RGB:0.28,0.89,0.28>     - scratch Time " .. round(bodyPart:getScratchTime(), 4) .. "\n"
            end
            if bodyPart:getCutTime() > 0 then
                injuryText = injuryText .. "<RGB:0.28,0.89,0.28>     - cut Time " .. round(bodyPart:getCutTime(), 4) .. "\n"
            end
            if bodyPart:getDeepWoundTime() > 0 then
                injuryText = injuryText .. "<RGB:0.28,0.89,0.28>     - deep-wound Time " .. round(bodyPart:getDeepWoundTime(), 4) .. "\n"
            end
        end
    end

    if bodyPart:isInfectedWound() and not bodyPart:bandaged() then
        if doctorLevel > 8 or (bodyPart:getWoundInfectionLevel() * 10 >= (2.5 - doctorLevel)) or cheat then
            injuryText = injuryText .. "<RGB:1,0.28,0>- " .. getText("IGUI_health_Infected") .. "\n"
            if cheat then injuryText = injuryText .. "<RGB:1,0.28,0>     - WOUND infection Time " .. round(bodyPart:getWoundInfectionLevel(), 4) .. "\n" end
        end
    end

    if bodyPart:haveBullet() and not bodyPart:bandaged() then
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_LodgedBullet") .. "\n"
    end

    if bodyPart:getBurnTime() > 0 and not bodyPart:bandaged() then
        local burnText = "";
        if (doctorLevel > 4 or cheat) and bodyPart:isNeedBurnWash() then
            burnText = " (" .. getText("IGUI_health_NeedCleaning") ..")";
        end
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_Burned") .. burnText .. "\n"
        if cheat then
            injuryText = injuryText .. "<RGB:1,0.28,0>     - burn Time " .. round(bodyPart:getBurnTime(), 4) .. "(" .. bodyPart:getLastTimeBurnWash() .. ")\n"
        end
    end

    if bodyPart:stitched() then
        local extraText = "";
        if doctorLevel > 6 or cheat then
            if bodyPart:getStitchTime() > 40 then extraText = " (" .. getText("IGUI_health_Good") ..")";
            else extraText = " (" .. getText("IGUI_health_NeedTime") ..")"; end
        end
        injuryText = injuryText .. "<RGB:0.28,0.89,0.28>- " .. getText("IGUI_health_Stitched") .. extraText .. "\n"
        if cheat then
            injuryText = injuryText .. "<RGB:0.28,0.89,0.28>     - stitch Time " .. round(bodyPart:getStitchTime(), 4) .. "\n"
        end
    end

    if bodyPart:haveGlass() and not bodyPart:bandaged() then
        injuryText = injuryText .. "<RGB:0.89,0.28,0.28>- " .. getText("IGUI_health_LodgedGlassShards") .. "\n"
    end
    
    if #injuryText > 0 then
        injuryText = injuryText:sub(1, -2)
    end
    text = text .. injuryText

    return text
end

function ISMiniHealth:renderTooltip()
    if not self.tooltip then
        self.tooltip = ISToolTip:new()
        self.tooltip:initialise()
        self.tooltip:addToUIManager()
        self.tooltip:setOwner(self)
        self.tooltip:setAlwaysOnTop(true)
    end

    local description = ""
    description = description .. "<RGB:1,1,1>" .. getText("IGUI_health_Overall_Body_Status") .. "\n"

    local bodyDamage = self.player:getBodyDamage()
    local health = bodyDamage:getHealth()
    
    local statusStr = ""
    if health == 100 then
        statusStr = getText("IGUI_health_ok")
    elseif health >= 90 then
        statusStr = getText("IGUI_health_Slight_damage")
    elseif health >= 80 then
        statusStr = getText("IGUI_health_Very_Minor_damage")
    elseif health >= 70 then
        statusStr = getText("IGUI_health_Minor_damage")
    elseif health >= 60 then
        statusStr = getText("IGUI_health_Moderate_damage")
    elseif health >= 50 then
        statusStr = getText("IGUI_health_Severe_damage")
    elseif health >= 40 then
        statusStr = getText("IGUI_health_Very_Severe_damage")
    elseif health >= 20 then
        statusStr = getText("IGUI_health_Crital_damage")
    elseif health >= 10 then
        statusStr = getText("IGUI_health_Highly_Crital_damage")
    elseif health > 0 then
        statusStr = getText("IGUI_health_Terminal_damage")
    else
        statusStr = getText("IGUI_health_Deceased")
    end
    
    local InjuryRedTextTint = (100 - health) / 100
    InjuryRedTextTint = math.max(InjuryRedTextTint, 0.2)
    local r = 1.0
    local g = 1.0 - InjuryRedTextTint
    local b = 1.0 - InjuryRedTextTint
    description = description .. "<RGB:"..tostring(r)..","..tostring(g)..","..tostring(b)..">" .. statusStr .. "\n"

    local painLevel = self.player:getMoodles():getMoodleLevel(MoodleType.PAIN)
    local doctorLevel = self.player:getPerkLevel(Perks.Doctor)
    local cheat = ISHealthPanel.cheat
    
    if (cheat or doctorLevel > 4) and painLevel > 0 then
        description = description .. "<RGB:1,1,1>" .. getText("Moodles_Pain_lvl" .. painLevel) .. "\n"
    end

    local damagedParts = self:getDamagedParts()
    if #damagedParts > 0 then
        description = description .. "\n"
        for i, bodyPart in ipairs(damagedParts) do
            description = description .. self:getBodyPartStatusText(bodyPart)
            if i < #damagedParts then
                description = description .. "\n\n"
            end
        end
    end

    self.tooltip.description = description
    
    self.tooltip:setX(self:getMouseX() + 20)
    self.tooltip:setY(self:getMouseY() + 20)
    self.tooltip:setVisible(true)
    self.tooltip:bringToTop()
end

Events.OnPlayerDeath.Add(function(player)
    if mhpHandle and player == mhpHandle.player then
        mhpHandle:setVisible(false)
    end
end)

Events.OnGameStart.Add(function()
    if mhpHandle then
        mhpHandle:setVisible(true); mhpHandle:backMost()
    end
end)

Events.OnCreatePlayer.Add(function()
    if mhpHandle then
        mhpHandle:setVisible(true); mhpHandle:backMost()
    end
end)