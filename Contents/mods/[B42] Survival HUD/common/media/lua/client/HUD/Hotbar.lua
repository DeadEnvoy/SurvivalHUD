require "ISUI/ISHotbar";

local Utils = require("HUD/Utils");

if getActivatedMods():contains("CleanHotBar") then
    return;
end

HotbarReskin = {};

HotbarReskin.HOTBAR_SIZE = 64;
HotbarReskin.CURRENT_HOTBAR_SIZE = 64;

local HOTBAR_MARGIN = 0;

local DRAG_THRESHOLD = 5;

local HOTBAR_PAD_BASE = 8;
local SEP_SIZE_BASE = 40;

local function getHotbarPad()
    return math.floor(HOTBAR_PAD_BASE * HotbarReskin.CURRENT_HOTBAR_SIZE / 64 + 0.5);
end

local function getSepSize()
    return math.floor(SEP_SIZE_BASE * HotbarReskin.CURRENT_HOTBAR_SIZE / 64 + 0.5);
end

local function getSlotTexture(textureName)
    local size = HotbarReskin.CURRENT_HOTBAR_SIZE;
    return getTexture("media/ui/Hotbar/" .. size .. "/Slot/" .. textureName .. ".png");
end

local function getHandTexture(textureName)
    local size = HotbarReskin.CURRENT_HOTBAR_SIZE;
    return getTexture("media/ui/Hotbar/" .. size .. "/Hand/" .. textureName .. ".png");
end

local ITEM_BASE_MAX_SIDE = 56;

local function getItemDrawSize(tex, slotScale)
    local w, h = tex:getWidth(), tex:getHeight();
    local maxDim = math.max(w, h);
    if maxDim > ITEM_BASE_MAX_SIDE then
        local ratio = ITEM_BASE_MAX_SIDE / maxDim;
        w = w * ratio;
        h = h * ratio;
    end
    return math.floor(w * slotScale + 0.5), math.floor(h * slotScale + 0.5);
end

local CONDITION_PHASES = {
    { 75, 100, 0, { 100, 95, 90, 85, 80 } },
    { 50, 75, 1, { 75, 70, 65, 60, 55 } },
    { 25, 50, 2, { 50, 45, 40, 35, 30 } },
    { 10, 25, 3, { 25, 30, 25, 20, 15 } },
    { 0, 10, 4, { 10, 5 } },
};

local function getConditionPhase(conditionPercent)
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

    if currentTexVal ~= -1 and math.abs(conditionPercent - currentTexVal) < 1.0 then
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

local function getConditionTexture(conditionPercent, currentTexVal, kind, isFluid)
    local size = HotbarReskin.CURRENT_HOTBAR_SIZE;
    local texVal, phase = getBestConditionTexture(conditionPercent, currentTexVal ~= nil and currentTexVal or -1);
    if not texVal or not phase then return nil, nil; end
    local phaseLevel = phase[3];
    local fluids = isFluid and "/Fluids" or "";
    local tex = getTexture("media/ui/Hotbar/" .. size .. "/" .. kind .. fluids .. "/" .. kind .. "_" .. phaseLevel .. "_" .. texVal .. ".png");
    return tex, texVal;
end

local BATTERY_OFF_TINT = 0.5;

local FLUID_MIN_LIGHTNESS = 55;

local function srgbToLinear(c)
    if c > 0.04045 then
        return ((c + 0.055) / 1.055) ^ 2.4;
    end
    return c / 12.92;
end

local function linearToSrgb(c)
    if c > 0.0031308 then
        return 1.055 * c ^ 0.41666666 - 0.055;
    end
    return c * 12.92;
end

local function clamp01(v)
    if v < 0 then return 0; end
    if v > 1 then return 1; end
    return v;
end

