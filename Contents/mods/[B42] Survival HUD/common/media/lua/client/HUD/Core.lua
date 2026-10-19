require "ISUI/ISPanel";

local Utils = require("HUD/Utils");

NeedsUI = ISPanel:derive("NeedsUI");
EnduranceUI = ISPanel:derive("EnduranceUI");

NeedsUI.instance = nil;
EnduranceUI.instance = nil;

local BASE_ICON_SIZE = 64;
local BOTTOM_OFFSET_BASE, RIGHT_OFFSET_BASE = 15, 15;

local CHEVRON_CONFIG = {
    [48] = { size = 12, offsets = { [1] = 3, [2] = 1.5 } },
    [64] = { size = 16, offsets = { [1] = 5, [2] = 2.5 } },
    [80] = { size = 20, offsets = { [1] = 6, [2] = 3 } },
};

local COMPACT_ICON_SIZE_MAP = {
    [80] = 64,
    [64] = 48,
    [48] = 32,
};

local function radToStage(radius)
    if not radius or radius <= 0 then
        return 0;
    elseif radius <= 4 then
        return 1;
    elseif radius <= 8 then
        return 2;
    elseif radius <= 12 then
        return 3;
    else
        return 4;
    end
end

local SAMPLE_INTERVAL_MS = 400;

local ARROW_THRESHOLDS = {
    Health = {
        tier1_enter = 0.005,
        tier1_exit = 0.002,
        tier2_enter = 0.150,
        tier2_exit = 0.100,
    },
    Hunger = {
        tier1_enter = 0.003,
        tier1_exit = 0.0015,
        tier2_enter = 0.030,
        tier2_exit = 0.024,
    },
    Thirst = {
        tier1_enter = 0.003,
        tier1_exit = 0.0015,
        tier2_enter = 0.035,
        tier2_exit = 0.027,
    },
    Fatigue = {
        tier1_enter = 0.003,
        tier1_exit = 0.0015,
        tier2_enter = 0.030,
        tier2_exit = 0.024,
    },
    Temperature = {
        tier1_enter = 0.003,
        tier1_exit = 0.0015,
        tier2_enter = 0.025,
        tier2_exit = 0.018,
    },
    Sickness = {
        tier1_enter = 0.005,
        tier1_exit = 0.002,
        tier2_enter = 0.050,
        tier2_exit = 0.035,
    },
    Intoxication = {
        tier1_enter = 0.005,
        tier1_exit = 0.002,
        tier2_enter = 0.050,
        tier2_exit = 0.035,
    },
};

local TOOLTIP_ALPHA_THRESHOLD = 0.9;

local CRITICAL_BLINK_PERIOD_MS = 1000;

local FOOD_EATEN_THRESHOLDS = {
    { timer = 4800, level = 4 },
    { timer = 3200, level = 3 },
    { timer = 1600, level = 2 },
    { timer = 0, level = 1 },
};

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

local function getBottomOffset(size)
    return math.floor(BOTTOM_OFFSET_BASE * size / 64 + 0.5);
end

local function getSideOffset(size)
    return math.floor(RIGHT_OFFSET_BASE * size / 64 + 0.5);
end

local ICON_VISUAL_PADDING = {
    Fatigue = { left = 0.24, right = 0.24 },
    Thirst = { left = 0.32, right = 0.32 },
    Hunger = { left = 0.09, right = 0.10 },
    Temperature  = { left = 0.30, right = 0.30 },
    Intoxication = { left = 0.04, right = 0.04 },
    Sickness = { left = 0.07, right = 0.07 },
    Health = { left = 0.07, right = 0.07 },
    Radius = { left = 0.19, right = 0.19 },
    Endurance = { left = 0.09, right = 0.07 },
};

local function getVisualPadPx(statType, size)
    local pad = ICON_VISUAL_PADDING[statType];
    return pad and math.floor(size * pad.left) or 0, pad and math.floor(size * pad.right) or 0;
end

local DEBUG_PADDING = false;

local function getPanelsVisible(playerNum)
    local hotbar = getPlayerHotbar(playerNum);
    local dash = getPlayerVehicleDashboard(playerNum);
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(playerNum);
    return hotbar and hotbar:isReallyVisible(), dash and dash:isReallyVisible(), pscDash and pscDash:isReallyVisible();
end

local function hasOpenWoundOrDirtyBandage(player)
    if not player then return false; end
    local bodyParts = player:getBodyDamage():getBodyParts();

    for i = 1, bodyParts:size() do
        local part = bodyParts:get(i - 1);
        if part:bandaged() then
            if part:isBandageDirty() then
                return true;
            end
        else
            if part:bleeding()
                or part:scratched()
                or part:isCut()
                or part:deepWounded()
                or part:bitten()
                or part:haveBullet()
                or part:haveGlass()
                or part:getBurnTime() > 0
                or part:stitched()
                or part:isInfectedWound() then
                return true;
            end
        end
    end
    return false;
end

local MOODLE_NAMES = {
    Fatigue = "Tired",
    Thirst = "Thirst",
    Hunger = "Hungry",
    Intoxication = "Sick",
    Sickness = "Sick",
    Health = "Injured",
};

