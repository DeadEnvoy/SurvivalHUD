require "ISUI/ISHotbar";

local Utils = require("HUD/Utils");

local BASE_SLOT_SIZE = 64;
local HOTBAR_MARGIN = 0;
local BOTTOM_OFFSET = 15;
local DRAG_THRESHOLD = 5;
local HOTBAR_PAD_BASE = 8;
local SEP_SIZE_BASE = 40;

local function getHotbarPad(slotSize)
    return math.floor(HOTBAR_PAD_BASE * slotSize / 64 + 0.5);
end

local function getSepSize(slotSize)
    return math.floor(SEP_SIZE_BASE * slotSize / 64 + 0.5);
end

local function getSlotTexture(slotSize, textureName)
    return Utils.getPackTexture("media/ui/Hotbar/" .. slotSize .. "/Slot/" .. textureName .. ".png");
end

local function getHandTexture(slotSize, textureName)
    return Utils.getPackTexture("media/ui/Hotbar/" .. slotSize .. "/Hand/" .. textureName .. ".png");
end

function ISHotbar:setBaseSlotSize(size)
    BASE_SLOT_SIZE = size;
    local hotbar = getPlayerHotbar(0);
    if hotbar then
        hotbar:setSlotSize(size);
    end
end

function ISHotbar:getBaseSlotSize()
    return BASE_SLOT_SIZE;
end

function ISHotbar:setSlotSize(size)
    self.slotSize = size;
    self.slotWidth = size;
    self.slotHeight = size;
    self.slotPad = getHotbarPad(size);
    self:setSizeAndPosition();
end

local STANDARD_ICON_MAX_SIZE = 32;

local function getItemDrawDimensions(tex)
    if not tex then return 0, 0, false; end
    local origW = tex:getWidthOrig();
    local origH = tex:getHeightOrig();
    if not origW or origW <= 0 then origW = tex:getWidth(); end
    if not origH or origH <= 0 then origH = tex:getHeight(); end

    local maxDim = math.max(origW, origH);
    if maxDim > STANDARD_ICON_MAX_SIZE then
        local ratio = STANDARD_ICON_MAX_SIZE / maxDim;
        return math.floor(origW * ratio + 0.5), math.floor(origH * ratio + 0.5), true;
    end
    return origW, origH, false;
end

local CONDITION_PHASES = {
    { 75, 100, 0, { 100, 95, 90, 85, 80 } },
    { 50, 75, 1, { 75, 70, 65, 60, 55 } },
    { 25, 50, 2, { 50, 45, 40, 35, 30 } },
    { 10, 25, 3, { 25, 20, 15 } },
    { 0, 10, 4, { 10, 5 } },
};