local function getFluidTint(color)
    local r = srgbToLinear(color:getR());
    local g = srgbToLinear(color:getG());
    local b = srgbToLinear(color:getB());
    r, g, b = r * 100, g * 100, b * 100;

    local x = r * 0.412453 + g * 0.35758 + b * 0.180423;
    local y = r * 0.212671 + g * 0.71516 + b * 0.072169;
    local z = r * 0.019334 + g * 0.119193 + b * 0.950227;
    x, y, z = x / 95.047, y / 100.0, z / 108.883;

    local f = function(t)
        if t > 0.008856 then
            return t ^ 0.3333333333333333;
        end
        return t * 7.787 + 0.13793103;
    end
    x, y, z = f(x), f(y), f(z);

    local labL = 116.0 * y - 16.0;
    local labA = 500.0 * (x - y);
    local labB = 200.0 * (y - z);

    if labL >= FLUID_MIN_LIGHTNESS then
        return color:getR(), color:getG(), color:getB();
    end

    local chroma = math.sqrt(labA * labA + labB * labB);
    ---@diagnostic disable-next-line: deprecated
    local hue = math.atan2(labB, labA);

    labL = FLUID_MIN_LIGHTNESS;
    labA = chroma * math.cos(hue);
    labB = chroma * math.sin(hue);

    y = (labL + 16.0) / 116.0;
    x = labA / 500.0 + y;
    z = y - labB / 200.0;
    local xyz = { x, y, z };
    for i = 1, 3 do
        if xyz[i] > 0.20689656 then
            xyz[i] = xyz[i] * xyz[i] * xyz[i];
        else
            xyz[i] = 0.12841856 * (xyz[i] - 0.13793103);
        end
    end
    xyz[1] = xyz[1] * 95.047;
    xyz[2] = xyz[2] * 100.0;
    xyz[3] = xyz[3] * 108.883;

    local lr = (xyz[1] * 3.240479 + xyz[2] * -1.53715 + xyz[3] * -0.498535) / 100.0;
    local lg = (xyz[1] * -0.969256 + xyz[2] * 1.875992 + xyz[3] * 0.041556) / 100.0;
    local lb = (xyz[1] * 0.055648 + xyz[2] * -0.204043 + xyz[3] * 1.057311) / 100.0;

    return clamp01(linearToSrgb(lr)), clamp01(linearToSrgb(lg)), clamp01(linearToSrgb(lb));
end

local function getItemConditionPercent(item, includeOffState)
    if instanceof(item, "HandWeapon") then
        local maxCond = item:getConditionMax();
        if maxCond and maxCond > 0 then
            local handleRatio = item:getCondition() / maxCond;
            local ratio = handleRatio;
            if item.hasHeadCondition and item:hasHeadCondition() then
                local headMax = item:getHeadConditionMax();
                if headMax and headMax > 0 then
                    local headRatio = item:getHeadCondition() / headMax;
                    ratio = math.min(handleRatio, headRatio);
                end
            end
            ratio = math.max(0, math.min(1, ratio));
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

local function getMainWidth(slotCount)
    return slotCount * HotbarReskin.CURRENT_HOTBAR_SIZE + (slotCount - 1) * getHotbarPad();
end

function HotbarReskin.calcTotalWidth(slotCount)
    local mainW = getMainWidth(slotCount);
    if SurvivalHUD.ShowHandSlots then
        return HotbarReskin.CURRENT_HOTBAR_SIZE + getSepSize() + mainW + getSepSize() + HotbarReskin.CURRENT_HOTBAR_SIZE;
    else
        return mainW;
    end
end

function HotbarReskin.getHeight()
    return HotbarReskin.CURRENT_HOTBAR_SIZE + HOTBAR_MARGIN * 2;
end

local function drawConditionOverlay(self, x, y, item, texValCache, cacheKey, kind, includeOffState)
    local val, tintR, tintG, tintB, overlayAlpha = getItemConditionPercent(item, includeOffState);
    if not val then return; end
    val = math.max(0, math.min(100, val));
    local isFluid = item:hasComponent(ComponentType.FluidContainer);
    local conTex, newTexVal = getConditionTexture(val, texValCache[cacheKey], kind, isFluid);
    if newTexVal then texValCache[cacheKey] = newTexVal; end
    if conTex then
        self:drawTexture(conTex, x, y, overlayAlpha, tintR, tintG, tintB);
    end
end

