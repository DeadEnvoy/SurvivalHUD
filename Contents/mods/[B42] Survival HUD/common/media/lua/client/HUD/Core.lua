require "ISUI/ISPanel";

local Utils = require("HUD/Utils");

SurvivalHUD = ISPanel:derive("SurvivalHUD");
EnduranceUI = ISPanel:derive("EnduranceUI");

SurvivalHUD.instance = nil;
EnduranceUI.instance = nil;

SurvivalHUD.ICON_SIZE = 64;

local CURRENT_ICON_SIZE = 64;

local BOTTOM_OFFSET = 15;
local RIGHT_OFFSET = 15;

local CHEVRON_CONFIG = {
    [48] = { texSize = 16, renderSize = 12 },
    [64] = { texSize = 16, renderSize = 16 },
    [80] = { texSize = 24, renderSize = 20 },
};

local SKIP_RENDER = 0;

local ARROW_DURATION = 10000;

local ARROW_OFFSET = 5.25;

local TOOLTIP_ALPHA_THRESHOLD = 0.9;

local CRITICAL_BLINK_PERIOD_MS = 1000;

local FOOD_EATEN_THRESHOLDS = {
    { timer = 4800, level = 4 },
    { timer = 3200, level = 3 },
    { timer = 1600, level = 2 },
    { timer = 0, level = 1 },
};

local COLLISION_SIZES = { 80, 64, 48 };

local PHASE_COLORS = {
    [0] = { r = 1, g = 1, b = 1 },
    [1] = { r = 1, g = 0.866, b = 0 },
    [2] = { r = 1, g = 0.482, b = 0.101 },
    [3] = { r = 0.862, g = 0.247, b = 0.290 },
    [4] = { r = 0.937, g = 0.196, b = 0.247 },
};

local GHOST_ALPHA = 0.4;

local FOOD_EATEN_PHASE_COLORS = {
    [1] = { r = 0.729, g = 0.898, b = 0.682 },
    [2] = { r = 0.635, g = 0.862, b = 0.576 },
    [3] = { r = 0.545, g = 0.831, b = 0.470 },
    [4] = { r = 0.454, g = 0.796, b = 0.364 },
};

local TEMP_PHASE_COLORS = {
    ["-1"] = { r = 0.62, g = 0.8, b = 0.9 },
    ["-2"] = { r = 0.43, g = 0.78, b = 0.91 },
    ["-3"] = { r = 0.1, g = 0.67, b = 0.86 },
    ["-4"] = { r = 0.5, g = 0.6, b = 0.75 }
};

local PHASES = {
    Fatigue = {
        { 40, 100, 0, { 100, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45 } },
        { 30, 40, 1, { 40, 35 } },
        { 20, 30, 2, { 30, 25 } },
        { 10, 20, 3, { 20, 15 } },
        { 5, 10, 4, { 10, 5 } },
    },
    Hunger = {
        { 85, 100, 0, { 100, 95, 90 } },
        { 75, 85, 1, { 85, 80 } },
        { 55, 75, 2, { 75, 70, 65, 60 } },
        { 30, 55, 3, { 55, 50, 45, 40, 35 } },
        { 0, 30, 4, { 30, 25, 20, 15, 10, 5 } },
    },
    Thirst = {
        { 88, 100, 0, { 100, 95, 90 } },
        { 75, 88, 1, { 88, 85, 80 } },
        { 30, 75, 2, { 75, 70, 65, 60, 55, 50, 45, 40, 35 } },
        { 16, 30, 3, { 30, 25, 20 } },
        { 0, 16, 4, { 16, 10, 5 } },
    },
    Temperature = {
        { 41, 42, "+4", { 41 } },
        { 40, 41, "+3", { 40 } },
        { 39, 40, "+2", { 39 } },
        { 37.5, 39, "+1", { 37.5, 38 } },
        { 36.5, 37.5, "0", { 37 } },
        { 35, 36.5, "-1", { 36.5 } },
        { 30, 35, "-2", { 30.5, 31.5, 32, 33, 33.5, 34.5, 35 } },
        { 25, 30, "-3", { 26.5, 27, 28, 29, 30 } },
        { 20, 25, "-4", { 25 } },
    },
    Sickness = {
        { 90, 100, 4, { 91, 95, 100 } },
        { 75, 90, 3, { 76, 80, 85, 90 } },
        { 50, 75, 2, { 51, 55, 60, 65, 70, 75 } },
        { 25, 50, 1, { 26, 30, 35, 40, 45, 50 } },
        { 0, 25, 0, { 0, 5, 10, 15, 20, 25 } },
    },
    Intoxication = {
        { 90, 100, 4, { 91, 95, 100 } },
        { 75, 90, 3, { 76, 80, 85, 90 } },
        { 50, 75, 2, { 51, 55, 60, 65, 70, 75 } },
        { 25, 50, 1, { 26, 30, 35, 40, 45, 50 } },
        { 0, 25, 0, { 0, 5, 10, 15, 20, 25 } },
    },
    Health = {
        { 80, 100, 0, { 100, 95, 90, 85 } },
        { 60, 80, 1, { 80, 75, 70, 65 } },
        { 40, 60, 2, { 60, 55, 50, 45 } },
        { 25, 40, 3, { 40, 35, 30 } },
        { 0, 25, 4, { 25, 20, 15, 10, 5 } },
    },
};

local CRITICAL_PHASE_LEVELS = {
    Fatigue = { [4] = true },
    Hunger = { [4] = true },
    Thirst = { [4] = true },
    Temperature = { ["-4"] = true, ["+4"] = true },
    Sickness = { [4] = true },
    Intoxication = { [4] = true },
    Health = { [4] = true },
};

local GROUPS = {
    { icons = { "Fatigue" } },
    { icons = { "Thirst", "Hunger", "Temperature" } },
    { icons = { "Intoxication", "Sickness", "Health" } },
};

local ICON_GAP_BASE = 16;
local GROUP_GAP_BASE = 40;

local function getIconGap(size)
    return math.floor(ICON_GAP_BASE * size / 64 + 0.5);
end

local function getGroupGap(size)
    return math.floor(GROUP_GAP_BASE * size / 64 + 0.5);
end

local ICON_VISUAL_PADDING = {
    Fatigue = { left = 0.23, right = 0.23 },
    Thirst = { left = 0.28, right = 0.28 },
    Hunger = { left = 0.14, right = 0.14 },
    Temperature  = { left = 0.30, right = 0.30 },
    Intoxication = { left = 0.025, right = 0.025 },
    Sickness = { left = 0.025, right = 0.025 },
    Health = { left = 0.025, right = 0.025 },
};