local function getConditionPhase(conditionPercent)
    if not conditionPercent then return nil; end

    if conditionPercent >= CONDITION_PHASES[1][2] then
        return CONDITION_PHASES[1];
    end
    if conditionPercent <= CONDITION_PHASES[#CONDITION_PHASES][1] then
        return CONDITION_PHASES[#CONDITION_PHASES];
    end

    for _, phase in ipairs(CONDITION_PHASES) do
        if conditionPercent >= phase[1] and conditionPercent <= phase[2] then
            return phase;
        end
    end
    return CONDITION_PHASES[#CONDITION_PHASES];
end

local function getBestConditionTexture(conditionPercent, currentTexVal)
    local phase = getConditionPhase(conditionPercent);
    if not phase then return nil, nil; end

    local texValues = phase[4];
    if #texValues == 0 then return nil, nil; end

    if currentTexVal and math.abs(conditionPercent - currentTexVal) < 1.0 then
        for _, texVal in ipairs(texValues) do
            if texVal == currentTexVal then
                return currentTexVal, phase;
            end
        end
    end

    local bestVal = texValues[1];
    local bestDiff = math.abs(conditionPercent - bestVal);
    for _, texVal in ipairs(texValues) do
        local diff = math.abs(conditionPercent - texVal);
        if diff < bestDiff then
            bestDiff = diff;
            bestVal = texVal;
        end
    end
    return bestVal, phase;
end

local function getConditionTexture(conditionPercent, currentTexVal, kind, isFluid, slotSize)
    local texVal, phase = getBestConditionTexture(conditionPercent, currentTexVal);
    if not texVal or not phase then return nil, nil; end
    local phaseLevel = phase[3];
    local fluids = isFluid and "/Fluids" or "";
    local tex = Utils.getPackTexture("media/ui/Hotbar/" .. slotSize .. "/" .. kind .. fluids .. "/" .. kind .. "_" .. phaseLevel .. "_" .. texVal .. ".png");
    return tex, texVal;
end

local BATTERY_OFF_TINT = 0.5;

local FLUID_MIN_BRIGHTNESS = 0.6;

local function getFluidTint(color)
    local r, g, b = color:getR(), color:getG(), color:getB();
    local maxC = math.max(r, math.max(g, b));
    if maxC < FLUID_MIN_BRIGHTNESS then
        local mult = FLUID_MIN_BRIGHTNESS / math.max(maxC, 0.05);
        return math.min(1, r * mult), math.min(1, g * mult), math.min(1, b * mult);
    end
    return r, g, b;
end

local function getItemConditionPercent(item, includeOffState)
    if instanceof(item, "HandWeapon") then
        local maxCond = item:getConditionMax();
        if maxCond > 0 then
            local handleRatio = item:getCondition() / maxCond;
            local ratio = handleRatio;
            if item.hasHeadCondition and item:hasHeadCondition() then
                local headMax = item:getHeadConditionMax();
                if headMax > 0 then
                    local headRatio = item:getHeadCondition() / headMax;
                    ratio = math.min(handleRatio, headRatio);
                end
            end
            ratio = math.max(0, math.min(1, ratio));
            if ratio <= 0 or item:isBroken() then
                return nil;
            end
            return math.floor(ratio * 100 + 0.5), 1, 1, 1, 1;
        end
    elseif instanceof(item, "Radio") then
        local deviceData = item:getDeviceData();
        if deviceData and deviceData:getIsBatteryPowered() and deviceData:getHasBattery() then
            local percent = math.floor(deviceData:getPower() * 100 + 0.5);
            if percent <= 0 then
                return nil;
            end
            if deviceData:getIsTurnedOn() then
                return percent, 1, 1, 1, 1;
            end
            if includeOffState then
                return percent, BATTERY_OFF_TINT, BATTERY_OFF_TINT, BATTERY_OFF_TINT, 1;
            end
        end
    elseif instanceof(item, "DrainableComboItem") and item:canBeActivated() then
        local percent = math.floor(item:getCurrentUsesFloat() * 100 + 0.5);
        if percent <= 0 then
            return nil;
        end
        if item:isActivated() then
            return percent, 1, 1, 1, 1;
        end
        if includeOffState then
            return percent, BATTERY_OFF_TINT, BATTERY_OFF_TINT, BATTERY_OFF_TINT, 1;
        end
    end
    if item:hasComponent(ComponentType.FluidContainer) then
        local fluidContainer = item:getFluidContainer();
        if fluidContainer and not fluidContainer:isEmpty() then
            local color = fluidContainer:getColor();
            local tintR, tintG, tintB = getFluidTint(color);
            return math.floor(fluidContainer:getAmount() / fluidContainer:getCapacity() * 100 + 0.5), tintR, tintG, tintB, 1;
        end
    end
    return nil;
end

local dragPreviewUI = nil;

local function getMainWidth(slotCount, slotSize)
    return slotCount * slotSize + (slotCount - 1) * getHotbarPad(slotSize);
end

local function calcTotalWidth(slotCount, slotSize)
    local mainW = getMainWidth(slotCount, slotSize);
    return slotSize + getSepSize(slotSize) + mainW + getSepSize(slotSize) + slotSize;
end

local function getHotbarHeight(slotSize)
    return slotSize;
end

local PULSE_PERIOD_MS = 1000;

local function getPulseFactor()
    local progress = (getTimestampMs() % PULSE_PERIOD_MS) / PULSE_PERIOD_MS;
    return 0.75 - 0.25 * math.cos(progress * (math.pi * 2));
end

local function drawConditionOverlay(self, x, item, texValCache, cacheKey, kind, includeOffState, isEquipped)
    local val, tintR, tintG, tintB, overlayAlpha = getItemConditionPercent(item, includeOffState);
    if not val then return; end
    val = math.max(0, math.min(100, val));
    local isFluid = item:hasComponent(ComponentType.FluidContainer);
    local conTex, newTexVal = getConditionTexture(val, texValCache[cacheKey], kind, isFluid, self.slotSize);
    if newTexVal then texValCache[cacheKey] = newTexVal; end
    if conTex then
        if isEquipped and instanceof(item, "HandWeapon") and item:isJammed() then
            overlayAlpha = overlayAlpha * getPulseFactor();
        end
        self:drawTexture(conTex, x, HOTBAR_MARGIN, overlayAlpha, tintR, tintG, tintB);
    end
end

local JAMMED_TEXT_COLOR = { r = 1, g = 0.25, b = 0.25, a = 1 };

local function getAmmoDisplayText(item)
    if not item then return nil; end

    if not instanceof(item, "HandWeapon") then
        if item:getMaxAmmo() > 0 then
            return item:getCurrentAmmoCount() .. "/" .. item:getMaxAmmo(), false;
        end
        return nil;
    end

    if not (item:isRanged() and item:getMaxAmmo() > 0) then
        return nil;
    end

    local isJammed = item:isJammed();
    if item:getMagazineType() and item:isContainsClip() then
        local chamberFlag = isJammed and "X" or (item:isRoundChambered() and "1" or "0");
        return chamberFlag .. " (" .. item:getCurrentAmmoCount() .. ")", isJammed;
    end

    if isJammed then
        return "X", true;
    end

    if item:haveChamber() then
        return tostring(item:getCurrentAmmoCount() + (item:isRoundChambered() and 1 or 0)), false;
    end

    return tostring(item:getCurrentAmmoCount()), false;
end

local function drawSlotLabel(self, x, size, text, customColor)
    local fontHgt = getTextManager():getFontHeight(UIFont.Small);
    local textWid = getTextManager():MeasureStringX(UIFont.Small, text);
    local labelX = x + math.floor((size - textWid) / 2);
    self:drawRect(labelX - 2, -fontHgt, textWid + 4, fontHgt, 0.6, 0, 0, 0);
    local col = customColor or self.textColor;
    self:drawText(text, labelX, -fontHgt, col.r, col.g, col.b, col.a, UIFont.Small);
end

local function drawItemIcon(self, x, item, isEquipped)
    local tex = item:getTexture();
    if not tex then return; end
    local w, h, isScaled = getItemDrawDimensions(tex);
    local ix = x + math.floor((self.slotSize - w) / 2);
    local iy = HOTBAR_MARGIN + math.floor((self.slotSize - h) / 2);
    local iconAlpha = 1.0;
    local shadowAlpha = 0.25;
    if isEquipped and instanceof(item, "HandWeapon") and (item:isBroken() or item:getCondition() <= 0) then
        local pulse = getPulseFactor();
        iconAlpha = pulse;
        shadowAlpha = 0.25 * pulse;
    end
    if isScaled then
        self:drawTextureScaled(tex, ix + 1, iy + 1, w, h, shadowAlpha, 0, 0, 0);
        self:drawTextureScaled(tex, ix, iy, w, h, iconAlpha, 1, 1, 1);
    else
        self:drawTexture(tex, ix + 1, iy + 1, shadowAlpha, 0, 0, 0);
        self:drawTexture(tex, ix, iy, iconAlpha, 1, 1, 1);
    end
end

local function drawHandSlot(self, x, item, isSelected, isHovered, isPrimary)
    local bg = getHandTexture(self.slotSize, "Hand_Background");
    local inHotbar = item and self:isInHotbar(item);
    local showSelected = isSelected and not inHotbar;
    local alpha = showSelected and 1.0 or 0.75;

    if bg then
        self:drawTexture(bg, x, HOTBAR_MARGIN, alpha, 1, 1, 1);
    end

    if showSelected and item then
        drawConditionOverlay(self, x, item, self.handTexVal, isPrimary and "primary" or "secondary", "Hand", true, true);
    end

    if showSelected then
        local selTex = getHandTexture(self.slotSize, "Hand_Selected");
        if selTex then
            self:drawTexture(selTex, x, HOTBAR_MARGIN, 1, 1, 1, 1);
        end
    end

    if isHovered then
        local hoverTex = getHandTexture(self.slotSize, "Hand_Hover");
        if hoverTex then
            self:drawTexture(hoverTex, x, HOTBAR_MARGIN, 0.25, 1, 1, 1);
        end
        drawSlotLabel(self, x, self.slotSize, isPrimary and getText("IGUI_PrimaryTooltip") or getText("IGUI_SecondaryTooltip"));
    elseif showSelected and item then
        local ammoText, isJammed = getAmmoDisplayText(item);
        if ammoText then
            drawSlotLabel(self, x, self.slotSize, ammoText, isJammed and JAMMED_TEXT_COLOR);
        end
    end

    if item then
        drawItemIcon(self, x, item, showSelected);
    end
end

local function drawSeparator(self, x)
    local sepSize = Utils.SeparatorConfig[self.slotSize];
    local sepTotalW = getSepSize(self.slotSize);
    local lineInset = math.floor(4 * self.slotSize / 64 + 0.5);
    if sepSize then
        local sep = Utils.getPackTexture("media/ui/Separator/" .. sepSize .. "/Separator.png");
        if sep then
            local sx = x + math.floor((sepTotalW - sepSize) / 2);
            local sy = HOTBAR_MARGIN + math.floor((self.slotSize - sepSize) / 2);
            self:drawTexture(sep, sx, sy, 0.5, 1, 1, 1);
            return;
        end
    end
    self:drawRect(x + math.floor(sepTotalW / 2), HOTBAR_MARGIN + lineInset, 1, self.slotSize - lineInset * 2, 0.4, 1, 1, 1);
end

local function isMouseOverNotBlocked(self)
    if not self:isReallyVisible() then return false; end

    local mx = getMouseX();
    local my = getMouseY();
    local ax = self:getAbsoluteX();
    local ay = self:getAbsoluteY();
    if mx < ax or mx >= ax + self.width or my < ay or my >= ay + self.height then
        return false;
    end
    local uis = UIManager.getUI();
    if not uis or not self.javaObject then return true; end
    local myToolRender = self.toolRender;
    local myToolJava = myToolRender and myToolRender.javaObject;
    local dragJava = dragPreviewUI and dragPreviewUI.javaObject;
    for i = uis:size() - 1, 0, -1 do
        local other = uis:get(i);
        if other == self.javaObject then break; end
        if other ~= myToolRender and other ~= myToolJava and other ~= dragPreviewUI and other ~= dragJava then
            if other:isVisible() and other:isPointOver(mx, my) then
                return false;
            end
        end
    end
    return true;
end

local HotbarDragPreview = ISPanel:derive("HotbarDragPreview");

function HotbarDragPreview:prerender()
end

function HotbarDragPreview:render()
    if ISHotbar.hotbarDraggingItem then
        local tex = ISHotbar.hotbarDraggingItem:getTexture();
        if tex then
            local w, h, isScaled = getItemDrawDimensions(tex);
            local mx = getMouseX() - math.floor(w / 2);
            local my = getMouseY() - math.floor(h / 2);
            if isScaled then
                self:drawTextureScaled(tex, mx, my, w, h, 0.5, 1, 1, 1);
            else
                self:drawTexture(tex, mx, my, 0.5, 1, 1, 1);
            end
        end
    end
end

function HotbarDragPreview:new()
    local o = ISPanel:new(0, 0, 1, 1);
    setmetatable(o, self)
    self.__index = self
    o:noBackground();
    o.suspend = true;
    return o
end

local function ensureDragPreviewUI()
    if not dragPreviewUI then
        dragPreviewUI = HotbarDragPreview:new();
        dragPreviewUI:initialise();
        dragPreviewUI:addToUIManager();
        dragPreviewUI:setAlwaysOnTop(true);
    end
end

local function removeDragPreviewUI()
    if dragPreviewUI then
        dragPreviewUI:removeFromUIManager();
        dragPreviewUI = nil;
    end
end

local function resetDragCandidate()
    ISHotbar.dragCandidateSlot = nil;
    ISHotbar.dragStartX = nil;
    ISHotbar.dragStartY = nil;
    ISHotbar.dragCandidatePlayer = nil;
end

function ISHotbar:prerender()
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    self.borderColor = { r = 0, g = 0, b = 0, a = 0 };
end

function ISHotbar:render()
    if (self.playerNum > 0) or JoypadState.players[self.playerNum + 1] then
        self:setVisible(false);
    end

    local chr = self.character;
    local primaryItem = chr:getPrimaryHandItem();
    local secondaryItem = chr:getSecondaryHandItem();
    local mouseOverSlotIndex = isMouseOverNotBlocked(self) and self:getSlotIndexAt(self:getMouseX(), self:getMouseY()) or -1;
    local hoveredHand = isMouseOverNotBlocked(self) and self:getHandSlotIndexAt(self:getMouseX(), self:getMouseY()) or -1;

    local draggedItem = nil;
    if ISHotbar.hotbarDraggingItem and ISHotbar.hotbarDraggingFrom == self.playerNum then
        draggedItem = ISHotbar.hotbarDraggingItem;
    elseif ISMouseDrag.dragging then
        local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging);
        if dragging and #dragging > 0 then
            draggedItem = dragging[1];
        end
    end

    local bg = getSlotTexture(self.slotSize, "Slot_Background");

    drawHandSlot(self, 0, secondaryItem, secondaryItem ~= nil, hoveredHand == -2, false);
    drawSeparator(self, self.slotSize);
    local slotX = self.slotSize + getSepSize(self.slotSize);

    for i, slot in pairs(self.availableSlot) do
        local item = self.attachedItems[i];
        local isSelected = item and item:isEquipped();
        local bgAlpha = isSelected and 1.0 or 0.75;

        if bg then
            self:drawTexture(bg, slotX, HOTBAR_MARGIN, bgAlpha, 1, 1, 1);
        end

        if isSelected then
            drawConditionOverlay(self, slotX, item, self.slotTexVal, i, "Slot", true, true);
            local selTex = getSlotTexture(self.slotSize, "Slot_Selected");
            if selTex then
                self:drawTexture(selTex, slotX, HOTBAR_MARGIN, 1, 1, 1, 1);
            end
        elseif item and item:canBeActivated() then
            drawConditionOverlay(self, slotX, item, self.slotTexVal, i, "Slot", false, false);
            if item:isActivated() then
                local selTex = getSlotTexture(self.slotSize, "Slot_Selected");
                if selTex then
                    self:drawTexture(selTex, slotX, HOTBAR_MARGIN, 1, 1, 1, 1);
                end
            end
        end

        local indexInsetX = math.floor(8 * self.slotSize / 64 + 0.5);
        local indexInsetY = math.floor(5 * self.slotSize / 64 + 0.5);
        local indexFont = self.slotSize >= 80 and UIFont.Medium or UIFont.Small;
        self:drawText(tostring(i), slotX + indexInsetX + 1, HOTBAR_MARGIN + indexInsetY + 1, 0, 0, 0, 0.75, indexFont);
        self:drawText(tostring(i), slotX + indexInsetX, HOTBAR_MARGIN + indexInsetY, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, indexFont);

        if i == mouseOverSlotIndex then
            local r, g, b = 1, 1, 1;
            if draggedItem then
                if not self:canBeAttached(slot, draggedItem) then
                    r, g, b = 1, 0, 0;
                end
            end
            local highlightInset = math.floor(4 * self.slotSize / 64 + 0.5);
            self:drawRect(slotX + highlightInset, HOTBAR_MARGIN + highlightInset, self.slotSize - highlightInset * 2, self.slotSize - highlightInset * 2, 0.25, r, g, b);

            drawSlotLabel(self, slotX, self.slotSize, getTextOrNull("IGUI_HotbarAttachment_" .. slot.slotType) or slot.name);
        elseif isSelected and item then
            local ammoText, isJammed = getAmmoDisplayText(item);
            if ammoText then
                drawSlotLabel(self, slotX, self.slotSize, ammoText, isJammed and JAMMED_TEXT_COLOR);
            end
        end

        if item then
            drawItemIcon(self, slotX, item, isSelected);
        elseif slot.texture then
            local st = slot.texture;
            local w, h, isScaled = getItemDrawDimensions(st);
            local ix = slotX + math.floor((self.slotSize - w) / 2);
            local iy = HOTBAR_MARGIN + math.floor((self.slotSize - h) / 2);
            if isScaled then
                self:drawTextureScaled(st, ix, iy, w, h, 0.25, 1, 1, 1);
            else
                self:drawTexture(st, ix, iy, 0.25, 1, 1, 1);
            end
        end

        slotX = slotX + self.slotSize + getHotbarPad(self.slotSize);
    end

    local rightSepX = slotX - getHotbarPad(self.slotSize);
    drawSeparator(self, rightSepX);

    local rightHandX = rightSepX + getSepSize(self.slotSize);
    drawHandSlot(self, rightHandX, primaryItem, primaryItem ~= nil, hoveredHand == -3, true);
end

function ISHotbar:setSizeAndPosition()
    local count = math.max(#self.availableSlot, 1);
    local w = calcTotalWidth(count, self.slotSize);
    local h = getHotbarHeight(self.slotSize);
    self:setWidth(w);
    self:setHeight(h);
    local screenW = getCore():getScreenWidth();
    local screenH = getCore():getScreenHeight();
    self:setX(math.floor((screenW - w) / 2));
    self:setY(screenH - h - BOTTOM_OFFSET);
end

local original_new = ISHotbar.new;
function ISHotbar:new(character)
    local o = original_new(self, character);

    o.slotSize = BASE_SLOT_SIZE;
    o.slotWidth = o.slotSize;
    o.slotHeight = o.slotSize;
    o.slotPad = getHotbarPad(o.slotSize);
    o.margins = HOTBAR_MARGIN;

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
    o.slotTexVal = {};
    o.handTexVal = {};

    local count = math.max(#o.availableSlot, 1);
    o.width = calcTotalWidth(count, o.slotSize);
    o.height = getHotbarHeight(o.slotSize);

    return o
end

Functions.PostHook.Add(ISHotbar, "refresh", function(self)
    self.slotSize = self.slotSize or BASE_SLOT_SIZE;
    local count = math.max(#self.availableSlot, 1);
    self:setWidth(calcTotalWidth(count, self.slotSize));
    self:setHeight(getHotbarHeight(self.slotSize));
end)

function ISHotbar:getSlotIndexAt(x, y)
    if y < 0 or y >= self.height then return -1; end
    local mainStartX = self.slotSize + getSepSize(self.slotSize);
    local slotCount = #self.availableSlot;
    local mainEndX = mainStartX + getMainWidth(slotCount, self.slotSize);
    if x >= mainStartX and x < mainEndX then
        local index = math.floor((x - mainStartX) / (self.slotSize + getHotbarPad(self.slotSize))) + 1;
        index = math.max(index, 1);
        return math.min(index, slotCount);
    end
    return -1;
end

function ISHotbar:getHandSlotIndexAt(x, y)
    if y < 0 or y >= self.height then return -1; end
    local slotCount = #self.availableSlot;
    local mainEndX = self.slotSize + getSepSize(self.slotSize) + getMainWidth(slotCount, self.slotSize);
    if x >= 0 and x < self.slotSize then
        return -2;
    end
    local rightHandX = mainEndX + getSepSize(self.slotSize);
    if x >= rightHandX and x < rightHandX + self.slotSize then
        return -3;
    end
    return -1;
end

function ISHotbar:update()
    local moodleUI = UIManager.getMoodleUI(self.playerNum);
    if not self:isVisible() and moodleUI and moodleUI:isVisible() and not JoypadState.players[self.playerNum+1] then
        self:setVisible(true);
    end

    if self.character:getVehicle() and self.character:getVehicle():isDriver(self.character) then
        self:setVisible(false);
    end

    if self.needsRefresh then
        self:refresh();
    end

    self:setSizeAndPosition();

    if ISHotbar.dragCandidateSlot and not ISHotbar.hotbarDraggingItem and ISHotbar.dragCandidatePlayer == self.playerNum then
        local dx = math.abs(getMouseX() - ISHotbar.dragStartX);
        local dy = math.abs(getMouseY() - ISHotbar.dragStartY);
        if dx > DRAG_THRESHOLD or dy > DRAG_THRESHOLD then
            local candidateSlot = ISHotbar.dragCandidateSlot;
            local item;
            if candidateSlot >= 1 then
                item = self.attachedItems[candidateSlot];
            elseif candidateSlot == -2 then
                item = self.character:getSecondaryHandItem();
            elseif candidateSlot == -3 then
                item = self.character:getPrimaryHandItem();
            end
            if item then
                ISHotbar.hotbarDraggingItem = item;
                ISHotbar.hotbarDraggingSlot = candidateSlot;
                ISHotbar.hotbarDraggingFrom = self.playerNum;
                ensureDragPreviewUI();
            end
            resetDragCandidate();
        end
    end

    local queue = ISTimedActionQueue.queues[self.character];
    if not (queue and #queue.queue > 0) then
        for i, item in pairs(self.attachedItems) do
            local slot = self.availableSlot[item:getAttachedSlot()]
            if not slot or not self:canBeAttached(slot, item) or not self.chr:getInventory():contains(item) or item:isBroken() then
                self:removeItem(item, false);
                self.chr:removeAttachedItem(item);
            else
                local slotDef = slot.def;
                if self.chr:isEquipped(item) then
                    self.chr:removeAttachedItem(item);
                elseif not self.chr:getAttachedItem(item:getAttachedToModel()) then
                    self:attachItem(item, slotDef.attachments[item:getAttachmentType()], item:getAttachedSlot(), slotDef, false)
                end
            end
        end
    end

    if not isMouseOverNotBlocked(self) then
        if self.toolRender then
            self.toolRender:setVisible(false);
        end
        return;
    end

    local contextVisible = getPlayerContextMenu(self.playerNum):isAnyVisible();
    local handSlot = self:getHandSlotIndexAt(self:getMouseX(), self:getMouseY());
    local handItem = nil;
    if handSlot == -2 then
        handItem = self.character:getSecondaryHandItem();
    elseif handSlot == -3 then
        handItem = self.character:getPrimaryHandItem();
    end

    local slotIndex = self:getSlotIndexAt(self:getMouseX(), self:getMouseY());
    local slotItem = (slotIndex ~= -1) and self.attachedItems[slotIndex];

    local tooltipItem = not contextVisible and (handItem or slotItem);

    if tooltipItem then
        if self.toolRender then
            self.toolRender:setItem(tooltipItem);
            self.toolRender:bringToTop();
        else
            self.toolRender = ISToolTipInv:new(tooltipItem);
            self.toolRender:initialise();
            self.toolRender:addToUIManager();
            self.toolRender:setOwner(self);
            self.toolRender:setCharacter(getSpecificPlayer(self.playerNum));
            if self.toolRender.javaObject then
                self.toolRender.javaObject:setConsumeMouseEvents(false);
            end
        end
        self.toolRender:setVisible(true);
    elseif self.toolRender then
        self.toolRender:setVisible(false);
    end
end

function ISHotbar:onRightMouseUp(x, y)
    if not isMouseOverNotBlocked(self) then return; end
    local handSlot = self:getHandSlotIndexAt(x, y);
    local item = nil;
    if handSlot == -2 then
        item = self.character:getSecondaryHandItem();
    elseif handSlot == -3 then
        item = self.character:getPrimaryHandItem();
    else
        local slotIndex = self:getSlotIndexAt(x, y);
        if slotIndex >= 1 then
            item = self.attachedItems[slotIndex];
        end
    end

    if item then
        ISInventoryPaneContextMenu.createMenu(self.character:getPlayerNum(), true, { item }, getMouseX(), getMouseY());
    end
end

function ISHotbar:activateSlot(slotIndex)
    local item = self.attachedItems[slotIndex];
    if not item then return end
    if item:getAttachedSlot() ~= slotIndex then
        error "item:getAttachedSlot() ~= slotIndex";
    end
    if item:canBeActivated() and not instanceof(item, "HandWeapon") then
        item:setActivated(not item:isActivated());
        syncItemActivated(self.chr, item);
        item:playActivateDeactivateSound();
        return;
    end

    ISInventoryPaneContextMenu.transferIfNeeded(self.chr, item);

    local primary = self.chr:getPrimaryHandItem();
    local secondary = self.chr:getSecondaryHandItem();

    local isEquipped = (primary == item) or (secondary == item);
    if isEquipped then
        ISTimedActionQueue.add(ISUnequipAction:new(self.chr, item, 20));
        return;
    end

    local bothHands = item:isTwoHandWeapon();
    local goToPrimary = bothHands or item:IsWeapon();

    if not goToPrimary then
        if secondary and not primary then
            goToPrimary = true;
        end
    end

    if goToPrimary then
        if primary and primary ~= item then
            if self:isInHotbar(primary) then
                ISTimedActionQueue.add(ISUnequipAction:new(self.chr, primary, 20));
            end
        end
        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, true, bothHands));
    else
        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, false, false));
    end

    self.chr:getInventory():setDrawDirty(true);
    getPlayerData(self.chr:getPlayerNum()).playerInventory:refreshBackpacks();
end

function ISHotbar:onMouseUp(x, y)
    if ISHotbar.dragCandidateSlot and ISHotbar.dragCandidatePlayer == self.playerNum then
        resetDragCandidate();
    end

    if ISHotbar.hotbarDraggingItem and ISHotbar.hotbarDraggingFrom == self.playerNum then
        local fromSlot = ISHotbar.hotbarDraggingSlot;
        local toSlot = self:getSlotIndexAt(x, y);
        local targetHandSlot = self:getHandSlotIndexAt(x, y);
        local dragItem = ISHotbar.hotbarDraggingItem;

        ISHotbar.hotbarDraggingItem = nil;
        ISHotbar.hotbarDraggingSlot = nil;
        ISHotbar.hotbarDraggingFrom = nil;
        removeDragPreviewUI();

        if toSlot >= 1 and fromSlot ~= toSlot then
            if fromSlot == -2 or fromSlot == -3 then
                local slot = self.availableSlot[toSlot];
                if slot and self.attachedItems[toSlot] ~= dragItem and self:canBeAttached(slot, dragItem) then
                    self:attachItem(dragItem, slot.def.attachments[dragItem:getAttachmentType()], toSlot, slot.def, true);
                end
                return;
            end

            local item = self.attachedItems[fromSlot];
            local slot = self.availableSlot[toSlot];
            if not (item and slot and self:canBeAttached(slot, item)) then
                return;
            end

            local wasEquipped = item:isEquipped();
            local existingItem = self.attachedItems[toSlot];
            if existingItem then
                local fromSlotDef = self.availableSlot[fromSlot];
                if fromSlotDef and self:canBeAttached(fromSlotDef, existingItem) then
                    self:removeItem(item, false);
                    self:removeItem(existingItem, false);
                    self:attachItem(item, slot.def.attachments[item:getAttachmentType()], toSlot, slot.def, false);
                    if wasEquipped then
                        self.chr:removeAttachedItem(item);
                        item:setAttachedSlot(toSlot);
                        item:setAttachedSlotType(slot.def.type);
                        item:setAttachedToModel(slot.def.attachments[item:getAttachmentType()]);
                        self:reloadIcons();
                    end
                    self:attachItem(existingItem, fromSlotDef.def.attachments[existingItem:getAttachmentType()], fromSlot, fromSlotDef.def, true);
                end
            else
                self:removeItem(item, false);
                if wasEquipped then
                    self.chr:removeAttachedItem(item);
                    item:setAttachedSlot(toSlot);
                    item:setAttachedSlotType(slot.def.type);
                    item:setAttachedToModel(slot.def.attachments[item:getAttachmentType()]);
                    self:reloadIcons();
                end
                self:attachItem(item, slot.def.attachments[item:getAttachmentType()], toSlot, slot.def, true);
            end
            return;
        end

        if targetHandSlot == -2 or targetHandSlot == -3 then
            local isPrimaryTarget = (targetHandSlot == -3);
            local targetItem = isPrimaryTarget and self.character:getPrimaryHandItem() or self.character:getSecondaryHandItem();

            if fromSlot >= 1 then
                local item = self.attachedItems[fromSlot];
                if item then
                    if targetItem and targetItem ~= item and not self:isInHotbar(targetItem) then
                        local fromSlotDef = self.availableSlot[fromSlot];
                        if fromSlotDef and self:canBeAttached(fromSlotDef, targetItem) then
                            self:attachItem(targetItem, fromSlotDef.def.attachments[targetItem:getAttachmentType()], fromSlot, fromSlotDef.def, false);
                        end
                    end
                    ISInventoryPaneContextMenu.transferIfNeeded(self.chr, item);
                    ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, isPrimaryTarget, isPrimaryTarget and item:isTwoHandWeapon()));
                end
            elseif (fromSlot == -2 or fromSlot == -3) and fromSlot ~= targetHandSlot and dragItem then
                if targetItem and targetItem ~= dragItem then
                    ISInventoryPaneContextMenu.transferIfNeeded(self.chr, targetItem);
                end
                ISInventoryPaneContextMenu.transferIfNeeded(self.chr, dragItem);
                ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, dragItem, 20, isPrimaryTarget, isPrimaryTarget and dragItem:isTwoHandWeapon()));
                if targetItem and targetItem ~= dragItem then
                    ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, targetItem, 20, not isPrimaryTarget, not isPrimaryTarget and targetItem:isTwoHandWeapon()));
                end
            end
        end
        return;
    end

    if not isMouseOverNotBlocked(self) then
        return;
    end

    if ISMouseDrag.dragging then
        local handSlot = self:getHandSlotIndexAt(x, y);
        if handSlot == -2 or handSlot == -3 then
            local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging);
            if dragging and #dragging > 0 then
                local item = dragging[1];
                local isPrimary = (handSlot == -3);
                ISInventoryPaneContextMenu.transferIfNeeded(self.chr, item);
                ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, isPrimary, isPrimary and item:isTwoHandWeapon()));
            end
            return;
        end

        local slotIndex = self:getSlotIndexAt(x, y);
        if slotIndex >= 1 then
            local slot = self.availableSlot[slotIndex];
            local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging);
            if dragging and #dragging > 0 and slot and self:canBeAttached(slot, dragging[1]) then
                self:attachItem(dragging[1], slot.def.attachments[dragging[1]:getAttachmentType()], slotIndex, slot.def, true);
            end
        end
        return;
    end

    local slotIndex = self:getSlotIndexAt(x, y);
    if slotIndex >= 1 then
        if self:isAllowedToActivateSlot() then
            self:activateSlot(slotIndex);
        end
        return;
    end

    local handSlot = self:getHandSlotIndexAt(x, y);
    if (handSlot == -2 or handSlot == -3) and self:isAllowedToActivateSlot() then
        local item = (handSlot == -2) and self.character:getSecondaryHandItem() or self.character:getPrimaryHandItem();
        if item then
            self:equipItem(item);
        end
    end