local function drawSlotLabel(self, x, size, text)
    local fontHgt = getTextManager():getFontHeight(UIFont.Small);
    local textWid = getTextManager():MeasureStringX(UIFont.Small, text);
    local labelX = x + math.floor((size - textWid) / 2);
    self:drawRect(labelX - 2, -fontHgt, textWid + 4, fontHgt, 0.6, 0, 0, 0);
    self:drawText(text, labelX, -fontHgt, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, UIFont.Small);
end

local function drawHandSlot(self, x, item, isSelected, isHovered, isPrimary)
    local size = HotbarReskin.CURRENT_HOTBAR_SIZE;
    local bg = getHandTexture("Hand_Background");
    local inHotbar = item and self:isInHotbar(item);
    local showSelected = isSelected and not inHotbar;
    local alpha = showSelected and 1.0 or 0.75;

    if bg then
        self:drawTexture(bg, x, HOTBAR_MARGIN, alpha, 1, 1, 1);
    end

    if showSelected and item then
        drawConditionOverlay(self, x, HOTBAR_MARGIN, item, self.handTexVal, isPrimary and "primary" or "secondary", "Hand", true);
    end

    if showSelected then
        local selTex = getHandTexture("Hand_Selected");
        if selTex then
            self:drawTexture(selTex, x, HOTBAR_MARGIN, 1, 1, 1, 1);
        end
    end

    if isHovered then
        local hoverTex = getHandTexture("Hand_Hover");
        if hoverTex then
            self:drawTexture(hoverTex, x, HOTBAR_MARGIN, 0.25, 1, 1, 1);
        end
        drawSlotLabel(self, x, size, isPrimary and getText("IGUI_PrimaryTooltip") or getText("IGUI_SecondaryTooltip"));
    end

    if item then
        local tex = item:getTexture();
        local w, h = getItemDrawSize(tex, size / 64);
        local ix = x + math.floor((size - w) / 2);
        local iy = HOTBAR_MARGIN + math.floor((size - h) / 2);
        self:drawTextureScaled(tex, ix + 1, iy + 1, w, h, 0.25, 0, 0, 0);
        self:drawTextureScaled(tex, ix, iy, w, h, 1, 1, 1, 1);
    end
end

local function drawSeparator(self, x)
    local sepCfg = Utils.SeparatorConfig[HotbarReskin.CURRENT_HOTBAR_SIZE];
    local sepSize = getSepSize();
    local hotbarSize = HotbarReskin.CURRENT_HOTBAR_SIZE;
    local lineInset = math.floor(4 * hotbarSize / 64 + 0.5);
    if sepCfg then
        local renderSize = sepCfg.renderSize;
        local texSize = sepCfg.texSize;
        local sep = getTexture("media/ui/Separator/" .. texSize .. "/Separator.png");
        if sep then
            local sx = x + math.floor((sepSize - renderSize) / 2);
            local sy = HOTBAR_MARGIN + math.floor((hotbarSize - renderSize) / 2);
            self:drawTextureScaled(sep, sx, sy, renderSize, renderSize, 0.5, 1, 1, 1);
            return;
        end
    end
    self:drawRect(x + math.floor(sepSize / 2), HOTBAR_MARGIN + lineInset, 1, hotbarSize - lineInset * 2, 0.4, 1, 1, 1);
end

local function isMouseBlocked(self)
    local mx = getMouseX();
    local my = getMouseY();
    local ax = self:getAbsoluteX();
    local ay = self:getAbsoluteY();
    if mx < ax or mx >= ax + self.width or my < ay or my >= ay + self.height then
        return true;
    end
    local uis = UIManager.getUI();
    if not uis or not self.javaObject then return false; end
    for i = uis:size() - 1, 0, -1 do
        local other = uis:get(i);
        if other == self.javaObject then break end
        if other:isVisible() and other:isPointOver(mx, my) then
            return true;
        end
    end
    return false;
end

HotbarDragPreview = ISPanel:derive("HotbarDragPreview");

function HotbarDragPreview:prerender()
end