local DEBUG_PADDING = false;

local function getPanelsVisible(playerNum)
    local hotbar = getPlayerHotbar(playerNum);
    local dash = getPlayerVehicleDashboard(playerNum);
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(playerNum) or nil;
    return hotbar and hotbar:isReallyVisible(), dash and dash:isReallyVisible(), pscDash and pscDash:isReallyVisible();
end

local function getRangedWeapon(player)
    local weapon = player:getPrimaryHandItem();
    if not weapon or not instanceof(weapon, "HandWeapon") or not weapon:isRanged() then
        return nil;
    end
    return weapon;
end

local function truncateNameToWidth(name, font, maxWidth)
    if getTextManager():MeasureStringX(font, name) <= maxWidth then
        return name;
    end
    if getTextManager():MeasureStringX(font, "...") > maxWidth then
        return nil;
    end
    for cut = #name - 1, 1, -1 do
        local byte = string.byte(name, cut);
        if byte < 0x80 or byte >= 0xC0 then
            local prefix = string.sub(name, 1, cut) .. "...";
            if getTextManager():MeasureStringX(font, prefix) <= maxWidth then
                return prefix;
            end
        end
    end
    return nil;
end

local function getAmmoDisplayText(weapon)
    if weapon:isJammed() then
        return "X";
    end
    if weapon:getMagazineType() and weapon:isContainsClip() then
        local chamberFlag = weapon:isRoundChambered() and "1" or "0";
        return chamberFlag .. " (" .. weapon:getCurrentAmmoCount() .. ")";
    end
    if weapon:haveChamber() then
        return tostring(weapon:getCurrentAmmoCount() + (weapon:isRoundChambered() and 1 or 0));
    end
    return tostring(weapon:getCurrentAmmoCount());
end

local MOODLE_NAMES = {
    Fatigue = "Tired",
    Thirst = "Thirst",
    Hunger = "Hungry",
    Intoxication = "Sick",
    Sickness = "Sick",
    Health = "Injured",
};

local Tooltip = ISPanel:derive("SurvivalHUD_Tooltip");

function Tooltip:initialise()
    ISPanel.initialise(self);
    self:instantiate();
    self.javaObject:setConsumeMouseEvents(false);
    self.backgroundColor = { r = 0.9, g = 0.1, b = 0.1, a = 0.1 };
    self.borderColor = { r = 1, g = 0.7, b = 0.7, a = 0.7 };
    self.currentOwner = nil;
end

function Tooltip:showFor(owner, text, iconType, currentValues, weightArrowInfo)
    self.currentOwner = owner;
    self:updateData(text, iconType, currentValues, weightArrowInfo);
    self:setVisible(true);
    self:bringToTop();
end

function Tooltip:hideFor(owner)
    if self.currentOwner ~= owner then return; end
    self:setVisible(false);
    self.currentOwner = nil;
end

function Tooltip:updateData(text, iconType, currentValues, weightArrowInfo)
    self.tooltipText = text;
    self.iconType = iconType;
    self.currentValues = currentValues;
    self.weightArrowInfo = weightArrowInfo;
    self:calculateLayout();
end

function Tooltip:calculateLayout()
    if not self.tooltipText then return; end

    local font = UIFont.Small;
    local lineHeight = getTextManager():getFontHeight(font);
    local pad = 8;

    local lines = {};
    for line in string.gmatch(self.tooltipText, "[^\n]+") do
        table.insert(lines, line);
    end
    self.lines = lines;

    local maxWidth = 0;
    for _, line in ipairs(lines) do
        local lineWidth = getTextManager():MeasureStringX(font, line);
        if self.iconType == "Hunger" and string.find(line, getText("Tooltip_HUD_Weight"), 1, true) then
            if self.weightArrowInfo then
                lineWidth = lineWidth + 20;
            end
        end
        if lineWidth > maxWidth then
            maxWidth = lineWidth;
        end
    end

    local panelW = maxWidth + pad * 2;
    local panelH = #lines * lineHeight + pad * 2;

    local mx = getMouseX();
    local my = getMouseY();
    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();

    local rx = mx + 12;
    if rx + panelW > screenW then
        rx = mx - panelW - 12;
        if rx < 0 then rx = screenW - panelW; end
    end

    local ry = my - panelH - 12;
    if ry < 0 then
        ry = my + 12;
    end
    if ry + panelH > screenH then
        ry = screenH - panelH;
    end

    self:setX(rx);
    self:setY(ry);
    self:setWidth(panelW);
    self:setHeight(panelH);
end

function Tooltip:getLineColor()
    if self.iconType == "Endurance" then
        return self:getEnduranceLineColor();
    end
    return self:getStatLineColor();
end

function Tooltip:getEnduranceLineColor()
    local val = self.currentValues["Endurance"];
    local phase = EnduranceUI.instance:getPhase(val);
    local color = PHASE_COLORS[phase];
    if color then
        return color.r, color.g, color.b;
    end
    return 1, 1, 1;
end

function Tooltip:getStatLineColor()
    local phase = SurvivalHUD.instance:getPhaseData(
        self.currentValues[self.iconType], self.iconType);
    if not phase then
        return 1, 1, 1;
    end

    local phaseLevel = phase[3];

    if self.iconType == "Temperature" then
        local color = TEMP_PHASE_COLORS[phaseLevel];
        if color then
            return color.r, color.g, color.b;
        end
        local numericLevel = (phaseLevel == "0") and 0 or tonumber(phaseLevel:sub(2));
        color = PHASE_COLORS[numericLevel];
        if color then
            return color.r, color.g, color.b;
        end
        return 1, 1, 1;
    end

    if self.iconType == "Hunger" and self.foodEatenPhase then
        local color = FOOD_EATEN_PHASE_COLORS[self.foodEatenPhase];
        if color then
            return color.r, color.g, color.b;
        end
    end

    local color = PHASE_COLORS[phaseLevel];
    if color then
        return color.r, color.g, color.b;
    end
    return 1, 1, 1;
end

function Tooltip:getWeightArrowTexture()
    local info = self.weightArrowInfo;
    if info.isIncWeightLot then
        return getTexture("media/ui/chevron_double.png");
    elseif info.isIncWeight then
        return getTexture("media/ui/chevron_up.png");
    elseif info.isDecWeight then
        return getTexture("media/ui/chevron_down.png");
    end
    return nil;
end

