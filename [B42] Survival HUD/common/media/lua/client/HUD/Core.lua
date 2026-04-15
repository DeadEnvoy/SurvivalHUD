require "ISUI/ISPanel";

SurvivalHUD = ISPanel:derive("SurvivalHUD");
EnduranceUI = ISPanel:derive("EnduranceUI");

SurvivalHUD.instance = nil;
EnduranceUI.instance = nil;

SurvivalHUD.IconSize = 64;
SurvivalHUD.BaseIconSize = 64;
SurvivalHUD.BottomOffset = 15;
SurvivalHUD.RightOffset = 15;

SurvivalHUD.ChevronConfig = {
    [48] = { texSize = 16, renderSize = 12 },
    [64] = { texSize = 16, renderSize = 16 },
    [80] = { texSize = 24, renderSize = 20 },
    -- [96] = { texSize = 24, renderSize = 24 },
    -- [128] = { texSize = 32, renderSize = 32 },
};

SurvivalHUD.SeparatorConfig = {
    [48] = { texSize = 32, renderSize = 24 },
    [64] = { texSize = 32, renderSize = 32 },
    [80] = { texSize = 48, renderSize = 40 },
    -- [96] = { texSize = 48, renderSize = 48 },
    -- [128] = { texSize = 64, renderSize = 64 },
};

SurvivalHUD.SkipRender = 0;

SurvivalHUD.ArrowDuration = 10000;

SurvivalHUD.CollisionSizes = { 80, 64, 48 };

SurvivalHUD.PhaseColors = {
    [0] = { r = 1, g = 1, b = 1 },
    [1] = { r = 1, g = 0.866, b = 0 },
    [2] = { r = 1, g = 0.482, b = 0.101 },
    [3] = { r = 0.937, g = 0.196, b = 0.247 },
    [4] = { r = 0.819, g = 0.105, b = 0.125 },
};

SurvivalHUD.TempPhaseColors = {
    ["-4"] = { r = 0.5, g = 0.6, b = 0.75 },
    ["-3"] = { r = 0.1, g = 0.67, b = 0.86 },
    ["-2"] = { r = 0.43, g = 0.78, b = 0.91 },
    ["-1"] = { r = 0.62, g = 0.8, b = 0.9 }
};

SurvivalHUD.Phases = {
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
        { 20, 25, "-4", { 25 } },
        { 25, 30, "-3", { 26.5, 27, 28, 29, 30 } },
        { 30, 35, "-2", { 30.5, 31.5, 32, 33, 33.5, 34.5, 35 } },
        { 35, 36.5, "-1", { 36.5 } },
        { 36.5, 37.5, "0", { 37 } },
        { 37.5, 39, "+1", { 37.5, 38 } },
        { 39, 40, "+2", { 39 } },
        { 40, 41, "+3", { 40 } },
        { 41, 42, "+4", { 41 } },
    },
    Sickness = {
        { 0, 25, 0, { 0, 5, 10, 15, 20, 25 } },
        { 25, 50, 1, { 26, 30, 35, 40, 45, 50 } },
        { 50, 75, 2, { 51, 55, 60, 65, 70, 75 } },
        { 75, 90, 3, { 76, 80, 85, 90 } },
        { 90, 100, 4, { 91, 95, 100 } },
    },
    Intoxication = {
        { 0, 25, 0, { 0, 5, 10, 15, 20, 25 } },
        { 25, 50, 1, { 26, 30, 35, 40, 45, 50 } },
        { 50, 75, 2, { 51, 55, 60, 65, 70, 75 } },
        { 75, 90, 3, { 76, 80, 85, 90 } },
        { 90, 100, 4, { 91, 95, 100 } },
    },
    Health = {
        { 80, 100, 0, { 100, 95, 90, 85 } },
        { 60, 80, 1, { 80, 75, 70, 65 } },
        { 40, 60, 2, { 60, 55, 50, 45 } },
        { 25, 40, 3, { 40, 35, 30 } },
        { 0, 25, 4, { 25, 20, 15, 10, 5 } },
    },
};

SurvivalHUD.Groups = {
    { icons = { "Fatigue" } },
    { icons = { "Thirst", "Hunger", "Temperature" } },
    { icons = { "Intoxication", "Sickness", "Health" } },
};

SurvivalHUD.IconGap = {
    [48] = 14,
    [64] = 16,
    [80] = 18,
    -- [96] = 20,
    -- [128] = 22
};

SurvivalHUD.GroupGap = {
    [48] = 32,
    [64] = 40,
    [80] = 48,
    -- [96] = 56,
    -- [128] = 64
};