function HotbarDragPreview:render()
    if ISHotbar.hotbarDraggingItem then
        local tex = ISHotbar.hotbarDraggingItem:getTexture();
        if tex then
            local w, h = getItemDrawSize(tex, HotbarReskin.CURRENT_HOTBAR_SIZE / 64);
            local mx = getMouseX() - math.floor(w / 2);
            local my = getMouseY() - math.floor(h / 2);
            self:drawTextureScaled(tex, mx, my, w, h, 0.5, 1, 1, 1);
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
    if not dragPreviewUI and ISHotbar.hotbarDraggingItem then
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
    local mouseOverSlotIndex = self:getSlotIndexAt(self:getMouseX(), self:getMouseY());
    local hoveredHand = self:getHandSlotIndexAt(self:getMouseX(), self:getMouseY());

    local draggedItem = nil;
    if ISHotbar.hotbarDraggingItem and ISHotbar.hotbarDraggingFrom == self.playerNum then
        draggedItem = ISHotbar.hotbarDraggingItem;
    elseif ISMouseDrag.dragging then
        local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging);
        if dragging and #dragging > 0 then
            draggedItem = dragging[1];
        end
    end

    local size = HotbarReskin.CURRENT_HOTBAR_SIZE;
    local bg = getSlotTexture("Slot_Background");
    local slotX = 0;

    if SurvivalHUD.ShowHandSlots then
        drawHandSlot(self, 0, secondaryItem, secondaryItem ~= nil, hoveredHand == -2, false);
        drawSeparator(self, HotbarReskin.CURRENT_HOTBAR_SIZE);
        slotX = HotbarReskin.CURRENT_HOTBAR_SIZE + getSepSize();
    end

    for i, slot in pairs(self.availableSlot) do
        local slotItem = self.attachedItems[i];
        local isSelected = slotItem and slotItem:isEquipped();
        local bgAlpha = isSelected and 1.0 or 0.75;

        if bg then
            self:drawTexture(bg, slotX, HOTBAR_MARGIN, bgAlpha, 1, 1, 1);
        end

        if isSelected then
            drawConditionOverlay(self, slotX, HOTBAR_MARGIN, slotItem, self.slotTexVal, i, "Slot", true);
            local selTex = getSlotTexture("Slot_Selected");
            if selTex then
                self:drawTexture(selTex, slotX, HOTBAR_MARGIN, 1, 1, 1, 1);
            end
        elseif slotItem and slotItem:canBeActivated() then
            drawConditionOverlay(self, slotX, HOTBAR_MARGIN, slotItem, self.slotTexVal, i, "Slot", false);
            if slotItem:isActivated() then
                local selTex = getSlotTexture("Slot_Selected");
                if selTex then
                    self:drawTexture(selTex, slotX, HOTBAR_MARGIN, 1, 1, 1, 1);
                end
            end
        end

        local indexInsetX = math.floor(8 * size / 64 + 0.5);
        local indexInsetY = math.floor(5 * size / 64 + 0.5);
        local indexFont = size >= 80 and UIFont.Medium or UIFont.Small;
        self:drawText(tostring(i), slotX + indexInsetX + 1, HOTBAR_MARGIN + indexInsetY + 1, 0, 0, 0, 0.75, indexFont);
        self:drawText(tostring(i), slotX + indexInsetX, HOTBAR_MARGIN + indexInsetY, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, indexFont);

        local item = self.attachedItems[i];

        if i == mouseOverSlotIndex then
            local r, g, b = 1, 1, 1;
            if draggedItem then
                if not self:canBeAttached(slot, draggedItem) then
                    r, g, b = 1, 0, 0;
                end
            end
            local highlightInset = math.floor(3 * size / 64 + 0.5);
            self:drawRect(slotX + highlightInset, HOTBAR_MARGIN + highlightInset, size - highlightInset * 2, size - highlightInset * 2, 0.25, r, g, b);

            drawSlotLabel(self, slotX, size, getTextOrNull("IGUI_HotbarAttachment_" .. slot.slotType) or slot.name);
        end

        if item then
            local tex = item:getTexture();
            local w, h = getItemDrawSize(tex, size / 64);
            local ix = slotX + math.floor((size - w) / 2);
            local iy = HOTBAR_MARGIN + math.floor((size - h) / 2);
            self:drawTextureScaled(tex, ix + 1, iy + 1, w, h, 0.25, 0, 0, 0);
            self:drawTextureScaled(tex, ix, iy, w, h, 1, 1, 1, 1);
        elseif slot.texture then
            local st = slot.texture;
            local w, h = getItemDrawSize(st, size / 64);
            local ix = slotX + math.floor((size - w) / 2);
            local iy = HOTBAR_MARGIN + math.floor((size - h) / 2);
            self:drawTextureScaled(st, ix, iy, w, h, 0.25, 1, 1, 1);
        end

        slotX = slotX + size + getHotbarPad();
    end

    if SurvivalHUD.ShowHandSlots then
        local rightSepX = slotX - getHotbarPad();
        drawSeparator(self, rightSepX);

        local rightHandX = rightSepX + getSepSize();
        drawHandSlot(self, rightHandX, primaryItem, primaryItem ~= nil, hoveredHand == -3, true);
    end