function Tooltip:prerender()
    if not self.tooltipText then return; end

    self:drawRect(0, 0, self.width, self.height, 0.9, 0.1, 0.1, 0.1);
    self:drawRectBorder(0, 0, self.width, self.height, 1, 0.7, 0.7, 0.7);

    local font = UIFont.Small;
    local lineHeight = getTextManager():getFontHeight(font);
    local pad = 8;
    local curY = pad;

    for i, line in ipairs(self.lines) do
        local r, g, b = 0.8, 0.8, 0.8;

        if i == 1 then
            r, g, b = self:getLineColor();
        end

        self:drawText(line, pad, curY, r, g, b, 1, font);

        if self.iconType == "Hunger"
            and string.find(line, getText("Tooltip_HUD_Weight"), 1, true)
            and self.weightArrowInfo then
            local arrowTex = self:getWeightArrowTexture();
            if arrowTex then
                local textWidth = getTextManager():MeasureStringX(font, line);
                local arrowX = pad + textWidth + 5;
                local arrowY = curY + (lineHeight - arrowTex:getHeight()) / 2;
                self:drawTextureScaled(arrowTex, arrowX, arrowY, arrowTex:getWidth(), arrowTex:getHeight(), 1, 1, 1, 1);
            end
        end

        curY = curY + lineHeight;
    end
end

function Tooltip:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o:setAlwaysOnTop(true);
    return o
end

function SurvivalHUD:initialise()
    ISPanel.initialise(self);
    CURRENT_ICON_SIZE = SurvivalHUD.ICON_SIZE;
    self.layoutDirty = true;

    self.tooltipUI = Tooltip:new(0, 0, 0, 0);
    self.tooltipUI:initialise();
    self.tooltipUI:addToUIManager();
    self.tooltipUI:setVisible(false);
end

function SurvivalHUD:getPhaseData(val, statType)
    local phases = PHASES[statType];
    if not phases then return nil; end

    if val ~= val then
        return nil;
    end

    for _, phase in ipairs(phases) do
        if val >= phase[1] and val <= phase[2] then
            return phase;
        end
    end

    return phases[#phases];
end

function SurvivalHUD:getFoodEatenPhase(timer)
    if timer <= 0 then return nil; end
    for _, t in ipairs(FOOD_EATEN_THRESHOLDS) do
        if timer > t.timer then return t.level, t.timer; end
    end
    return nil;
end

function SurvivalHUD:isStatVisible(statType, val)
    if statType == "Fatigue" then
        return self.sleepNeeded;
    end
    if statType == "Intoxication" then
        return not self.sleepNeeded or val > 0;
    end
    if statType == "Sickness" then
        return val > 0;
    end
    return true;
end

function SurvivalHUD:getBestTexture(val, statType, currentTexVal)
    local intoxicationAlwaysShown = statType == "Intoxication" and not self.sleepNeeded;
    if statType ~= "Temperature" and val <= 0 and not intoxicationAlwaysShown then return nil; end

    local threshold = (statType == "Temperature") and 0.5 or 1.0;

    local phase = self:getPhaseData(val, statType);

    if currentTexVal ~= -1 and math.abs(val - currentTexVal) < threshold then
        if phase then
            for _, texVal in ipairs(phase[4]) do
                if texVal == currentTexVal then
                    return currentTexVal;
                end
            end
        end
    end

    if not phase then return nil; end

    local texValues = phase[4];
    if #texValues == 0 then
        return (statType == "Temperature") and 37 or nil;
    end

    local bestVal = texValues[1];
    local bestDiff = math.abs(val - bestVal);
    for _, texVal in ipairs(texValues) do
        local diff = math.abs(val - texVal);
        if diff < bestDiff then
            bestDiff = diff;
            bestVal = texVal;
        end
    end
    return bestVal;
end

local function valueToFilename(v)
    return tostring(v):gsub("%.", "-");
end

local function buildNeutralBgPath(sizeStr, statType)
    if statType == "Temperature" then
        return "media/ui/Needs/" .. sizeStr .. "/Temperature/Temperature_Background_0.png";
    end
    local typeCap = statType:sub(1, 1):upper() .. statType:sub(2);
    return "media/ui/Needs/" .. sizeStr .. "/" .. typeCap .. "/" .. typeCap .. "_Background_0.png";
end

local function buildTexturePaths(sizeStr, statType, phase, texVal)
    local phaseLevel = phase[3];
    local bgPath, iconPath;

    if statType == "Temperature" then
        local texValStr = valueToFilename(texVal);

        if phaseLevel == "0" then
            bgPath = "media/ui/Needs/" .. sizeStr .. "/Temperature/Temperature_Background_0.png";
            iconPath = "media/ui/Needs/" .. sizeStr .. "/Temperature/Temperature_0_" .. texValStr .. ".png";
        elseif phaseLevel:sub(1, 1) == "-" then
            local lvl = phaseLevel:sub(2);
            bgPath = "media/ui/Needs/" .. sizeStr .. "/Temperature/Hypothermia/Hypothermia_Background_" .. lvl .. ".png";
            iconPath = "media/ui/Needs/" .. sizeStr .. "/Temperature/Hypothermia/Hypothermia_" .. lvl .. "_" .. texValStr .. ".png";
        else
            local lvl = phaseLevel:sub(2);
            bgPath = "media/ui/Needs/" .. sizeStr .. "/Temperature/Hyperthermia/Hyperthermia_Background_" .. lvl .. ".png";
            iconPath = "media/ui/Needs/" .. sizeStr .. "/Temperature/Hyperthermia/Hyperthermia_" .. lvl .. "_" .. texValStr .. ".png";
        end
    else
        local typeCap = statType:sub(1, 1):upper() .. statType:sub(2);
        local texValStr = valueToFilename(texVal);
        bgPath = "media/ui/Needs/" .. sizeStr .. "/" .. typeCap .. "/" .. typeCap .. "_Background_" .. tostring(phaseLevel) .. ".png";
        iconPath = "media/ui/Needs/" .. sizeStr .. "/" .. typeCap .. "/" .. typeCap .. "_" .. tostring(phaseLevel) .. "_" .. texValStr .. ".png";
    end

    return bgPath, iconPath;
end

function SurvivalHUD:getTexturePaths(statType, phase, texVal)
    return buildTexturePaths(tostring(CURRENT_ICON_SIZE), statType, phase, texVal);
end

function SurvivalHUD:getIconPadPx(statType)
    local size = CURRENT_ICON_SIZE;
    local pad = ICON_VISUAL_PADDING[statType];
    return pad and math.floor(size * pad.left) or 0, pad and math.floor(size * pad.right) or 0;
end

function SurvivalHUD:isIntersecting(x1, y1, w1, h1, x2, y2, w2, h2)
    return not (x1 + w1 < x2 or x2 + w2 < x1 or y1 + h1 < y2 or y2 + h2 < y1);
end

function SurvivalHUD:checkUICollision(ui)
    if not ui then return false; end
    if not ui:isReallyVisible() then return false; end
    if ui:getWidth() <= 0 or ui:getHeight() <= 0 then return false; end

    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    local myX = screenW - self:getWidth() - RIGHT_OFFSET;
    local myY = screenH - BOTTOM_OFFSET - CURRENT_ICON_SIZE;
    local myW = self:getWidth();
    local myH = CURRENT_ICON_SIZE;

    return self:isIntersecting(myX, myY, myW, myH, ui:getAbsoluteX(), ui:getAbsoluteY(), ui:getWidth(), ui:getHeight());
end

function SurvivalHUD:resolveCollisionWith(ui, isIntoxicationVisible, isSicknessVisible)
    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    while self:checkUICollision(ui) do
        local nextIconSize = Utils.getNextSmallerSize(COLLISION_SIZES, CURRENT_ICON_SIZE);
        if nextIconSize then
            CURRENT_ICON_SIZE = nextIconSize;
            if EnduranceUI.instance then
                EnduranceUI.instance.layoutDirty = true;
            end
            self:recalcDimensions(isIntoxicationVisible, isSicknessVisible);
            self:setX(screenW - self:getWidth() - RIGHT_OFFSET);
            self:setY(screenH - BOTTOM_OFFSET - CURRENT_ICON_SIZE);
        elseif HotbarReskin and ui.availableSlot then
            local nextHotbarSize = Utils.getNextSmallerSize(Utils.CollisionSizes, HotbarReskin.CURRENT_HOTBAR_SIZE);
            if not nextHotbarSize then break; end
            HotbarReskin.CURRENT_HOTBAR_SIZE = nextHotbarSize;
            Utils.layoutHotbar(ui);
        else
            break;
        end
    end
end

function SurvivalHUD:updateLayout(isIntoxicationVisible, isSicknessVisible)
    local player = getPlayer();
    if not player then return; end

    if isIntoxicationVisible == nil then
        isIntoxicationVisible = self:isStatVisible("Intoxication", player:getStats():get(CharacterStat.FOOD_SICKNESS));
    end
    if isSicknessVisible == nil then
        isSicknessVisible = self:isStatVisible("Sickness", player:getStats():get(CharacterStat.SICKNESS));
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum());
    local dash = getPlayerVehicleDashboard(player:getPlayerNum());
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(player:getPlayerNum()) or nil;
    local vehicle = player:getVehicle();

    CURRENT_ICON_SIZE = SurvivalHUD.ICON_SIZE;
    if HotbarReskin and hotbar then
        HotbarReskin.CURRENT_HOTBAR_SIZE = HotbarReskin.HOTBAR_SIZE;
        Utils.layoutHotbar(hotbar);
    end
    self:recalcDimensions(isIntoxicationVisible, isSicknessVisible);

    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    self:setX(screenW - self:getWidth() - RIGHT_OFFSET);
    self:setY(screenH - BOTTOM_OFFSET - CURRENT_ICON_SIZE);

    if vehicle and vehicle:isDriver(player) and pscDash then
        self:resolveCollisionWith(pscDash, isIntoxicationVisible, isSicknessVisible);
    end
    if vehicle and vehicle:isDriver(player) and dash then
        self:resolveCollisionWith(dash, isIntoxicationVisible, isSicknessVisible);
    end
    if hotbar then
        self:resolveCollisionWith(hotbar, isIntoxicationVisible, isSicknessVisible);
    end

    if EnduranceUI.instance then
        EnduranceUI.instance:setVisible(true);
        EnduranceUI.instance.layoutDirty = true;
    end

    self.cachedHotbarVis = hotbar and hotbar:isReallyVisible();
    self.cachedDashVis = dash and dash:isReallyVisible();
    self.cachedPscDashVis = pscDash and pscDash:isReallyVisible();