local Tooltip = ISPanel:derive("NeedsUI_Tooltip");

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
    local val = self.currentValues and self.currentValues["Endurance"];
    if not val then return 1, 1, 1; end
    local phase = EnduranceUI.instance and EnduranceUI.instance:getPhase(val) or 0;
    local color = PHASE_COLORS[phase];
    if color then
        return color.r, color.g, color.b;
    end
    return 1, 1, 1;
end

function Tooltip:getStatLineColor()
    if not self.currentValues or not NeedsUI.instance then return 1, 1, 1; end
    local phase = NeedsUI.instance:getPhaseData(
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
                local arrowY = math.floor(curY + (lineHeight - arrowTex:getHeight()) / 2);
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

function NeedsUI:initialise()
    ISPanel.initialise(self);
    self.iconSize = BASE_ICON_SIZE;
    self.layoutDirty = true;

    self.tooltipUI = Tooltip:new(0, 0, 0, 0);
    self.tooltipUI:initialise();
    self.tooltipUI:addToUIManager();
    self.tooltipUI:setVisible(false);
end

function NeedsUI:setBaseIconSize(size)
    BASE_ICON_SIZE = size;
    if NeedsUI.instance then
        NeedsUI.instance.layoutDirty = true;
    end
    if EnduranceUI.instance then
        EnduranceUI.instance.layoutDirty = true;
    end
end

function NeedsUI:getBaseIconSize()
    return BASE_ICON_SIZE;
end

function NeedsUI:getPhaseData(val, statType)
    if not val or val ~= val then return nil; end
    local phases = PHASES[statType];
    if not phases then return nil; end

    if val >= phases[1][2] then
        return phases[1];
    end
    if val <= phases[#phases][1] then
        return phases[#phases];
    end

    for _, phase in ipairs(phases) do
        if val >= phase[1] and val <= phase[2] then
            return phase;
        end
    end

    if statType == "Temperature" then
        return (val >= 37) and phases[1] or phases[#phases];
    end
    return phases[#phases];
end

local function getFoodEatenPhase(timer)
    if timer <= 0 then return nil; end
    for _, t in ipairs(FOOD_EATEN_THRESHOLDS) do
        if timer > t.timer then return t.level, t.timer; end
    end
    return nil;
end

function NeedsUI:isStatVisible(statType, val)
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

function NeedsUI:getBestTexture(val, statType, currentTexVal)
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
        if statType == "Temperature" then return 37; end
        return nil;
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

local function isIntersecting(x1, y1, w1, h1, x2, y2, w2, h2)
    return not (x1 + w1 < x2 or x2 + w2 < x1 or y1 + h1 < y2 or y2 + h2 < y1);
end

local function checkUICollision(hud, ui)
    if not ui then return false; end
    if not ui:isReallyVisible() then return false; end
    if ui:getWidth() <= 0 or ui:getHeight() <= 0 then return false; end

    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    local uiX = ui:getAbsoluteX();
    local uiY = ui:getAbsoluteY();
    local uiW = ui:getWidth();
    local uiH = ui:getHeight();

    local myX = screenW - hud:getWidth() - getSideOffset(hud.iconSize);
    local myY = screenH - getBottomOffset(hud.iconSize) - hud.iconSize;
    local myW = hud:getWidth();
    local myH = hud.iconSize;

    if isIntersecting(myX, myY, myW, myH, uiX, uiY, uiW, uiH) then
        return true;
    end

    local endurance = EnduranceUI.instance;
    if endurance and endurance:isReallyVisible() then
        if isIntersecting(endurance:getAbsoluteX(), endurance:getAbsoluteY(), endurance:getWidth(), endurance:getHeight(), uiX, uiY, uiW, uiH) then
            return true;
        end
    end

    return false;
end

local function resolveCollisionWith(hud, ui, isIntoxicationVisible, isSicknessVisible)
    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    while checkUICollision(hud, ui) do
        local nextIconSize = Utils.getNextSmallerSize(Utils.CollisionSizes, hud.iconSize);
        if nextIconSize then
            hud.iconSize = nextIconSize;
            if EnduranceUI.instance then
                EnduranceUI.instance:updateLayout();
            end
            hud:recalcDimensions(isIntoxicationVisible, isSicknessVisible);
            hud:setX(screenW - hud:getWidth() - getSideOffset(hud.iconSize));
            hud:setY(screenH - getBottomOffset(hud.iconSize) - hud.iconSize);
        elseif ui.availableSlot and ui.setSlotSize then
            local nextHotbarSize = Utils.getNextSmallerSize(Utils.CollisionSizes, ui.slotSize);
            if not nextHotbarSize then break; end
            ui:setSlotSize(nextHotbarSize);
        else
            break;
        end
    end
end

function NeedsUI:updateLayout(isIntoxicationVisible, isSicknessVisible)
    local player = getPlayer();
    if not player or player:isDead() then return; end

    if isIntoxicationVisible == nil then
        isIntoxicationVisible = self:isStatVisible("Intoxication", player:getStats():get(CharacterStat.FOOD_SICKNESS));
    end
    if isSicknessVisible == nil then
        isSicknessVisible = self:isStatVisible("Sickness", player:getStats():get(CharacterStat.SICKNESS));
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum());
    local dash = getPlayerVehicleDashboard(player:getPlayerNum());
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(player:getPlayerNum());
    local vehicle = player:getVehicle();

    self.iconSize = BASE_ICON_SIZE;
    if hotbar then
        hotbar:setSlotSize(ISHotbar:getBaseSlotSize());
    end
    if EnduranceUI.instance then
        EnduranceUI.instance:updateLayout();
    end
    self:recalcDimensions(isIntoxicationVisible, isSicknessVisible);

    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    self:setX(screenW - self:getWidth() - getSideOffset(self.iconSize));
    self:setY(screenH - getBottomOffset(self.iconSize) - self.iconSize);

    if vehicle and vehicle:isDriver(player) and pscDash then
        resolveCollisionWith(self, pscDash, isIntoxicationVisible, isSicknessVisible);
    end
    if vehicle and vehicle:isDriver(player) and dash then
        resolveCollisionWith(self, dash, isIntoxicationVisible, isSicknessVisible);
    end
    if hotbar then
        resolveCollisionWith(self, hotbar, isIntoxicationVisible, isSicknessVisible);
    end

    self.cachedHotbarVis = hotbar and hotbar:isReallyVisible();
    self.cachedDashVis = dash and dash:isReallyVisible();
    self.cachedPscDashVis = pscDash and pscDash:isReallyVisible();
    self.layoutDirty = false;
end

function NeedsUI:recalcDimensions(showIntoxication, showSickness)
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
            local groupW = self.iconSize;
            for j = 2, #icons do
                local _, rp = getVisualPadPx(icons[j - 1], self.iconSize);
                local lp, _ = getVisualPadPx(icons[j], self.iconSize);
                groupW = groupW + self.iconSize - rp - lp + getIconGap(self.iconSize);
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
                    local _, lastRight = getVisualPadPx(icons_i[#icons_i], self.iconSize);
                    local firstLeft, _ = getVisualPadPx(icons_j[1], self.iconSize);
                    totalW = totalW + getGroupGap(self.iconSize) - lastRight - firstLeft;
                    break;
                end
            end
        end
    end

    self:setWidth(totalW);
    self:setHeight(self.iconSize);

    self.groupWidths = groupWidths;
    self.visibleGroups = visibleGroups;
    self.groupIcons = groupIcons;
end

function NeedsUI:update()
    if self.layoutDirty then
        self:updateLayout();
    end
end

local function getGameSeconds()
    local gt = getGameTime();
    if not gt then return 0; end
    local minutesPerDay = gt:getMinutesPerDay() or 60;
    return gt:getWorldAgeHours() * (minutesPerDay * 2.5);
end

local function getArrowThresholds(statType, player)
    local base = ARROW_THRESHOLDS[statType];
    local mult = 1.0;

    if player and (statType == "Hunger" or statType == "Thirst" or statType == "Fatigue") then
        local sb = getSandboxOptions();
        if sb and sb.getStatsDecreaseMultiplier then
            mult = mult * sb:getStatsDecreaseMultiplier();
        end

        if statType == "Thirst" then
            if player:hasTrait(CharacterTrait.HIGH_THIRST) then
                mult = mult * 2.0;
            elseif player:hasTrait(CharacterTrait.LOW_THIRST) then
                mult = mult * 0.5;
            end
        elseif statType == "Hunger" then
            if player:hasTrait(CharacterTrait.HEARTY_APPETITE) then
                mult = mult * 1.5;
            elseif player:hasTrait(CharacterTrait.LIGHT_EATER) then
                mult = mult * 0.75;
            end
        elseif statType == "Fatigue" then
            if player:hasTrait(CharacterTrait.NEEDS_MORE_SLEEP) then
                mult = mult * 1.3;
            elseif player:hasTrait(CharacterTrait.NEEDS_LESS_SLEEP) then
                mult = mult * 0.7;
            end
        end
    end

    if mult == 1.0 then
        return base;
    end

    return {
        tier1_enter = base.tier1_enter * mult,
        tier1_exit = base.tier1_exit * mult,
        tier2_enter = base.tier2_enter * mult,
        tier2_exit = base.tier2_exit * mult,
    };
end

function NeedsUI:trackIconArrows(vals, now)
    local gameSec = getGameSeconds();
    local player = getPlayer();

    for statType, val in pairs(vals) do
        local icon = self.icons[statType];

        if not val or val ~= val or val < 0 then
            icon.sampleVal = -1;
            icon.sampleTime = 0;
            icon.sampleGameSec = 0;
            icon.rateTier = 0;
            icon.filteredRate = 0;
            icon.arrow.visible = false;
            icon.arrow.tier = 0;
        elseif not self:isStatVisible(statType, val) then
            icon.arrow.visible = false;
            icon.arrow.tier = 0;
            icon.rateTier = 0;
            icon.filteredRate = 0;
            icon.sampleVal = val;
            icon.sampleTime = now;
            icon.sampleGameSec = gameSec;
        elseif icon.sampleTime == 0 or icon.sampleVal == -1 then
            icon.sampleVal = val;
            icon.sampleTime = now;
            icon.sampleGameSec = gameSec;
        else
            local timeDelta = now - icon.sampleTime;
            local valDelta = val - icon.sampleVal;
            local dtGame = gameSec - icon.sampleGameSec;
            local isSpike = (statType == "Temperature") and (math.abs(valDelta) >= 0.2) or (math.abs(valDelta) >= 1.0);

            if timeDelta >= SAMPLE_INTERVAL_MS or isSpike then
                if dtGame > 0.05 and dtGame < 300.0 then
                    local rawRate = valDelta / dtGame;
                    local alpha = 0.6;
                    icon.filteredRate = icon.filteredRate + (rawRate - icon.filteredRate) * alpha;

                    local cfg = getArrowThresholds(statType, player);
                    local rate = icon.filteredRate;
                    local absRate = math.abs(rate);
                    local targetDir = (rate > 0) and "up" or "down";

                    local curRateTier = icon.rateTier;
                    local targetRateTier = curRateTier;

                    if curRateTier == 0 then
                        if absRate >= cfg.tier2_enter then
                            targetRateTier = 2;
                        elseif absRate >= cfg.tier1_enter then
                            targetRateTier = 1;
                        end
                    elseif curRateTier == 1 then
                        if absRate >= cfg.tier2_enter then
                            targetRateTier = 2;
                        elseif absRate < cfg.tier1_exit then
                            targetRateTier = 0;
                        end
                    elseif curRateTier == 2 then
                        if absRate < cfg.tier2_exit then
                            targetRateTier = (absRate >= cfg.tier1_exit) and 1 or 0;
                        end
                    end

                    icon.rateTier = targetRateTier;

                    if icon.rateTier > 0 then
                        icon.arrow.tier = icon.rateTier;
                        icon.arrow.dir = targetDir;
                        icon.arrow.visible = true;
                    else
                        icon.arrow.tier = 0;
                        icon.arrow.visible = false;
                    end
                else
                    icon.filteredRate = 0;
                    icon.rateTier = 0;
                    icon.arrow.tier = 0;
                    icon.arrow.visible = false;
                end

                icon.sampleVal = val;
                icon.sampleTime = now;
                icon.sampleGameSec = gameSec;
            end
        end
    end
end

local function drawGroupSeparator(self, size, rightEdge, leftEdge, alpha)
    local sepSize = Utils.SeparatorConfig[size];
    if not sepSize then return; end
    local sepTex = getTexture("media/ui/Separator/" .. sepSize .. "/Separator.png");
    if not sepTex then return; end
    local sepX = math.floor((rightEdge + leftEdge) / 2 - sepSize / 2);
    local sepY = math.floor((size - sepSize) / 2);
    self:drawTexture(sepTex, sepX, sepY, alpha, 1, 1, 1);
end

function NeedsUI:isMouseOverNotBlocked(x, y, w, h)
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

local function swallowUnlessAiming()
    local player = getPlayer();
    return not (player and player:isAiming());
end

NeedsUI.onMouseDown = swallowUnlessAiming;
NeedsUI.onRightMouseDown = swallowUnlessAiming;
NeedsUI.onRightMouseUp = swallowUnlessAiming;

function NeedsUI:onMouseUp(x, y)
    local player = getPlayer();
    if player:isAiming() then return false; end

    local clickTargets = {
        { stat = "Health", view = "IGUI_XP_Health" },
        { stat = "Temperature", view = "IGUI_XP_ClothingIns" },
    };
    for _, t in ipairs(clickTargets) do
        local pos = self.iconPos[t.stat];
        if pos and pos.visible then
            local leftPad, rightPad = getVisualPadPx(t.stat, self.iconSize);
            local hitX = pos.x + leftPad;
            local hitW = self.iconSize - leftPad - rightPad;
            if x >= hitX and x <= hitX + hitW and y >= pos.y and y <= pos.y + self.iconSize then
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
    end
    return true;
end

function NeedsUI:drawStatusIcon(x, y, statType, val, alpha)
    local sizeStr = tostring(self.iconSize);
    local icon = self.icons[statType];
    local phase = self:getPhaseData(val, statType);

    if not phase then
        if statType == "Temperature" then
            local pos = self.iconPos[statType];
            pos.x = x;
            pos.y = y;
            pos.visible = true;
            local bgTex = getTexture(buildNeutralBgPath(sizeStr, statType));
            if bgTex then
                self:drawTextureScaled(bgTex, x, y, self.iconSize, self.iconSize, alpha, 1, 1, 1);
            end
        end
        return;
    end

    local pos = self.iconPos[statType];
    pos.x = x;
    pos.y = y;
    pos.visible = true;

    local texVal = self:getBestTexture(val, statType, icon.texVal);
    if texVal then icon.texVal = texVal; end

    local bgPath, iconPath = buildTexturePaths(sizeStr, statType, phase, icon.texVal);

    local isCritical = CRITICAL_PHASE_LEVELS[statType] and CRITICAL_PHASE_LEVELS[statType][phase[3]];
    if isCritical and getTimestampMs() % CRITICAL_BLINK_PERIOD_MS < CRITICAL_BLINK_PERIOD_MS / 2 then
        bgPath = buildNeutralBgPath(sizeStr, statType);
    end

    if statType == "Hunger" and val > 95 then
        local player = getPlayer();
        local foodEatenTimer = player:getBodyDamage():getHealthFromFoodTimer();
        local level, threshold = getFoodEatenPhase(foodEatenTimer);
        if level then
            bgPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_" .. level .. ".png";
            iconPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_" .. level .. "_" .. threshold .. ".png";
        end
    end

    local fillAlpha = alpha;
    if statType == "Health" and hasOpenWoundOrDirtyBandage(getPlayer()) then
        local pulseProgress = (getTimestampMs() % CRITICAL_BLINK_PERIOD_MS) / CRITICAL_BLINK_PERIOD_MS;
        local pulse = 0.75 - 0.25 * math.cos(pulseProgress * (math.pi * 2));
        fillAlpha = alpha * pulse;
    end

    local bgTex = getTexture(bgPath);
    if bgTex then
        self:drawTextureScaled(bgTex, x, y, self.iconSize, self.iconSize, alpha, 1, 1, 1);
    end

    if texVal then
        local iconTex = getTexture(iconPath);
        if iconTex then
            self:drawTextureScaled(iconTex, x, y, self.iconSize, self.iconSize, fillAlpha, 1, 1, 1);
        end
    end

    if icon.arrow.visible and icon.arrow.tier > 0 then
        local chevronCfg = CHEVRON_CONFIG[self.iconSize];
        if chevronCfg then
            local arrowSize = chevronCfg.size;
            local dirName = (icon.arrow.dir == "up") and "Up" or "Down";
            local arrowTex = getTexture("media/ui/Arrow/" .. arrowSize .. "/" .. icon.arrow.tier .. "x_" .. dirName .. ".png");
            if arrowTex then
                local arrowOffset = CHEVRON_CONFIG[self.iconSize].offsets[icon.arrow.tier];
                local arrowX = math.floor(x + (self.iconSize - arrowSize) / 2);
                local arrowY;
                if icon.arrow.dir == "up" then
                    arrowY = math.floor(y - arrowSize + arrowOffset);
                else
                    arrowY = math.floor(y + self.iconSize - arrowOffset);
                end
                self:drawTexture(arrowTex, arrowX, arrowY, alpha, 1, 1, 1);
            end
        end
    end

    if DEBUG_PADDING then
        local pad = ICON_VISUAL_PADDING[statType];
        if pad then
            local leftW  = math.floor(pad.left  * self.iconSize);
            local rightW = math.floor(pad.right * self.iconSize);
            if leftW > 0 then
                self:drawRect(x, y, leftW, self.iconSize, 0.45, 1, 0.1, 0.1);
            end
            if rightW > 0 then
                self:drawRect(x + self.iconSize - rightW, y, rightW, self.iconSize, 0.45, 0.1, 0.4, 1);
            end
        end
    end
end

function NeedsUI:updateTooltipHover(vals, isIntoxicationVisible, isSicknessVisible)
    local anyHovered = false;

    for statType, pos in pairs(self.iconPos) do
        local leftPad, rightPad = getVisualPadPx(statType, self.iconSize);
        local hitX = pos.x + leftPad;
        local hitW = self.iconSize - leftPad - rightPad;
        local isHovered = pos.visible and self:isMouseOverNotBlocked(hitX, pos.y, hitW, self.iconSize);

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

local function buildTooltipDescription(statType, val)
    local player = getPlayer();
    local title = getText("Tooltip_HUD_" .. statType);

    local desc;
    if statType == "Temperature" then
        if not val or val ~= val then
            desc = string.format("%s: NaN.", title);
        elseif getCore():getOptionDisplayAsCelsius() then
            desc = string.format("%s: %.1f C.", title, val);
        else
            desc = string.format("%s: %.1f F.", title, val * 9 / 5 + 32);
        end
    elseif (statType == "Intoxication" or statType == "Sickness") and (not val or val <= 0) then
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

local function buildMoodleDescription(self, statType, val)
    local player = getPlayer();
    local phase = self:getPhaseData(val, statType);
    if not phase then return nil, nil; end

    local phaseLevel = phase[3];
    local moodleName = nil;
    local foodEatenPhase = nil;

    if statType == "Temperature" then
        if phaseLevel == "0" then return nil, nil; end
        moodleName = (phaseLevel:sub(1, 1) == "+") and "Hyperthermia" or "Hypothermia";
    elseif statType == "Hunger" and val > 95 then
        local foodEatenTimer = player:getBodyDamage():getHealthFromFoodTimer();
        local level = getFoodEatenPhase(foodEatenTimer);
        if not level then return nil, nil; end
        moodleName = "FoodEaten";
        phaseLevel = level;
        foodEatenPhase = level;
    elseif phaseLevel ~= 0 then
        moodleName = MOODLE_NAMES[statType];
    end

    if not moodleName then return nil, foodEatenPhase; end

    local levelSuffix = (statType == "Temperature") and phaseLevel:sub(2) or tostring(phaseLevel);
    local moodleDesc = getText("Moodles_" .. moodleName .. "_desc_lvl" .. levelSuffix);
    if moodleDesc then
        return "\n\n" .. moodleDesc, foodEatenPhase;
    end
    return nil, foodEatenPhase;
end

function NeedsUI:prepareTooltip(statType, val)
    local desc, weightArrowInfo = buildTooltipDescription(statType, val);
    local moodleDesc, foodEatenPhase = buildMoodleDescription(self, statType, val);
    if moodleDesc then
        desc = desc .. moodleDesc;
    end

    self.tooltipUI.foodEatenPhase = foodEatenPhase;
    self.tooltipUI:showFor("icons", desc, statType, self.currentValues, weightArrowInfo);
end

function NeedsUI:prerender()
    local player = getPlayer();
    if not player or player:isDead() then
        self:setVisible(false);
        return;
    end
    self:setVisible(true);
end

function NeedsUI:render()
    if self.skipRender and self.skipRender > 0 then
        self.skipRender = self.skipRender - 1;
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
    for _, pos in pairs(self.iconPos) do
        pos.visible = false;
    end

    for i, _ in ipairs(GROUPS) do
        if self.visibleGroups and self.visibleGroups[i] then
            local icons = self.groupIcons[i];

            local iconX = curX;
            for j, statType in ipairs(icons) do
                if j > 1 then
                    local _, prevRight = getVisualPadPx(icons[j - 1], self.iconSize);
                    local curLeft, _ = getVisualPadPx(statType, self.iconSize);
                    iconX = iconX + self.iconSize - prevRight - curLeft + getIconGap(self.iconSize);
                end
                self:drawStatusIcon(iconX, 0, statType, vals[statType], globalAlpha);
            end

            curX = curX + self.groupWidths[i];

            if i < #GROUPS then
                for j = i + 1, #GROUPS do
                    if self.visibleGroups[j] then
                        local nextIcons = self.groupIcons[j];
                        local _, lastRight = getVisualPadPx(icons[#icons], self.iconSize);
                        local firstLeft, _ = getVisualPadPx(nextIcons[1], self.iconSize);

                        local nextGroupStart = curX + getGroupGap(self.iconSize) - lastRight - firstLeft;
                        drawGroupSeparator(self, self.iconSize, curX - lastRight, nextGroupStart + firstLeft, globalAlpha * 0.5);

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

function NeedsUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
    o.fade = UITransition.new();
    o.skipRender = 0;
    o.iconSize = BASE_ICON_SIZE;
    o.icons = {};
    o.iconPos = {};
    o.sleepNeeded = not isClient() or (getServerOptions():getBoolean("SleepNeeded") and getServerOptions():getBoolean("SleepAllowed"));

    for _, group in ipairs(GROUPS) do
        for _, statType in ipairs(group.icons) do
            o.iconPos[statType] = { x = 0, y = 0, visible = false };
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
                sampleVal = -1,
                sampleTime = 0,
                sampleGameSec = 0,
                rateTier = 0,
                filteredRate = 0,
                arrow = { visible = false, dir = "up", tier = 0 },
            };
        end
    end

    return o;
end

EnduranceUI.soundSpikeEndTime = 0;
EnduranceUI.soundSpikeStage = 0;

function EnduranceUI:initialise()
    ISPanel.initialise(self);
    EnduranceUI.soundSpikeEndTime = 0;
    EnduranceUI.soundSpikeStage = 0;
    self:updateLayout();
end

function EnduranceUI:updateLayout()
    self.iconSize = NeedsUI.instance and NeedsUI.instance.iconSize or BASE_ICON_SIZE;
    self.scale = self.iconSize / 64;
    self.barW = 250 * self.scale;
    self.barH = 8 * self.scale;
    self.radiusSize = COMPACT_ICON_SIZE_MAP[self.iconSize] or 48;
    self.runnerSize = COMPACT_ICON_SIZE_MAP[self.iconSize] or 48;

    local _, radRightPad = getVisualPadPx("Radius", self.radiusSize);
    local runnerLeftPad, runnerRightPad = getVisualPadPx("Endurance", self.runnerSize);

    local spacing = math.floor(10 * self.scale + 0.5);
    local runnerX = self.radiusSize - radRightPad - runnerLeftPad + spacing;
    local barX = runnerX + self.runnerSize - runnerRightPad + spacing;
    local totalW = barX + self.barW;

    self:setWidth(totalW);
    self:setHeight(math.max(self.barH, self.runnerSize, self.radiusSize));
    self:setX(getSideOffset(self.iconSize));
    self:setY(getCore():getScreenHeight() - getBottomOffset(self.iconSize) - self:getHeight());
    self.layoutDirty = false;
end

local function getSoundPhase(player)
    if not player or player:isDead() or (player:isInvisible() or player:isGhostMode()) then
        return 0;
    end

    local vehicle = player:getVehicle();
    if vehicle then
        if vehicle:isDriver(player) and vehicle:isEngineRunning() then
            local loudness = vehicle:getEngineLoudness();
            return radToStage(loudness);
        end
        return 0;
    end

    if not player:isPlayerMoving() then
        return 0;
    end

    local isSneaking = player:isSneaking();
    local speed = 0.50;
    if player:isSprinting() then
        speed = 1.00;
    elseif isSneaking then
        speed = 0.25;
    elseif player:isRunning() then
        speed = 0.75;
    end

    local mult = 1.4;
    if CharacterTrait.GRACEFUL and player:hasTrait(CharacterTrait.GRACEFUL) then
        mult = mult * 0.6;
    end
    if CharacterTrait.CLUMSY and player:hasTrait(CharacterTrait.CLUMSY) then
        mult = mult * 1.2;
    end
    if not player:getClothingItem_Feet() then
        mult = mult * 0.5;
    end

    local lightfoot = player:getLightfootMod() or 1.0;
    local nimble = player:getNimbleMod() or 1.0;
    mult = mult * lightfoot;
    mult = mult * (2.0 - nimble);

    if isSneaking then
        local sneakMod = player:getSneakSpotMod() or 1.0;
        mult = mult * sneakMod;
    end

    local sq = player:getCurrentSquare();
    if sq and sq:getRoom() then
        mult = mult * 0.5;
    end

    local rad = math.ceil(speed * mult * 10);
    if isSneaking then
        rad = math.max(1, rad);
    end

    return radToStage(rad);
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
    return PHASE_COLORS[phase];
end

EnduranceUI.onMouseDown = swallowUnlessAiming;
EnduranceUI.onMouseUp = swallowUnlessAiming;
EnduranceUI.onRightMouseDown = swallowUnlessAiming;
EnduranceUI.onRightMouseUp = swallowUnlessAiming;

function EnduranceUI:update()
    if self.layoutDirty then
        self:updateLayout();
    end
end

function EnduranceUI:render()
    if self.skipRender and self.skipRender > 0 then
        self.skipRender = self.skipRender - 1;
        return;
    end

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
    local capFrac = provider and provider(player);
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
    local runnerSize = self.runnerSize;
    local runTex = getTexture("media/ui/Endurance/" .. runnerSize .. "/Endurance_" .. phase .. ".png");
    local spacing = math.floor(10 * self.scale + 0.5);

    local radSize = self.radiusSize;
    local radX = 0;
    local radY = math.floor((self:getHeight() - radSize) / 2);

    local movementPhase = getSoundPhase(player);
    local activePhase = movementPhase;
    local now = getTimestampMs();
    if now < EnduranceUI.soundSpikeEndTime then
        if player:isPlayerMoving() or EnduranceUI.soundSpikeStage > 2 then
            activePhase = math.max(activePhase, EnduranceUI.soundSpikeStage);
        end
    end

    local bgRadTex = getTexture("media/ui/Radius/" .. radSize .. "/Radius_4.png");
    if bgRadTex then
        self:drawTextureScaled(bgRadTex, radX, radY, radSize, radSize, 0.5 * globalAlpha, 1, 1, 1);
    end

    if activePhase > 0 then
        local fillRadTex = getTexture("media/ui/Radius/" .. radSize .. "/Radius_" .. activePhase .. ".png");
        if fillRadTex then
            self:drawTextureScaled(fillRadTex, radX, radY, radSize, radSize, globalAlpha, 1, 1, 1);
        end
    end

    local _, radRightPad = getVisualPadPx("Radius", radSize);
    local runnerLeftPad, runnerRightPad = getVisualPadPx("Endurance", runnerSize);

    local runnerX = radSize - radRightPad - runnerLeftPad + spacing;
    local runnerY = (self:getHeight() - runnerSize) / 2;
    if runTex then
        self:drawTexture(runTex, runnerX, runnerY, globalAlpha, 1, 1, 1);
    end

    local barX = runnerX + runnerSize - runnerRightPad + spacing;
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

    local tooltipUI = NeedsUI.instance and NeedsUI.instance.tooltipUI;
    if tooltipUI then
        if globalAlpha > TOOLTIP_ALPHA_THRESHOLD and self:isMouseOver() and self:getMouseX() >= runnerX and not player:isAiming() then
            local title = getText("Tooltip_HUD_Endurance");
            local desc = string.format("%s: %d%%", title, math.floor(val * 100 + 0.5));

            if phase > 0 then
                local moodleDesc = getText("Moodles_Endurance_desc_lvl" .. phase);
                if moodleDesc then
                    desc = desc .. "\n" .. moodleDesc;
                end
            end

            self.currentValues = self.currentValues or {};
            self.currentValues.Endurance = val;
            tooltipUI:showFor("endurance", desc, "Endurance", self.currentValues, nil);
        else
            tooltipUI:hideFor("endurance");
        end
    end
end

function EnduranceUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
    o.fade = UITransition.new();
    o.skipRender = 0;
    o.iconSize = BASE_ICON_SIZE;
    o.radiusSize = COMPACT_ICON_SIZE_MAP[BASE_ICON_SIZE] or 48;
    o.runnerSize = COMPACT_ICON_SIZE_MAP[BASE_ICON_SIZE] or 48;

    return o;
end

local function onCreatePlayer()
    if NeedsUI.instance then
        if NeedsUI.instance.tooltipUI then
            NeedsUI.instance.tooltipUI:removeFromUIManager();
        end
        NeedsUI.instance:removeFromUIManager();
    end
    if EnduranceUI.instance then
        EnduranceUI.instance:removeFromUIManager();
    end

    NeedsUI.instance = NeedsUI:new(0, 0, 100, 100);
    NeedsUI.instance:initialise();
    NeedsUI.instance:addToUIManager();
    NeedsUI.instance:backMost();

    EnduranceUI.instance = EnduranceUI:new(0, 0, 100, 100);
    EnduranceUI.instance:initialise();
    EnduranceUI.instance:addToUIManager();
    EnduranceUI.instance:backMost();

    NeedsUI.instance.layoutDirty = true;
    EnduranceUI.instance.layoutDirty = true;
end

local function onResolutionChange()
    if NeedsUI.instance then
        NeedsUI.instance.layoutDirty = true;
        NeedsUI.instance.skipRender = 15;
    end
    if EnduranceUI.instance then
        EnduranceUI.instance.layoutDirty = true;
        EnduranceUI.instance.skipRender = 15;
    end
end

local function onPlayerUpdate()
    if NeedsUI.instance then
        NeedsUI.instance.layoutDirty = true;
    end
    if EnduranceUI.instance then
        EnduranceUI.instance.layoutDirty = true;
    end
end

local function onPlayerDeath()
    if NeedsUI.instance then
        if NeedsUI.instance.tooltipUI then
            NeedsUI.instance.tooltipUI:removeFromUIManager();
        end
        NeedsUI.instance:removeFromUIManager();
        NeedsUI.instance = nil;
    end
    if EnduranceUI.instance then
        EnduranceUI.soundSpikeEndTime = 0;
        EnduranceUI.soundSpikeStage = 0;
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

        for _, t in ipairs(FOOD_EATEN_THRESHOLDS) do
            getTexture("media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_" .. t.level .. ".png");
            getTexture("media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_" .. t.level .. "_" .. t.timer .. ".png");
        end
    end

    for _, texSize in ipairs({ 12, 16, 20 }) do
        getTexture("media/ui/Arrow/" .. texSize .. "/1x_Up.png");
        getTexture("media/ui/Arrow/" .. texSize .. "/1x_Down.png");
        getTexture("media/ui/Arrow/" .. texSize .. "/2x_Up.png");
        getTexture("media/ui/Arrow/" .. texSize .. "/2x_Down.png");
    end

    for _, texSize in ipairs({ 24, 32, 40 }) do
        getTexture("media/ui/Separator/" .. texSize .. "/Separator.png");
    end

    for _, texSize in ipairs({ 32, 48, 64 }) do
        for phase = 1, 4 do
            getTexture("media/ui/Radius/" .. texSize .. "/Radius_" .. phase .. ".png");
        end
        for phase = 0, 4 do
            getTexture("media/ui/Endurance/" .. texSize .. "/Endurance_" .. phase .. ".png");
        end
    end

    getTexture("media/ui/chevron_up.png");
    getTexture("media/ui/chevron_double.png");
    getTexture("media/ui/chevron_down.png");
end

local function onWorldSound(x, y, z, radius, volume, source)
    local player = getPlayer();
    if not player or player:isDead() or (player:isInvisible() or player:isGhostMode()) then return; end
    local vehicle = player:getVehicle();
    local isDriver = vehicle and vehicle:isDriver(player);
    local isPlayerSource = (source == player) or (isDriver and source == vehicle);
    if not isPlayerSource and source == nil then
        isPlayerSource = (x == math.floor(player:getX()) and y == math.floor(player:getY()) and z == math.floor(player:getZ()));
    end
    if not isPlayerSource then return; end

    local spikeStage = radToStage(radius);
    if spikeStage > 0 then
        local currentPhase = getSoundPhase(player);
        if spikeStage > currentPhase or radius >= 15 then
            EnduranceUI.soundSpikeStage = spikeStage;
            EnduranceUI.soundSpikeEndTime = getTimestampMs() + 750;
        end
    end
end

local function canFirearmShoot(player, weapon)
    if not player:isAiming() then
        return false;
    end
    if player:isDoShove() then
        return false;
    end
    if weapon:isJammed() then
        return false;
    end
    if player:isUnlimitedAmmo() then
        return true;
    end
    if weapon:haveChamber() then
        if not weapon:isRoundChambered() or weapon:isSpentRoundChambered() then
            return false;
        end
    elseif weapon:getCurrentAmmoCount() <= 0 then
        return false;
    end
    return true;
end

local function onWeaponSwing(player, weapon)
    if not player or player:isDead() or not player:isLocalPlayer() or (player:isInvisible() or player:isGhostMode()) then return; end
    if weapon and instanceof(weapon, "HandWeapon") and weapon:isRanged() then
        if canFirearmShoot(player, weapon) then
            local radius = weapon:getSoundRadius();
            local spikeStage = radToStage(radius);
            EnduranceUI.soundSpikeStage = spikeStage;
            EnduranceUI.soundSpikeEndTime = getTimestampMs() + 750;
        end
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer);
Events.OnPlayerDeath.Add(onPlayerDeath);
Events.OnResolutionChange.Add(onResolutionChange);
Events.OnClothingUpdated.Add(onPlayerUpdate);
Events.OnEnterVehicle.Add(onPlayerUpdate);
Events.OnExitVehicle.Add(onPlayerUpdate);
Events.OnSwitchVehicleSeat.Add(onPlayerUpdate);
Events.OnWorldSound.Add(onWorldSound);
Events.OnWeaponSwing.Add(onWeaponSwing);
Events.OnGameBoot.Add(onGameBoot);