end

function ISHotbar:setSizeAndPosition()
    Utils.layoutHotbar(self);
end

local original_new = ISHotbar.new;
function ISHotbar:new(character)
    local o = original_new(self, character);

    o.slotWidth = HotbarReskin.CURRENT_HOTBAR_SIZE;
    o.slotHeight = HotbarReskin.CURRENT_HOTBAR_SIZE;
    o.slotPad = getHotbarPad();
    o.margins = HOTBAR_MARGIN;

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
    o.slotTexVal = {};
    o.handTexVal = {};

    local count = math.max(#o.availableSlot, 1);
    o.width = HotbarReskin.calcTotalWidth(count);
    o.height = HotbarReskin.getHeight();

    return o;
end

Functions.PostHook.Add(ISHotbar, "refresh", function(self)
    self.slotWidth = HotbarReskin.CURRENT_HOTBAR_SIZE;
    self.slotHeight = HotbarReskin.CURRENT_HOTBAR_SIZE;
    self.slotPad = getHotbarPad();
    self.margins = HOTBAR_MARGIN;

    local count = math.max(#self.availableSlot, 1);
    self:setWidth(HotbarReskin.calcTotalWidth(count));
    self:setHeight(HotbarReskin.getHeight());
end)

function ISHotbar:getSlotIndexAt(x, y)
    if y < 0 or y >= self.height then return -1 end
    local mainStartX = 0;
    if SurvivalHUD.ShowHandSlots then
        mainStartX = HotbarReskin.CURRENT_HOTBAR_SIZE + getSepSize();
    end
    local slotCount = #self.availableSlot;
    local mainEndX = mainStartX + getMainWidth(slotCount);
    if x >= mainStartX and x < mainEndX then
        local index = math.floor((x - mainStartX) / (HotbarReskin.CURRENT_HOTBAR_SIZE + getHotbarPad())) + 1;
        index = math.max(index, 1);
        return math.min(index, slotCount);
    end
    return -1;
end

function ISHotbar:getHandSlotIndexAt(x, y)
    if y < 0 or y >= self.height then return -1 end
    if not SurvivalHUD.ShowHandSlots then return -1 end
    local slotCount = #self.availableSlot;
    local mainEndX = HotbarReskin.CURRENT_HOTBAR_SIZE + getSepSize() + getMainWidth(slotCount);
    if x >= 0 and x < HotbarReskin.CURRENT_HOTBAR_SIZE then
        return -2;
    end
    local rightHandX = mainEndX + getSepSize();
    if x >= rightHandX and x < rightHandX + HotbarReskin.CURRENT_HOTBAR_SIZE then
        return -3;
    end
    return -1;
end

function ISHotbar:update()
    local moodleUI = UIManager.getMoodleUI(self.playerNum)
    if not self:isVisible() and moodleUI and moodleUI:isVisible() and not JoypadState.players[self.playerNum+1] then
        self:setVisible(true)
    end

    if self.character:getVehicle() and self.character:getVehicle():isDriver(self.character) then
        self:setVisible(false);
    end

    if self.needsRefresh then
        self:refresh()
    end

    self:setSizeAndPosition()

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
    if queue and #queue.queue > 0 then
        return;
    end

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

    if isMouseBlocked(self) then
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
    local slotItem = slotIndex ~= -1 and self.attachedItems[slotIndex] or nil;

    local tooltipItem = nil;
    if handItem and not contextVisible then
        tooltipItem = handItem;
    elseif slotItem and not contextVisible then
        tooltipItem = slotItem;
    end

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
        end
        self.toolRender:setVisible(true);
    elseif self.toolRender then
        self.toolRender:setVisible(false);
    end
end

function ISHotbar:onRightMouseUp(x, y)
    local handSlot = self:getHandSlotIndexAt(x, y);
    if handSlot == -2 then
        local item = self.character:getSecondaryHandItem();
        if item then
            ISInventoryPaneContextMenu.createMenu(self.character:getPlayerNum(), true, { item }, getMouseX(), getMouseY());
        end
        return;
    elseif handSlot == -3 then
        local item = self.character:getPrimaryHandItem();
        if item then
            ISInventoryPaneContextMenu.createMenu(self.character:getPlayerNum(), true, { item }, getMouseX(), getMouseY());
        end
        return;
    end

    local slotIndex = self:getSlotIndexAt(x, y);
    if slotIndex >= 1 then
        local item = self.attachedItems[slotIndex];
        if item then
            ISInventoryPaneContextMenu.createMenu(self.character:getPlayerNum(), true, { item }, getMouseX(), getMouseY());
        end
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
            if fromSlot >= 1 then
                local item = self.attachedItems[fromSlot];
                local slot = self.availableSlot[toSlot];
                if item and slot and self:canBeAttached(slot, item) then
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
                        if wasEquipped then
                            self.chr:removeAttachedItem(item);
                            item:setAttachedSlot(toSlot);
                            item:setAttachedSlotType(slot.def.type);
                            item:setAttachedToModel(slot.def.attachments[item:getAttachmentType()]);
                            self:reloadIcons();
                        else
                            self:removeItem(item, false);
                            self:attachItem(item, slot.def.attachments[item:getAttachmentType()], toSlot, slot.def, true);
                        end
                    end
                end
            elseif fromSlot == -2 or fromSlot == -3 then
                local existingItem = self.attachedItems[toSlot];
                if existingItem ~= dragItem then
                    local slot = self.availableSlot[toSlot];
                    if slot and dragItem and self:canBeAttached(slot, dragItem) then
                        self:attachItem(dragItem, slot.def.attachments[dragItem:getAttachmentType()], toSlot, slot.def, true);
                    end
                end
            end
            return;
        end

        if targetHandSlot == -2 or targetHandSlot == -3 then
            if fromSlot >= 1 then
                local item = self.attachedItems[fromSlot];
                if item then
                    local targetItem = targetHandSlot == -2 and self.character:getSecondaryHandItem() or self.character:getPrimaryHandItem();
                    local targetInHotbar = targetItem and self:isInHotbar(targetItem);
                    if targetItem and targetItem ~= item and not targetInHotbar then
                        local fromSlotDef = self.availableSlot[fromSlot];
                        if fromSlotDef and self:canBeAttached(fromSlotDef, targetItem) then
                            self:attachItem(targetItem, fromSlotDef.def.attachments[targetItem:getAttachmentType()], fromSlot, fromSlotDef.def, false);
                        end
                    end
                    ISInventoryPaneContextMenu.transferIfNeeded(self.chr, item);
                    if targetHandSlot == -3 then
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, true, item:isTwoHandWeapon()));
                    else
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, false, false));
                    end
                end
            elseif (fromSlot == -2 or fromSlot == -3) and fromSlot ~= targetHandSlot then
                if dragItem then
                    local targetItem = targetHandSlot == -2 and self.character:getSecondaryHandItem() or self.character:getPrimaryHandItem();
                    if targetItem and targetItem ~= dragItem then
                        ISInventoryPaneContextMenu.transferIfNeeded(self.chr, targetItem);
                    end
                    ISInventoryPaneContextMenu.transferIfNeeded(self.chr, dragItem);
                    if targetHandSlot == -3 then
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, dragItem, 20, true, dragItem:isTwoHandWeapon()));
                        if targetItem and targetItem ~= dragItem then
                            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, targetItem, 20, false, false));
                        end
                    else
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, dragItem, 20, false, false));
                        if targetItem and targetItem ~= dragItem then
                            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, targetItem, 20, true, targetItem:isTwoHandWeapon()));
                        end
                    end
                end
            end
            return;
        end
        return;
    end

    if ISMouseDrag.dragging then
        local handSlot = self:getHandSlotIndexAt(x, y);
        if handSlot == -2 or handSlot == -3 then
            local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging);
            if dragging and #dragging > 0 then
                local item = dragging[1];
                if item then
                    ISInventoryPaneContextMenu.transferIfNeeded(self.chr, item);
                    if handSlot == -3 then
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, true, item:isTwoHandWeapon()));
                    else
                        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, false, false));
                    end
                end
            end
            return;
        end
        local slotIndex = self:getSlotIndexAt(x, y);
        if slotIndex >= 1 then
            local slot = self.availableSlot[slotIndex];
            local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging);
            if dragging and #dragging > 0 and slot then
                local item = dragging[1];
                if item and self:canBeAttached(slot, item) then
                    self:attachItem(item, slot.def.attachments[item:getAttachmentType()], slotIndex, slot.def, true);
                end
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
        local item = handSlot == -2 and self.character:getSecondaryHandItem() or self.character:getPrimaryHandItem();
        if item then
            self:equipItem(item);
        end
        return;
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
    if ISMouseDrag.dragging or ISHotbar.hotbarDraggingItem then return; end

    local handSlot = self:getHandSlotIndexAt(x, y);
    if handSlot == -2 or handSlot == -3 then
        local item = handSlot == -2 and self.character:getSecondaryHandItem() or self.character:getPrimaryHandItem();
        if item then
            ISHotbar.dragCandidateSlot = handSlot;
            ISHotbar.dragStartX = getMouseX();
            ISHotbar.dragStartY = getMouseY();
            ISHotbar.dragCandidatePlayer = self.playerNum;
        end
        return;
    end

    local slotIndex = self:getSlotIndexAt(x, y);
    if slotIndex < 1 then return end
    local item = self.attachedItems[slotIndex];
    if not item then return end

    ISHotbar.dragCandidateSlot = slotIndex;
    ISHotbar.dragStartX = getMouseX();
    ISHotbar.dragStartY = getMouseY();
    ISHotbar.dragCandidatePlayer = self.playerNum;