SurvivalHUD.IconVisualPadding = {
    Fatigue = { left = 0.23, right = 0.23 },
    Thirst = { left = 0.28, right = 0.28 },
    Hunger = { left = 0.14, right = 0.14 },
    Temperature  = { left = 0.30, right = 0.30 },
    Intoxication = { left = 0.025, right = 0.025 },
    Sickness = { left = 0.025, right = 0.025 },
    Health = { left = 0.025, right = 0.025 },
};

-- SurvivalHUD.DebugPadding = false;

SurvivalHUD.MoodleNames = {
    Fatigue = "Tired",
    Thirst = "Thirst",
    Hunger = "Hungry",
    Intoxication = "Sick",
    Sickness = "Sick",
    Health = "Injured",
};

SurvivalHUD.Tooltip = ISPanel:derive("SurvivalHUD_Tooltip");

function SurvivalHUD.Tooltip:initialise()
    ISPanel.initialise(self);
    self:instantiate();
    self.javaObject:setConsumeMouseEvents(false);
    self.backgroundColor = { r = 0.9, g = 0.1, b = 0.1, a = 0.1 };
    self.borderColor = { r = 1, g = 0.7, b = 0.7, a = 0.7 };
    self.currentOwner = nil;
end

function SurvivalHUD.Tooltip:updateData(text, iconType, currentValues, weightArrowInfo)
    self.tooltipText = text;
    self.iconType = iconType;
    self.currentValues = currentValues;
    self.weightArrowInfo = weightArrowInfo;
    self:calculateLayout();
end

function SurvivalHUD.Tooltip:calculateLayout()
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
        if self.iconType == "Hunger" and string.find(line, getText("Tooltip_HUD_Weight")) then
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

function SurvivalHUD.Tooltip:prerender()
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
            and string.find(line, getText("Tooltip_HUD_Weight"))
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

function SurvivalHUD.Tooltip:getLineColor()
    if self.iconType == "Endurance" then
        return self:getEnduranceLineColor();
    end
    return self:getStatLineColor();
end

function SurvivalHUD.Tooltip:getEnduranceLineColor()
    if not EnduranceUI.instance then
        return 1, 1, 1;
    end
    local val = self.currentValues["Endurance"];
    local phase = EnduranceUI.instance:getPhase(val);
    local color = SurvivalHUD.PhaseColors[phase];
    if color then
        return color.r, color.g, color.b;
    end
    return 1, 1, 1;
end

function SurvivalHUD.Tooltip:getStatLineColor()
    local phase = SurvivalHUD.instance:getPhaseData(
        self.currentValues[self.iconType], self.iconType);
    if not phase then
        return 1, 1, 1;
    end

    local phaseLevel = phase[3];

    if self.iconType == "Temperature" then
        local color = SurvivalHUD.TempPhaseColors[phaseLevel];
        if color then
            return color.r, color.g, color.b;
        end
        local numericLevel = (phaseLevel == "0") and 0 or tonumber(phaseLevel:sub(2));
        color = SurvivalHUD.PhaseColors[numericLevel];
        if color then
            return color.r, color.g, color.b;
        end
        return 1, 1, 1;
    end

    local color = SurvivalHUD.PhaseColors[phaseLevel];
    if color then
        return color.r, color.g, color.b;
    end
    return 1, 1, 1;
end

function SurvivalHUD.Tooltip:getWeightArrowTexture()
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

function SurvivalHUD.Tooltip:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;
    o:setAlwaysOnTop(true);
    return o;
end

function SurvivalHUD:initialise()
    ISPanel.initialise(self);
    SurvivalHUD.IconSize = SurvivalHUD.BaseIconSize;
    self.layoutDirty = true;

    self.tooltipUI = SurvivalHUD.Tooltip:new(0, 0, 0, 0);
    self.tooltipUI:initialise();
    self.tooltipUI:addToUIManager();
    self.tooltipUI:setVisible(false);
end