end

function SurvivalHUD:recalcDimensions(showIntoxication, showSickness)
    local size = CURRENT_ICON_SIZE;
    local totalW = 0;
    local groupWidths = {};
    local visibleGroups = {};

    local function getVisibleIcons(group)
        local t = {};
        for _, st in ipairs(group.icons) do
            local hidden = (st == "Intoxication" and not showIntoxication) or (st == "Sickness" and not showSickness);
            if st == "Fatigue" and not self:isStatVisible("Fatigue", 0) then
                hidden = true;
            end
            if not hidden then table.insert(t, st); end
        end
        return t;
    end

    local groupIcons = {};
    for i, group in ipairs(GROUPS) do
        groupIcons[i] = getVisibleIcons(group);
        visibleGroups[i] = #groupIcons[i] > 0;
    end

    for i, icons in ipairs(groupIcons) do
        if #icons > 0 then
            local groupW = size;
            for j = 2, #icons do
                local _, rp = self:getIconPadPx(icons[j - 1]);
                local lp, _ = self:getIconPadPx(icons[j]);
                groupW = groupW + size - rp - lp + getIconGap(size);
            end
            groupWidths[i] = groupW;
            totalW = totalW + groupW;
        else
            groupWidths[i] = 0;
        end
    end

    for i = 1, #GROUPS - 1 do
        if visibleGroups[i] then
            for j = i + 1, #GROUPS do
                if visibleGroups[j] then
                    local icons_i = groupIcons[i];
                    local icons_j = groupIcons[j];
                    local _, lastRight = self:getIconPadPx(icons_i[#icons_i]);
                    local firstLeft, _ = self:getIconPadPx(icons_j[1]);
                    totalW = totalW + getGroupGap(size) - lastRight - firstLeft;
                    break;
                end
            end
        end
    end

    self:setWidth(totalW);
    self:setHeight(size);

    self.groupWidths = groupWidths;
    self.visibleGroups = visibleGroups;
    self.groupIcons = groupIcons;
end

function SurvivalHUD:update()
    if self.layoutDirty then
        self:updateLayout();
        self.layoutDirty = false;
    end
end

function SurvivalHUD:trackIconArrows(vals, now)
    for statType, val in pairs(vals) do
        local icon = self.icons[statType];

        if val ~= val then
            icon.lastVal = -1;
        else
            if val ~= icon.lastVal and icon.lastVal ~= -1 then
                icon.arrow.visible = true;
                icon.arrow.time = now;
                icon.arrow.dir = (val > icon.lastVal) and "up" or "down";
            end

            local iconHidden = false;
            if (statType == "Intoxication" and self.sleepNeeded) or statType == "Sickness" then
                iconHidden = val <= 0;
            elseif statType == "Temperature" then
                iconHidden = val >= 36.55 and val <= 37.45;
            else
                iconHidden = val >= 99;
            end

            if icon.arrow.visible
                and (now - icon.arrow.time >= ARROW_DURATION or iconHidden) then
                icon.arrow.visible = false;
            end

            icon.lastVal = val;
        end
    end
end

function SurvivalHUD:drawGroupSeparator(size, rightEdge, leftEdge, alpha)
    local sepCfg = Utils.SeparatorConfig[size];
    if not sepCfg then return; end
    local sepTex = getTexture("media/ui/Separator/" .. sepCfg.texSize .. "/Separator.png");
    if not sepTex then return; end
    local renderSize = sepCfg.renderSize;
    local sepX = math.floor((rightEdge + leftEdge) / 2 - renderSize / 2);
    local sepY = math.floor((size - renderSize) / 2);
    self:drawTextureScaled(sepTex, sepX, sepY, renderSize, renderSize, alpha, 1, 1, 1);
end

function SurvivalHUD:isMouseOverNotBlocked(x, y, w, h)
    if not self:isReallyVisible() then return false; end

    local mx = getMouseX();
    local my = getMouseY();

    local absX = self:getAbsoluteX();
    local absY = self:getAbsoluteY();
    local absW = self:getWidth();
    local absH = self:getHeight();

    if x and y and w and h then
        absX = absX + x;
        absY = absY + y;
        absW = w;
        absH = h;
    end

    if mx < absX or mx >= absX + absW or my < absY or my >= absY + absH then
        return false;
    end

    local uis = UIManager.getUI();
    for i = uis:size() - 1, 0, -1 do
        local other = uis:get(i);
        if other == self.javaObject then break; end
        if other:isVisible() and other:isPointOver(mx, my) then
            local name = tostring(other:toString());
            if not string.find(name, "MoodlesUI") then
                return false;
            end
        end
    end
    return true;
end

function SurvivalHUD:onMouseDown(x, y)
    if getPlayer():isAiming() then return false; end
    return true;
end

function SurvivalHUD:onMouseUp(x, y)
    local player = getPlayer();
    if player:isAiming() then return false; end
    local mx = self:getMouseX();
    local my = self:getMouseY();
    local size = CURRENT_ICON_SIZE;

    local clickTargets = {
        { stat = "Health", view = "IGUI_XP_Health" },
        { stat = "Temperature", view = "IGUI_XP_ClothingIns" },
    };
    for _, t in ipairs(clickTargets) do
        local pos = self.iconPos[t.stat];
        if pos and mx >= pos.x and mx <= pos.x + size and my >= pos.y and my <= pos.y + size then
            if self:isMouseOver() then
                local infopanel = getPlayerInfoPanel(player:getPlayerNum());
                if infopanel then
                    infopanel:toggleView(getText(t.view));
                    getSoundManager():playUISound("UISelectListItem");
                end
                return true;
            end
        end
    end
    return true;
end

function SurvivalHUD:onRightMouseDown(x, y)
    if getPlayer():isAiming() then return false; end
    return true;
end

function SurvivalHUD:onRightMouseUp(x, y)
    if getPlayer():isAiming() then return false; end
    return true;
end

function SurvivalHUD:drawStatusIcon(x, y, statType, val, alpha)
    local icon = self.icons[statType];
    local phase = self:getPhaseData(val, statType);

    if not phase then
        if statType == "Temperature" then
            self.iconPos[statType] = { x = x, y = y };
            local bgTex = getTexture(buildNeutralBgPath(tostring(CURRENT_ICON_SIZE), statType));
            if bgTex then
                self:drawTextureScaled(bgTex, x, y, CURRENT_ICON_SIZE, CURRENT_ICON_SIZE, alpha, 1, 1, 1);
            end
        end
        return;
    end

    self.iconPos[statType] = { x = x, y = y };

    local texVal = self:getBestTexture(val, statType, icon.texVal);
    if texVal then icon.texVal = texVal; end

    local bgPath, iconPath = self:getTexturePaths(statType, phase, icon.texVal);

    local isCritical = CRITICAL_PHASE_LEVELS[statType] and CRITICAL_PHASE_LEVELS[statType][phase[3]];
    if isCritical and getTimestampMs() % CRITICAL_BLINK_PERIOD_MS < CRITICAL_BLINK_PERIOD_MS / 2 then
        bgPath = buildNeutralBgPath(tostring(CURRENT_ICON_SIZE), statType);
    end

    if statType == "Hunger" and val > 95 then
        local player = getPlayer();
        local foodEatenTimer = player:getBodyDamage():getHealthFromFoodTimer();
        local sizeStr = tostring(CURRENT_ICON_SIZE);
        local level, threshold = self:getFoodEatenPhase(foodEatenTimer);
        if level then
            bgPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_" .. level .. ".png";
            iconPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_" .. level .. "_" .. threshold .. ".png";
        end
    end

    local bgTex = getTexture(bgPath);
    if bgTex then
        self:drawTextureScaled(bgTex, x, y, CURRENT_ICON_SIZE, CURRENT_ICON_SIZE, alpha, 1, 1, 1);
    end

    if texVal then
        local iconTex = getTexture(iconPath);
        if iconTex then
            self:drawTextureScaled(iconTex, x, y, CURRENT_ICON_SIZE, CURRENT_ICON_SIZE, alpha, 1, 1, 1);
        end
    end

    if icon.arrow.visible then
        local chevronCfg = CHEVRON_CONFIG[CURRENT_ICON_SIZE];
        if chevronCfg then
            local texSize = chevronCfg.texSize;
            local renderSize = chevronCfg.renderSize;
            local dir = icon.arrow.dir;
            local arrowTex = getTexture("media/ui/Chevron/" .. texSize .. "/Chevron-" .. (dir == "up" and "Up" or "Down") .. ".png");
            if arrowTex then
                local arrowX = x + (CURRENT_ICON_SIZE - renderSize) / 2;
                local arrowY;
                if dir == "up" then
                    arrowY = y - renderSize + ARROW_OFFSET;
                else
                    arrowY = y + CURRENT_ICON_SIZE - ARROW_OFFSET;
                end
                self:drawTextureScaled(arrowTex, arrowX, arrowY, renderSize, renderSize, alpha, 1, 1, 1);
            end
        end
    end

    if DEBUG_PADDING then
        local pad = ICON_VISUAL_PADDING[statType];
        if pad then
            local size = CURRENT_ICON_SIZE;
            local leftW  = math.floor(pad.left  * size);
            local rightW = math.floor(pad.right * size);
            if leftW > 0 then
                self:drawRect(x, y, leftW, size, 0.45, 1, 0.1, 0.1);
            end
            if rightW > 0 then
                self:drawRect(x + size - rightW, y, rightW, size, 0.45, 0.1, 0.4, 1);
            end
        end
    end
end

function SurvivalHUD:updateTooltipHover(vals, isIntoxicationVisible, isSicknessVisible)
    local anyHovered = false;

    for statType, pos in pairs(self.iconPos) do
        local isHovered = self:isMouseOverNotBlocked(pos.x, pos.y, CURRENT_ICON_SIZE, CURRENT_ICON_SIZE);

        if isHovered then
            local iconHidden = (statType == "Intoxication" and not isIntoxicationVisible) or (statType == "Sickness" and not isSicknessVisible);
            if not iconHidden then
                self:prepareTooltip(statType, vals[statType]);
                anyHovered = true;
            end
            break;
        end
    end

    if not anyHovered then
        self.tooltipUI:hideFor("icons");
    end
end

function SurvivalHUD:buildTooltipDescription(statType, val)
    local player = getPlayer();
    local title = getText("Tooltip_HUD_" .. statType);

    local desc;
    if statType == "Temperature" then
        if val ~= val then
            desc = string.format("%s: NaN.", title);
        elseif getCore():getOptionDisplayAsCelsius() then
            desc = string.format("%s: %.1f C.", title, val);
        else
            desc = string.format("%s: %.1f F.", title, val * 9 / 5 + 32);
        end
    elseif (statType == "Intoxication" or statType == "Sickness") and val <= 0 then
        desc = string.format("%s: %s.", title, getText("Tooltip_HUD_None"));
    else
        desc = string.format("%s: %d%%", title, val);
    end

    local weightArrowInfo = nil;
    if statType == "Hunger" then
        local nutrition = player:getNutrition();
        local weight = nutrition:getWeight();
        desc = desc .. string.format("\n%s: %.1f %s", getText("Tooltip_HUD_Weight"), weight, getText("Tooltip_HUD_Weight_Value"));

        if nutrition:isIncWeight() or nutrition:isIncWeightLot() or nutrition:isDecWeight() then
            weightArrowInfo = {
                isIncWeight = nutrition:isIncWeight() and not nutrition:isIncWeightLot(),
                isIncWeightLot = nutrition:isIncWeightLot(),
                isDecWeight = nutrition:isDecWeight(),
            };
        end

        if player:hasTrait(CharacterTrait.NUTRITIONIST) then
            desc = desc .. string.format("\n%s: %.1f", getText("Tooltip_food_Calories"), nutrition:getCalories());
            desc = desc .. string.format("\n%s: %.1f", getText("Tooltip_food_Carbs"), nutrition:getCarbohydrates());
            desc = desc .. string.format("\n%s: %.1f", getText("Tooltip_food_Prots"), nutrition:getProteins());
            desc = desc .. string.format("\n%s: %.1f", getText("Tooltip_food_Fat"), nutrition:getLipids());
        end
    end

    return desc, weightArrowInfo;
end

function SurvivalHUD:buildMoodleDescription(statType, val)
    local player = getPlayer();
    local phase = self:getPhaseData(val, statType);
    if not phase then return nil; end

    local phaseLevel = phase[3];
    local moodleName = nil;

    if statType == "Temperature" then
        if phaseLevel == "0" then return nil; end
        moodleName = (phaseLevel:sub(1, 1) == "+") and "Hyperthermia" or "Hypothermia";
    elseif statType == "Hunger" and val > 95 then
        local foodEatenTimer = player:getBodyDamage():getHealthFromFoodTimer();
        local level = self:getFoodEatenPhase(foodEatenTimer);
        if not level then return nil; end
        moodleName = "FoodEaten";
        phaseLevel = level;
        self.tooltipUI.foodEatenPhase = level;
    elseif phaseLevel ~= 0 then
        moodleName = MOODLE_NAMES[statType] or statType;
    end

    if not moodleName then return nil; end

    local levelSuffix;
    if statType == "Temperature" then
        levelSuffix = phaseLevel:sub(2);
    else
        levelSuffix = tostring(phaseLevel);
    end
    local moodleDesc = getText("Moodles_" .. moodleName .. "_desc_lvl" .. levelSuffix);
    if moodleDesc then
        return "\n\n" .. moodleDesc;
    end
    return nil;
end

function SurvivalHUD:prepareTooltip(statType, val)
    self.tooltipUI.foodEatenPhase = nil;

    local desc, weightArrowInfo = self:buildTooltipDescription(statType, val);
    local moodleDesc = self:buildMoodleDescription(statType, val);
    if moodleDesc then
        desc = desc .. moodleDesc;
    end

    self.tooltipUI:showFor("icons", desc, statType, self.currentValues, weightArrowInfo);
end

function SurvivalHUD:prerender()
    local player = getPlayer();
    if not player or player:isDead() then
        self:setVisible(false);
        return;
    end
    self:setVisible(true);
end

function SurvivalHUD:render()
    if SKIP_RENDER > 0 then
        SKIP_RENDER = SKIP_RENDER - 1;
        return;
    end

    local player = getPlayer();
    if not player then return; end

    local hotbarVis, dashVis, pscDashVis = getPanelsVisible(player:getPlayerNum());
    if not (hotbarVis or dashVis or pscDashVis) then return; end
    if self.cachedHotbarVis ~= hotbarVis or self.cachedDashVis ~= dashVis or self.cachedPscDashVis ~= pscDashVis then
        self:updateLayout();
    end

    local isAiming = player:isAiming();
    local isMouseOver = self:isMouseOverNotBlocked();
    if isAiming and isMouseOver then
        self.fade:setFadeIn(false);
    else
        self.fade:setFadeIn(true);
    end
    self.fade:update();

    local globalAlpha = self.fade:fraction();
    if globalAlpha <= 0 then return; end

    local stats = player:getStats();
    local body = player:getBodyDamage();
    local vals = {
        Fatigue = Utils.clamp100((1 - stats:get(CharacterStat.FATIGUE)) * 100),
        Thirst = Utils.clamp100((1 - stats:get(CharacterStat.THIRST)) * 100),
        Hunger = Utils.clamp100((1 - stats:get(CharacterStat.HUNGER)) * 100),
        Temperature = stats:get(CharacterStat.TEMPERATURE),
        Intoxication = Utils.clamp100(stats:get(CharacterStat.FOOD_SICKNESS)),
        Sickness = Utils.clamp100(stats:get(CharacterStat.SICKNESS) * 100),
        Health = Utils.clamp100(body:getHealth()),
    };

    local isIntoxicationVisible = self:isStatVisible("Intoxication", vals.Intoxication);
    local isSicknessVisible = self:isStatVisible("Sickness", vals.Sickness);

    if self.lastIntoxicationVisible ~= isIntoxicationVisible or self.lastSicknessVisible ~= isSicknessVisible then
        self.lastIntoxicationVisible = isIntoxicationVisible;
        self.lastSicknessVisible = isSicknessVisible;
        self:updateLayout(isIntoxicationVisible, isSicknessVisible);
    end

    self.currentValues = vals;
    self:trackIconArrows(vals, getTimestampMs());

    local curX = 0;
    ---@diagnostic disable-next-line: undefined-field
    table.wipe(self.iconPos);
    local size = CURRENT_ICON_SIZE;

    for i, _ in ipairs(GROUPS) do
        if self.visibleGroups and self.visibleGroups[i] then
            local icons = self.groupIcons and self.groupIcons[i] or {};

            local iconX = curX;
            for j, statType in ipairs(icons) do
                if j > 1 then
                    local _, prevRight = self:getIconPadPx(icons[j - 1]);
                    local curLeft, _ = self:getIconPadPx(statType);
                    iconX = iconX + size - prevRight - curLeft + getIconGap(size);
                end
                self:drawStatusIcon(iconX, 0, statType, vals[statType], globalAlpha);
            end

            curX = curX + self.groupWidths[i];

            if i < #GROUPS then
                for j = i + 1, #GROUPS do
                    if self.visibleGroups[j] then
                        local nextIcons = self.groupIcons and self.groupIcons[j] or {};
                        local _, lastRight = self:getIconPadPx(icons[#icons]);
                        local firstLeft, _ = self:getIconPadPx(nextIcons[1]);

                        local nextGroupStart = curX + getGroupGap(size) - lastRight - firstLeft;
                        self:drawGroupSeparator(size, curX - lastRight, nextGroupStart + firstLeft, globalAlpha * 0.5);

                        curX = nextGroupStart;
                        break;
                    end
                end
            end
        end
    end

    if globalAlpha > TOOLTIP_ALPHA_THRESHOLD and not player:isAiming() then
        self:updateTooltipHover(vals, isIntoxicationVisible, isSicknessVisible);
    else
        self.tooltipUI:hideFor("icons");
    end
end

function SurvivalHUD:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
    o.fade = UITransition.new();
    o.icons = {};
    o.iconPos = {};
    o.sleepNeeded = not isClient() or getServerOptions():getBoolean("SleepNeeded");

    for _, group in ipairs(GROUPS) do
        for _, statType in ipairs(group.icons) do
            local defaultTexVal;
            if statType == "Intoxication" then
                defaultTexVal = 0;
            elseif statType == "Temperature" then
                defaultTexVal = 37;
            else
                defaultTexVal = 100;
            end
            o.icons[statType] = {
                texVal = defaultTexVal,
                lastVal = -1,
                arrow = { visible = false, dir = "up", time = 0 },
            };
        end
    end

    return o;
end

function EnduranceUI:initialise()
    ISPanel.initialise(self);
    self:updateLayout();
end

function EnduranceUI:updateLayout()
    self.scale = CURRENT_ICON_SIZE / 64;
    self.barW = 268 * self.scale;
    self.barH = 8 * self.scale;
    self.iconSize = 32 * self.scale;

    local spacing = 10 * self.scale;
    local totalW = self.iconSize + spacing + self.barW;

    self:setWidth(totalW);
    self:setHeight(math.max(self.barH, self.iconSize));
    self:setX(20);
    self:setY(getCore():getScreenHeight() - 15 - self:getHeight());
end

function EnduranceUI:getPhase(val)
    if val <= 0.10 then
        return 4;
    elseif val <= 0.25 then
        return 3;
    elseif val <= 0.50 then
        return 2;
    elseif val <= 0.75 then
        return 1;
    else
        return 0;
    end
end

function EnduranceUI:getColor(val)
    local phase = self:getPhase(val);
    return PHASE_COLORS[phase] or { r = 1, g = 1, b = 1 };
end

function EnduranceUI:onMouseDown(x, y)
    if getPlayer():isAiming() then return false; end
    return true;
end

function EnduranceUI:onMouseUp(x, y)
    if getPlayer():isAiming() then return false; end
    return true;
end

function EnduranceUI:onRightMouseDown(x, y)
    if getPlayer():isAiming() then return false; end
    return true;
end

function EnduranceUI:onRightMouseUp(x, y)
    if getPlayer():isAiming() then return false; end
    return true;
end

function EnduranceUI:update()
    if self.layoutDirty then
        self:updateLayout();
        self.layoutDirty = false;
    end
end

function EnduranceUI:render()
    if SKIP_RENDER > 0 then return; end

    local player = getPlayer();
    if not player or player:isDead() then
        self:setVisible(false);
        return;
    end

    local hotbarVis, dashVis, pscDashVis = getPanelsVisible(player:getPlayerNum());
    if not (hotbarVis or dashVis or pscDashVis) then return; end

    self:setVisible(true);

    local val = player:getStats():get(CharacterStat.ENDURANCE);

    local provider = EnduranceUI.capacityProvider;
    local capFrac = provider and provider(player) or nil;
    if capFrac then
        self.displayVal = self.displayVal and (self.displayVal + (val - self.displayVal) * 0.2) or val;
        val = self.displayVal;
    end

    local isAiming = player:isAiming();
    if isAiming and self:isMouseOver() then
        self.fade:setFadeIn(false);
    else
        self.fade:setFadeIn(true);
    end
    self.fade:update();

    local globalAlpha = self.fade:fraction();
    if globalAlpha <= 0 then return; end

    local phase = self:getPhase(val);
    local sizeStr = tostring(CURRENT_ICON_SIZE);
    local runTex = getTexture("media/ui/Needs/" .. sizeStr .. "/Endurance/Endurance_" .. phase .. ".png");

    if runTex then
        self:drawTextureScaled(runTex, 0, (self:getHeight() - self.iconSize) / 2, self.iconSize, self.iconSize, globalAlpha, 1, 1, 1);
    end

    local barX = self.iconSize + 10 * self.scale;
    local barY = (self:getHeight() - self.barH) / 2;

    local fillW = math.max(0, self.barW * val);

    if capFrac then
        local capW = math.floor(math.min(self.barW * capFrac, self.barW) + 0.5);
        fillW = math.min(math.floor(fillW + 0.5), capW);
        self:drawRect(barX, barY, capW, self.barH, GHOST_ALPHA * globalAlpha, 1, 1, 1);
        if capW < self.barW then
            self:drawRect(barX + capW, barY, self.barW - capW, self.barH, 0.5 * globalAlpha, 0, 0, 0);
        end
    else
        self:drawRect(barX, barY, self.barW, self.barH, 0.5 * globalAlpha, 0, 0, 0);
    end

    local col = self:getColor(val);
    if fillW > 0 then
        self:drawRect(barX, barY, fillW, self.barH, globalAlpha, col.r, col.g, col.b);
    end

    local weapon = getRangedWeapon(player);
    if weapon and weapon:getMaxAmmo() > 0 then
        local font = self.scale < 1 and UIFont.Small or UIFont.Medium;
        local statusText = getAmmoDisplayText(weapon);
        local statusWidth = getTextManager():MeasureStringX(font, statusText);
        local fontHgt = getTextManager():getFontHeight(font);
        local textY = barY - fontHgt - 6 * self.scale;
        local nameMaxWidth = self.barW - statusWidth - 8 * self.scale;

        local name = truncateNameToWidth(weapon:getDisplayName(), font, nameMaxWidth);
        if name then
            self:drawText(name, barX + 1, textY + 1, 0, 0, 0, globalAlpha, font);
            self:drawText(name, barX, textY, 1, 1, 1, globalAlpha, font);
        end
        self:drawTextRight(statusText, barX + self.barW + 1, textY + 1, 0, 0, 0, globalAlpha, font);
        self:drawTextRight(statusText, barX + self.barW, textY, 1, 1, 1, globalAlpha, font);
    end

    if globalAlpha > TOOLTIP_ALPHA_THRESHOLD and self:isMouseOver() and not player:isAiming() then
        local title = getText("Tooltip_HUD_Endurance");
        local desc = string.format("%s: %d%%", title, math.floor(val * 100 + 0.5));

        if phase > 0 then
            local moodleDesc = getText("Moodles_Endurance_desc_lvl" .. phase);
            if moodleDesc then
                desc = desc .. "\n" .. moodleDesc;
            end
        end

        local currentValues = { Endurance = val };
        SurvivalHUD.instance.tooltipUI:showFor("endurance", desc, "Endurance", currentValues, nil);
    else
        SurvivalHUD.instance.tooltipUI:hideFor("endurance");
    end
end

function EnduranceUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
    o.fade = UITransition.new();

    return o;
end

local function onCreatePlayer()
    if SurvivalHUD.instance then
        if SurvivalHUD.instance.tooltipUI then
            SurvivalHUD.instance.tooltipUI:removeFromUIManager();
        end
        SurvivalHUD.instance:removeFromUIManager();
    end
    if EnduranceUI.instance then
        EnduranceUI.instance:removeFromUIManager();
    end

    SurvivalHUD.instance = SurvivalHUD:new(0, 0, 100, 100);
    SurvivalHUD.instance:initialise();
    SurvivalHUD.instance:addToUIManager();
    SurvivalHUD.instance:backMost();

    EnduranceUI.instance = EnduranceUI:new(0, 0, 100, 100);
    EnduranceUI.instance:initialise();
    EnduranceUI.instance:addToUIManager();
    EnduranceUI.instance:backMost();

    SurvivalHUD.instance.layoutDirty = true;
    EnduranceUI.instance.layoutDirty = true;
end

local function onResolutionChange()
    SKIP_RENDER = 15;
    if SurvivalHUD.instance then SurvivalHUD.instance.layoutDirty = true; end
    if EnduranceUI.instance then EnduranceUI.instance.layoutDirty = true; end
end

local function onPlayerUpdate()
    if SurvivalHUD.instance then
        SurvivalHUD.instance.layoutDirty = true;
    end
    if EnduranceUI.instance then
        EnduranceUI.instance.layoutDirty = true;
    end
end

local function onPlayerDeath()
    if SurvivalHUD.instance then
        if SurvivalHUD.instance.tooltipUI then
            SurvivalHUD.instance.tooltipUI:removeFromUIManager();
        end
        SurvivalHUD.instance:removeFromUIManager();
        SurvivalHUD.instance = nil;
    end
    if EnduranceUI.instance then
        EnduranceUI.instance:removeFromUIManager();
        EnduranceUI.instance = nil;
    end
end

local function onGameBoot()
    for _, size in ipairs({ 48, 64, 80 }) do
        local sizeStr = tostring(size);

        for statType, phases in pairs(PHASES) do
            for _, phase in ipairs(phases) do
                local bgPath = buildTexturePaths(sizeStr, statType, phase, phase[4][1]);
                getTexture(bgPath);
                for _, val in ipairs(phase[4]) do
                    local _, iconPath = buildTexturePaths(sizeStr, statType, phase, val);
                    getTexture(iconPath);
                end
            end
        end

        for i = 0, 4 do
            getTexture("media/ui/Needs/" .. sizeStr .. "/Endurance/Endurance_" .. i .. ".png");
        end

        for _, t in ipairs(FOOD_EATEN_THRESHOLDS) do
            getTexture("media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_" .. t.level .. ".png");
            getTexture("media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_" .. t.level .. "_" .. t.timer .. ".png");
        end
    end

    for _, texSize in ipairs({ 16, 24, 32 }) do
        getTexture("media/ui/Chevron/" .. texSize .. "/Chevron-Up.png");
        getTexture("media/ui/Chevron/" .. texSize .. "/Chevron-Down.png");
    end

    for _, texSize in ipairs({ 32, 48, 64 }) do
        getTexture("media/ui/Separator/" .. texSize .. "/Separator.png");
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer);
Events.OnPlayerDeath.Add(onPlayerDeath);
Events.OnResolutionChange.Add(onResolutionChange);
Events.OnClothingUpdated.Add(onPlayerUpdate);
Events.OnEnterVehicle.Add(onPlayerUpdate);
Events.OnExitVehicle.Add(onPlayerUpdate);
Events.OnSwitchVehicleSeat.Add(onPlayerUpdate);

Events.OnGameBoot.Add(onGameBoot);