end

local function onPlayerDeath()
    ISMouseDrag.dragging = nil;
    ISMouseDrag.draggingFocus = nil;
    ISMouseDrag.dragView = nil;
end

local function onGameBoot()
    for _, size in ipairs({ 48, 64, 80 }) do
        for _, kind in ipairs({ "Slot", "Hand" }) do
            for _, textureName in ipairs({ kind .. "_Background", kind .. "_Selected" }) do
                getTexture("media/ui/Hotbar/" .. size .. "/" .. kind .. "/" .. textureName .. ".png");
            end
            if kind == "Hand" then
                getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_Hover.png");
            end

            for _, phaseData in ipairs(CONDITION_PHASES) do
                local phaseLevel = phaseData[3];
                for _, threshold in ipairs(phaseData[4]) do
                    getTexture("media/ui/Hotbar/" .. size .. "/" .. kind .. "/" .. kind .. "_" .. phaseLevel .. "_" .. threshold .. ".png");
                end
            end

            for _, phaseData in ipairs(CONDITION_PHASES) do
                local phaseLevel = phaseData[3];
                for _, threshold in ipairs(phaseData[4]) do
                    local path = "media/ui/Hotbar/" .. size .. "/" .. kind .. "/Fluids/" .. kind .. "_" .. phaseLevel .. "_" .. threshold .. ".png";
                    if fileExists(path) then
                        getTexture(path);
                    end
                end
            end
        end
    end
end

Events.OnPlayerDeath.Add(onPlayerDeath);
Events.OnGameBoot.Add(onGameBoot);