end


function ISHotbar:onMouseUpOutside(x, y)
    if ISHotbar.dragCandidateSlot and ISHotbar.dragCandidatePlayer == self.playerNum then
        resetDragCandidate();
    end

    if ISHotbar.hotbarDraggingItem and ISHotbar.hotbarDraggingFrom == self.playerNum then
        ISHotbar.hotbarDraggingItem = nil;
        ISHotbar.hotbarDraggingSlot = nil;
        ISHotbar.hotbarDraggingFrom = nil;
        removeDragPreviewUI();
        return;
    end
end

function ISHotbar:onMouseDown(x, y)
    if not isMouseOverNotBlocked(self) then return; end
    if ISMouseDrag.dragging or ISHotbar.hotbarDraggingItem then return; end

    local handSlot = self:getHandSlotIndexAt(x, y);
    local slot = (handSlot == -2 or handSlot == -3) and handSlot or self:getSlotIndexAt(x, y);
    if slot == -1 then return; end

    local item;
    if slot == -2 then
        item = self.character:getSecondaryHandItem();
    elseif slot == -3 then
        item = self.character:getPrimaryHandItem();
    else
        item = self.attachedItems[slot];
    end

    if item then
        ISHotbar.dragCandidateSlot = slot;
        ISHotbar.dragStartX = getMouseX();
        ISHotbar.dragStartY = getMouseY();
        ISHotbar.dragCandidatePlayer = self.playerNum;
    end