function SurvivalHUD:getPhaseData(val, statType)
    local phases = SurvivalHUD.Phases[statType];
    if not phases then return nil; end

    for _, phase in ipairs(phases) do
        if val >= phase[1] and val <= phase[2] then
            return phase;
        end
    end

    return phases[#phases];
end

function SurvivalHUD:getBestTexture(val, statType, currentTexVal)
    local hideWhenZero = {
        Intoxication = true,
        Sickness = true,
        Fatigue = true,
    };
    if hideWhenZero[statType] and val <= 0 then return nil; end

    if statType ~= "Temperature" and val <= 0 then return nil; end

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

function SurvivalHUD:getTexturePaths(statType, phase, texVal)
    local sizeStr = tostring(SurvivalHUD.IconSize);
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

function SurvivalHUD:getIconPadPx(statType)
    local size = SurvivalHUD.IconSize;
    local pad = SurvivalHUD.IconVisualPadding[statType];
    return pad and math.floor(size * pad.left) or 0,
           pad and math.floor(size * pad.right) or 0;
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
    local myX = screenW - self:getWidth() - SurvivalHUD.RightOffset;
    local myY = screenH - SurvivalHUD.BottomOffset - SurvivalHUD.IconSize;
    local myW = self:getWidth();
    local myH = SurvivalHUD.IconSize;

    return self:isIntersecting(myX, myY, myW, myH, ui:getAbsoluteX(), ui:getAbsoluteY(), ui:getWidth(), ui:getHeight());
end

local function getNextSmallerSize(currentSize)
    local sizes = SurvivalHUD.CollisionSizes;
    local found = false;
    for _, size in ipairs(sizes) do
        if found then return size; end
        if size == currentSize then found = true; end
    end
    return nil;
end

function SurvivalHUD:resolveCollisionWith(ui, isIntoxicationVisible, isSicknessVisible)
    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    while self:checkUICollision(ui) do
        local nextIconSize = getNextSmallerSize(SurvivalHUD.IconSize);
        if nextIconSize then
            SurvivalHUD.IconSize = nextIconSize;
            if EnduranceUI.instance then
                EnduranceUI.instance.layoutDirty = true;
            end
            self:recalcDimensions(isIntoxicationVisible, isSicknessVisible);
            self:setX(screenW - self:getWidth() - SurvivalHUD.RightOffset);
            self:setY(screenH - SurvivalHUD.BottomOffset - SurvivalHUD.IconSize);
        elseif HotbarReskin and ui.availableSlot then
            local nextHotbarSize = HotbarReskin.getNextSmallerSize(HotbarReskin.HOTBAR_SIZE);
            if not nextHotbarSize then break; end
            HotbarReskin.HOTBAR_SIZE = nextHotbarSize;
            local hotbar = ui;
            local count = math.max(#hotbar.availableSlot, 1);
            local w = HotbarReskin.calcTotalWidth(count);
            local h = HotbarReskin.HOTBAR_SIZE + HotbarReskin.HOTBAR_MARGIN * 2;
            hotbar:setWidth(w);
            hotbar:setHeight(h);
            local screenX = getPlayerScreenLeft(hotbar.playerNum);
            local screenY = getPlayerScreenTop(hotbar.playerNum);
            local screenWH = getPlayerScreenWidth(hotbar.playerNum);
            local screenHH = getPlayerScreenHeight(hotbar.playerNum);
            hotbar:setX(screenX + math.floor((screenWH - w) / 2));
            hotbar:setY(screenY + screenHH - h - 15);
        else
            break;
        end
    end
end

function SurvivalHUD:updateLayout(isIntoxicationVisible, isSicknessVisible)
    local player = getPlayer();
    if not player then return; end

    if isIntoxicationVisible == nil then
        isIntoxicationVisible = player:getStats():get(CharacterStat.FOOD_SICKNESS) > 0;
    end
    if isSicknessVisible == nil then
        isSicknessVisible = player:getStats():get(CharacterStat.SICKNESS) > 0;
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum());
    local dash = getPlayerVehicleDashboard(player:getPlayerNum());
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(player:getPlayerNum()) or nil;
    local vehicle = player:getVehicle();

    SurvivalHUD.IconSize = SurvivalHUD.BaseIconSize;
    if HotbarReskin and hotbar then
        HotbarReskin.HOTBAR_SIZE = HotbarReskin.BASE_HOTBAR_SIZE;
        local count = math.max(#hotbar.availableSlot, 1);
        local w = HotbarReskin.calcTotalWidth(count);
        local h = HotbarReskin.HOTBAR_SIZE + HotbarReskin.HOTBAR_MARGIN * 2;
        hotbar:setWidth(w);
        hotbar:setHeight(h);
        local screenX = getPlayerScreenLeft(hotbar.playerNum);
        local screenY = getPlayerScreenTop(hotbar.playerNum);
        local screenWP = getPlayerScreenWidth(hotbar.playerNum);
        local screenHP = getPlayerScreenHeight(hotbar.playerNum);
        hotbar:setX(screenX + math.floor((screenWP - w) / 2));
        hotbar:setY(screenY + screenHP - h - 15);
    end
    self:recalcDimensions(isIntoxicationVisible, isSicknessVisible);

    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    self:setX(screenW - self:getWidth() - SurvivalHUD.RightOffset);
    self:setY(screenH - SurvivalHUD.BottomOffset - SurvivalHUD.IconSize);

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

function SurvivalHUD:getVisualWidth(statType)
    local pad = SurvivalHUD.IconVisualPadding[statType];
    if not pad then return SurvivalHUD.IconSize; end
    return SurvivalHUD.IconSize * (1 - pad.left - pad.right);
end

function SurvivalHUD:getVisualLeft(statType)
    local pad = SurvivalHUD.IconVisualPadding[statType];
    if not pad then return 0; end
    return math.floor(SurvivalHUD.IconSize * pad.left);
end

function SurvivalHUD:recalcDimensions(showIntoxication, showSickness)
    local size = SurvivalHUD.IconSize;
    local totalW = 0;
    local groupWidths = {};
    local visibleGroups = {};

    local function getPad(statType)
        return self:getIconPadPx(statType);
    end

    local function getVisibleIcons(group)
        local t = {};
        for _, st in ipairs(group.icons) do
            local hidden = (st == "Intoxication" and not showIntoxication)
                        or (st == "Sickness" and not showSickness);
            if not hidden then table.insert(t, st); end
        end
        return t;
    end

    local groupIcons = {};
    for i, group in ipairs(SurvivalHUD.Groups) do
        groupIcons[i] = getVisibleIcons(group);
        visibleGroups[i] = #groupIcons[i] > 0;
    end

    for i, icons in ipairs(groupIcons) do
        if #icons > 0 then
            local groupW = size;
            for j = 2, #icons do
                local _, rp = getPad(icons[j - 1]);
                local lp, _ = getPad(icons[j]);
                groupW = groupW + size - rp - lp + (SurvivalHUD.IconGap[size] or 4);
            end
            groupWidths[i] = groupW;
            totalW = totalW + groupW;
        else
            groupWidths[i] = 0;
        end
    end

    for i = 1, #SurvivalHUD.Groups - 1 do
        if visibleGroups[i] then
            for j = i + 1, #SurvivalHUD.Groups do
                if visibleGroups[j] then
                    local icons_i = groupIcons[i];
                    local icons_j = groupIcons[j];
                    local _, lastRight = getPad(icons_i[#icons_i]);
                    local firstLeft, _ = getPad(icons_j[1]);
                    totalW = totalW + (SurvivalHUD.GroupGap[size] or 16) - lastRight - firstLeft;
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
        SurvivalHUD.IconSize = SurvivalHUD.BaseIconSize;
        self:updateLayout();
        self.layoutDirty = false;
    end
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
    if SurvivalHUD.SkipRender > 0 then
        SurvivalHUD.SkipRender = SurvivalHUD.SkipRender - 1;
        return;
    end

    local player = getPlayer();
    if not player then return; end

    local hotbar = getPlayerHotbar(player:getPlayerNum());
    local dash = getPlayerVehicleDashboard(player:getPlayerNum());
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(player:getPlayerNum()) or nil;

    local anyPanelVisible = (hotbar and hotbar:isReallyVisible()) or (dash and dash:isReallyVisible()) or (pscDash and pscDash:isReallyVisible());
    if not anyPanelVisible then return; end

    local hotbarVis = hotbar and hotbar:isReallyVisible();
    local dashVis = dash and dash:isReallyVisible();
    local pscDashVis = pscDash and pscDash:isReallyVisible();
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
        Fatigue = math.max(0, math.min(100, (1 - stats:get(CharacterStat.FATIGUE)) * 100)),
        Thirst = math.max(0, math.min(100, (1 - stats:get(CharacterStat.THIRST)) * 100)),
        Hunger = math.max(0, math.min(100, (1 - stats:get(CharacterStat.HUNGER)) * 100)),
        Temperature = stats:get(CharacterStat.TEMPERATURE),
        Intoxication = math.max(0, math.min(100, stats:get(CharacterStat.FOOD_SICKNESS))),
        Sickness = math.max(0, math.min(100, stats:get(CharacterStat.SICKNESS) * 100)),
        Health = math.max(0, math.min(100, body:getHealth())),
    };

    local isIntoxicationVisible = vals.Intoxication > 0;
    local isSicknessVisible = vals.Sickness > 0;

    if self.lastIntoxicationVisible ~= isIntoxicationVisible or self.lastSicknessVisible ~= isSicknessVisible then
        self.lastIntoxicationVisible = isIntoxicationVisible;
        self.lastSicknessVisible = isSicknessVisible;
        self:updateLayout(isIntoxicationVisible, isSicknessVisible);
    end

    self.currentValues = vals;

    local now = getTimestampMs();
    for statType, val in pairs(vals) do
        local icon = self.icons[statType];

        if val ~= icon.lastVal and icon.lastVal ~= -1 then
            icon.arrow.visible = true;
            icon.arrow.time = now;
            icon.arrow.dir = (val > icon.lastVal) and "up" or "down";
        end

        local iconHidden = false;
        if statType == "Intoxication" or statType == "Sickness" then
            iconHidden = val <= 0;
        elseif statType == "Temperature" then
            iconHidden = val >= 36.55 and val <= 37.45;
        else
            iconHidden = val >= 99;
        end

        if icon.arrow.visible
            and (now - icon.arrow.time >= SurvivalHUD.ArrowDuration or iconHidden) then
            icon.arrow.visible = false;
        end

        icon.lastVal = val;
    end

    local curX = 0;
    for k in pairs(self.iconPos) do self.iconPos[k] = nil; end
    local size = SurvivalHUD.IconSize;

    local function getPadPx(statType)
        return self:getIconPadPx(statType);
    end

    for i, group in ipairs(SurvivalHUD.Groups) do
        if self.visibleGroups and self.visibleGroups[i] then
            local icons = self.groupIcons and self.groupIcons[i] or {};

            local iconX = curX;
            for j, statType in ipairs(icons) do
                if j > 1 then
                    local _, prevRight = getPadPx(icons[j - 1]);
                    local curLeft, _  = getPadPx(statType);
                    iconX = iconX + size - prevRight - curLeft + (SurvivalHUD.IconGap[size] or 4);
                end
                self:drawStatusIcon(iconX, 0, statType, vals[statType], globalAlpha);
            end

            curX = curX + self.groupWidths[i];

            if i < #SurvivalHUD.Groups then
                for j = i + 1, #SurvivalHUD.Groups do
                    if self.visibleGroups[j] then
                        local nextIcons = self.groupIcons and self.groupIcons[j] or {};
                        local lastIcon  = icons[#icons];
                        local firstIcon = nextIcons[1];

                        local _, lastRight  = getPadPx(lastIcon);
                        local firstLeft, _  = getPadPx(firstIcon);

                        local rightEdge = curX - lastRight;
                        local nextGroupStart = curX + (SurvivalHUD.GroupGap[size] or 16) - lastRight - firstLeft;
                        local leftEdge = nextGroupStart + firstLeft;

                        local sepCenterX = (rightEdge + leftEdge) / 2;

                        local sepCfg = SurvivalHUD.SeparatorConfig[size];
                        if sepCfg then
                            local renderSize = sepCfg.renderSize;
                            local texSize    = sepCfg.texSize;
                            local sepTex = getTexture("media/ui/Separator/" .. texSize .. "/Separator.png");
                            if sepTex then
                                local sepX = math.floor(sepCenterX - renderSize / 2);
                                local sepY = math.floor((size - renderSize) / 2);
                                self:drawTextureScaled(sepTex, sepX, sepY, renderSize, renderSize, globalAlpha * 0.5, 1, 1, 1);
                            end
                        end

                        curX = nextGroupStart;
                        break;
                    end
                end
            end
        end
    end

    if globalAlpha > 0.9 and not player:isAiming() then
        self:updateTooltipHover(vals, isIntoxicationVisible, isSicknessVisible);
    else
        self:hideTooltipIfOwned("icons");
    end
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
    if getPlayer():isAiming() then return false; end
    local mx = self:getMouseX();
    local my = self:getMouseY();
    local size = SurvivalHUD.IconSize;
    local healthPos = self.iconPos["Health"];
    if healthPos and mx >= healthPos.x and mx <= healthPos.x + size and my >= healthPos.y and my <= healthPos.y + size then
        if self:isMouseOver() then
            local player = getPlayer();
            local infopanel = getPlayerInfoPanel(player:getPlayerNum());
            if infopanel then
                infopanel:toggleView(getText("IGUI_XP_Health"));
                getSoundManager():playUISound("UISelectListItem");
            end
            return true;
        end
    end
    local tempPos = self.iconPos["Temperature"];
    if tempPos and mx >= tempPos.x and mx <= tempPos.x + size and my >= tempPos.y and my <= tempPos.y + size then
        if self:isMouseOver() then
            local player = getPlayer();
            local infopanel = getPlayerInfoPanel(player:getPlayerNum());
            if infopanel then
                infopanel:toggleView(getText("IGUI_XP_ClothingIns"));
                getSoundManager():playUISound("UISelectListItem");
            end
            return true;
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
    if not phase then return; end

    self.iconPos[statType] = { x = x, y = y };

    local texVal = self:getBestTexture(val, statType, icon.texVal);
    if texVal then icon.texVal = texVal; end

    local bgPath, iconPath = self:getTexturePaths(statType, phase, icon.texVal);

    if statType == "Hunger" and val > 95 then
        local player = getPlayer();
        local foodEatenTimer = player:getBodyDamage():getHealthFromFoodTimer();
        local sizeStr = tostring(SurvivalHUD.IconSize);
        if foodEatenTimer > 0 then
            if foodEatenTimer > 4800 then
                bgPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_4.png";
                iconPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_4_4800.png";
            elseif foodEatenTimer > 3200 then
                bgPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_3.png";
                iconPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_3_3200.png";
            elseif foodEatenTimer > 1600 then
                bgPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_2.png";
                iconPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_2_1600.png";
            else
                bgPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_1.png";
                iconPath = "media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_1_0.png";
            end
        end
    end

    local bgTex = getTexture(bgPath);
    if bgTex then
        self:drawTextureScaled(bgTex, x, y, SurvivalHUD.IconSize, SurvivalHUD.IconSize, alpha, 1, 1, 1);
    end

    if texVal then
        local iconTex = getTexture(iconPath);
        if iconTex then
            self:drawTextureScaled(iconTex, x, y, SurvivalHUD.IconSize, SurvivalHUD.IconSize, alpha, 1, 1, 1);
        end
    end

    if icon.arrow.visible then
        local chevronCfg = SurvivalHUD.ChevronConfig[SurvivalHUD.IconSize];
        if chevronCfg then
            local texSize = chevronCfg.texSize;
            local renderSize = chevronCfg.renderSize;
            local dir = icon.arrow.dir;
            local arrowTex = getTexture("media/ui/Chevron/" .. texSize .. "/Chevron-" .. (dir == "up" and "Up" or "Down") .. ".png");
            if arrowTex then
                local arrowX = x + (SurvivalHUD.IconSize - renderSize) / 2;
                local arrowY;
                if dir == "up" then
                    arrowY = y - renderSize + 5.25;
                else
                    arrowY = y + SurvivalHUD.IconSize - 5.25;
                end
                self:drawTextureScaled(arrowTex, arrowX, arrowY, renderSize, renderSize, alpha, 1, 1, 1);
            end
        end
    end

    -- if SurvivalHUD.DebugPadding then
    --     local pad = SurvivalHUD.IconVisualPadding[statType];
    --     if pad then
    --         local size = SurvivalHUD.IconSize;
    --         local leftW  = math.floor(pad.left  * size);
    --         local rightW = math.floor(pad.right * size);
    --         if leftW > 0 then
    --             self:drawRect(x, y, leftW, size, 0.45, 1, 0.1, 0.1);
    --         end
    --         if rightW > 0 then
    --             self:drawRect(x + size - rightW, y, rightW, size, 0.45, 0.1, 0.4, 1);
    --         end
    --     end
    -- end
end

function SurvivalHUD:updateTooltipHover(vals, isIntoxicationVisible, isSicknessVisible)
    local anyHovered = false;

    for statType, pos in pairs(self.iconPos) do
        local isHovered = false;

        if statType == "Health" then
            isHovered = self:isMouseOverNotBlocked(pos.x, pos.y, SurvivalHUD.IconSize, SurvivalHUD.IconSize);
        else
            local mx = self:getMouseX();
            local my = self:getMouseY();
            local inBounds = mx >= pos.x
                and mx <= pos.x + SurvivalHUD.IconSize
                and my >= pos.y
                and my <= pos.y + SurvivalHUD.IconSize;
            if inBounds then
                isHovered = self:isMouseOver();
            end
        end

        if isHovered then
            local iconHidden = (statType == "Intoxication" and not isIntoxicationVisible) or (statType == "Sickness" and not isSicknessVisible);
            if not iconHidden then
                self:prepareTooltip(statType, vals[statType]);
                self.tooltipUI.currentOwner = "icons";
                anyHovered = true;
            end
            break;
        end
    end

    if not anyHovered then
        self:hideTooltipIfOwned("icons");
    end
end

function SurvivalHUD:hideTooltipIfOwned(owner)
    if self.tooltipUI and self.tooltipUI.currentOwner == owner then
        self.tooltipUI:setVisible(false);
        self.tooltipUI.currentOwner = nil;
    end
end

function SurvivalHUD:prepareTooltip(statType, val)
    local title = getText("Tooltip_HUD_" .. string.gsub(" " .. statType, "%W%l", string.upper):sub(2));
    if not title then title = statType; end

    local desc;
    if statType == "Temperature" then
        if getCore():getOptionDisplayAsCelsius() then
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
        local player = getPlayer();
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

    local phase = self:getPhaseData(val, statType);
    if phase then
        local phaseLevel = phase[3];
        local showMoodDescription = false;
        local moodleName = "";

        if statType == "Temperature" then
            if phaseLevel ~= "0" then
                showMoodDescription = true;
                if phaseLevel:sub(1, 1) == "+" then
                    moodleName = "Hyperthermia";
                else
                    moodleName = "Hypothermia";
                end
            end
        elseif statType == "Hunger" and val > 95 then
            local player = getPlayer();
            local foodEatenTimer = player:getBodyDamage():getHealthFromFoodTimer();
            if foodEatenTimer > 0 then
                showMoodDescription = true;
                moodleName = "FoodEaten";
                if foodEatenTimer > 4800 then
                    phaseLevel = 4;
                elseif foodEatenTimer > 3200 then
                    phaseLevel = 3;
                elseif foodEatenTimer > 1600 then
                    phaseLevel = 2;
                else
                    phaseLevel = 1;
                end
            end
        elseif phaseLevel ~= 0 then
            showMoodDescription = true;
            moodleName = (SurvivalHUD.MoodleNames[statType] or statType);
        end

        if showMoodDescription then
            local levelSuffix;
            if statType == "Temperature" then
                levelSuffix = phaseLevel:sub(2);
            else
                levelSuffix = tostring(phaseLevel);
            end
            local moodleDesc = getText("Moodles_" .. moodleName .. "_desc_lvl" .. levelSuffix);
            if moodleDesc then
                desc = desc .. "\n\n" .. moodleDesc;
            end
        end
    end

    if self.tooltipUI then
        self.tooltipUI:updateData(desc, statType, self.currentValues, weightArrowInfo);
        self.tooltipUI:setVisible(true);
        self.tooltipUI:bringToTop();
    end
end

function SurvivalHUD:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
    o.fade = UITransition.new();
    o.icons = {};
    o.iconPos = {};

    for _, group in ipairs(SurvivalHUD.Groups) do
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

function EnduranceUI:initTextures()
end

function EnduranceUI:updateLayout()
    self.scale = SurvivalHUD.IconSize / 64;
    self.barW = 268 * self.scale;
    self.barH = 8 * self.scale;
    self.iconSize = 32 * self.scale;

    local spacing = 10 * self.scale;
    local totalW = self.iconSize + spacing + self.barW;

    self:setWidth(totalW);
    self:setHeight(math.max(self.barH, self.iconSize));
    self:setX(20);
    self:setY(getCore():getScreenHeight() - 40 - self.barH);
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
    return SurvivalHUD.PhaseColors[phase] or { r = 1, g = 1, b = 1 };
end

function EnduranceUI:render()
    if SurvivalHUD.SkipRender > 0 then return; end

    local player = getPlayer();
    if not player or player:isDead() then
        self:setVisible(false);
        return;
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum());
    local dash = getPlayerVehicleDashboard(player:getPlayerNum());
    local pscDash = getPlayerVehicleDashboardReplacer and getPlayerVehicleDashboardReplacer(player:getPlayerNum()) or nil;

    local anyPanelVisible = (hotbar and hotbar:isReallyVisible()) or (dash and dash:isReallyVisible()) or (pscDash and pscDash:isReallyVisible());
    if not anyPanelVisible then return; end

    self:setVisible(true);

    local val = player:getStats():get(CharacterStat.ENDURANCE);

    local isAiming = player:isAiming();
    local shouldFade = false;

    if not shouldFade and isAiming then
        if self:isMouseOver() then
            shouldFade = true;
        end
    end
    if shouldFade then
        self.fade:setFadeIn(false);
    else
        self.fade:setFadeIn(true);
    end
    self.fade:update();

    local globalAlpha = self.fade:fraction();
    if globalAlpha <= 0 then return; end

    local phase = self:getPhase(val);
    local sizeStr = tostring(SurvivalHUD.IconSize);
    local runTex = getTexture("media/ui/Needs/" .. sizeStr .. "/Endurance/Endurance_" .. phase .. ".png");

    if runTex then
        self:drawTextureScaled(runTex, 0, (self:getHeight() - self.iconSize) / 2, self.iconSize, self.iconSize, globalAlpha, 1, 1, 1);
    end

    local barX = self.iconSize + 10 * self.scale;
    local barY = (self:getHeight() - self.barH) / 2;
    self:drawRect(barX, barY, self.barW, self.barH, 0.5 * globalAlpha, 0, 0, 0);

    local fillW = math.max(0, self.barW * val);
    local col = self:getColor(val);
    if fillW > 0 then
        self:drawRect(barX, barY, fillW, self.barH, globalAlpha, col.r, col.g, col.b);
    end

    if globalAlpha > 0.9 and self:isMouseOver() and not player:isAiming() then
        local title = getText("Tooltip_HUD_Endurance");
        local desc = string.format("%s: %d%%", title, math.floor(val * 100 + 0.5));

        if phase > 0 then
            local moodleDesc = getText("Moodles_Endurance_desc_lvl" .. phase);
            if moodleDesc then
                desc = desc .. "\n" .. moodleDesc;
            end
        end

        local currentValues = { Endurance = val };
        SurvivalHUD.instance.tooltipUI:updateData(desc, "Endurance", currentValues, nil);
        SurvivalHUD.instance.tooltipUI:setVisible(true);
        SurvivalHUD.instance.tooltipUI:bringToTop();
        SurvivalHUD.instance.tooltipUI.currentOwner = "Endurance";
    else
        SurvivalHUD.instance:hideTooltipIfOwned("Endurance");
    end
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

function EnduranceUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
    o.fade = UITransition.new();

    return o;
end

SurvivalHUD.OnGameStart = function()
    if SurvivalHUD.instance then
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

SurvivalHUD.OnResolutionChange = function()
    SurvivalHUD.SkipRender = 15;
    if SurvivalHUD.instance then SurvivalHUD.instance.layoutDirty = true; end
    if EnduranceUI.instance then EnduranceUI.instance.layoutDirty = true; end
end

SurvivalHUD.OnPlayerUpdate = function()
    if SurvivalHUD.instance then
        SurvivalHUD.instance.layoutDirty = true;
    end
    if EnduranceUI.instance then
        EnduranceUI.instance.layoutDirty = true;
    end
end

SurvivalHUD.OnPlayerDeath = function()
    if SurvivalHUD.instance then
        SurvivalHUD.instance:setVisible(false);
        if SurvivalHUD.instance.tooltipUI then
            SurvivalHUD.instance.tooltipUI:setVisible(false);
        end
    end
    if EnduranceUI.instance then
        EnduranceUI.instance:setVisible(false);
    end
end

Events.OnGameStart.Add(SurvivalHUD.OnGameStart);
Events.OnPlayerDeath.Add(SurvivalHUD.OnPlayerDeath);
Events.OnCreatePlayer.Add(SurvivalHUD.OnGameStart);
Events.OnResolutionChange.Add(SurvivalHUD.OnResolutionChange);
Events.OnClothingUpdated.Add(SurvivalHUD.OnPlayerUpdate);
Events.OnEnterVehicle.Add(SurvivalHUD.OnPlayerUpdate);
Events.OnExitVehicle.Add(SurvivalHUD.OnPlayerUpdate);
Events.OnSwitchVehicleSeat.Add(SurvivalHUD.OnPlayerUpdate);

Events.OnGameBoot.Add(function()
    for _, size in ipairs({ 48, 64, 80 }) do
        local sizeStr = tostring(size);

        for statType, phases in pairs(SurvivalHUD.Phases) do
            local typeCap = statType:sub(1, 1):upper() .. statType:sub(2);

            for _, phase in ipairs(phases) do
                local phaseLevel = phase[3];

                if statType == "Temperature" then
                    if phaseLevel == "0" then
                        getTexture("media/ui/Needs/" .. sizeStr .. "/Temperature/Temperature_Background_0.png");
                        getTexture("media/ui/Needs/" .. sizeStr .. "/Temperature/Temperature_0_37.png");
                    elseif tostring(phaseLevel):sub(1, 1) == "-" then
                        local lvl = tostring(phaseLevel):sub(2);
                        getTexture("media/ui/Needs/" .. sizeStr .. "/Temperature/Hypothermia/Hypothermia_Background_" .. lvl .. ".png");
                        for _, val in ipairs(phase[4]) do
                            getTexture("media/ui/Needs/" .. sizeStr .. "/Temperature/Hypothermia/Hypothermia_" .. lvl .. "_" .. tostring(val):gsub("%.", "-") .. ".png");
                        end

                    else
                        local lvl = tostring(phaseLevel):sub(2);
                        getTexture("media/ui/Needs/" .. sizeStr .. "/Temperature/Hyperthermia/Hyperthermia_Background_" .. lvl .. ".png");
                        for _, val in ipairs(phase[4]) do
                            getTexture("media/ui/Needs/" .. sizeStr .. "/Temperature/Hyperthermia/Hyperthermia_" .. lvl .. "_" .. tostring(val):gsub("%.", "-") .. ".png");
                        end
                    end
                else
                    getTexture("media/ui/Needs/" .. sizeStr .. "/" .. typeCap .. "/" .. typeCap .. "_Background_" .. tostring(phaseLevel) .. ".png");
                    for _, val in ipairs(phase[4]) do
                        getTexture("media/ui/Needs/" .. sizeStr .. "/" .. typeCap .. "/" .. typeCap .. "_" .. tostring(phaseLevel) .. "_" .. tostring(val):gsub("%.", "-") .. ".png");
                    end
                end
            end
        end

        for i = 0, 4 do
            getTexture("media/ui/Needs/" .. sizeStr .. "/Endurance/Endurance_" .. i .. ".png");
        end

        for i = 1, 4 do
            local threshold = ({ 0, 1600, 3200, 4800 })[i];
            getTexture("media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_Background_" .. i .. ".png");
            getTexture("media/ui/Needs/" .. sizeStr .. "/FoodEaten/FoodEaten_" .. i .. "_" .. threshold .. ".png");
        end
    end

    for _, texSize in ipairs({ 16, 24, 32 }) do
        getTexture("media/ui/Chevron/" .. texSize .. "/Chevron-Up.png");
        getTexture("media/ui/Chevron/" .. texSize .. "/Chevron-Down.png");
    end
    
    for _, texSize in ipairs({ 32, 48, 64 }) do
        getTexture("media/ui/Separator/" .. texSize .. "/Separator.png");
    end
end);