end

local function onPlayerDeath()
    ISMouseDrag.dragging = nil;
    ISMouseDrag.draggingFocus = nil;
    ISMouseDrag.dragView = nil;
    ISHotbar.hotbarDraggingItem = nil;
    ISHotbar.hotbarDraggingSlot = nil;
    ISHotbar.hotbarDraggingFrom = nil;
    removeDragPreviewUI();
    resetDragCandidate();
end

local function onGameBoot()
    for _, size in ipairs({ 48, 64, 80 }) do
        for _, kind in ipairs({ "Slot", "Hand" }) do
            for _, textureName in ipairs({ kind .. "_Background", kind .. "_Selected" }) do
                Utils.getPackTexture("media/ui/Hotbar/" .. size .. "/" .. kind .. "/" .. textureName .. ".png");
            end
            if kind == "Hand" then
                Utils.getPackTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_Hover.png");
            end

            for _, phaseData in ipairs(CONDITION_PHASES) do
                local phaseLevel = phaseData[3];
                for _, threshold in ipairs(phaseData[4]) do
                    Utils.getPackTexture("media/ui/Hotbar/" .. size .. "/" .. kind .. "/" .. kind .. "_" .. phaseLevel .. "_" .. threshold .. ".png");
                    local fluidPath = "media/ui/Hotbar/" .. size .. "/" .. kind .. "/Fluids/" .. kind .. "_" .. phaseLevel .. "_" .. threshold .. ".png";
                    if fileExists(fluidPath) then
                        Utils.getPackTexture(fluidPath);
                    end
                end
            end
        end
    end
end

Events.OnPlayerDeath.Add(onPlayerDeath);
Events.OnGameBoot.Add(onGameBoot);