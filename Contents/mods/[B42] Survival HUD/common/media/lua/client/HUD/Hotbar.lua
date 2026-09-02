require "ISUI/ISHotbar";

local Utils = require("HUD/Utils");

if getActivatedMods():contains("CleanHotBar") then
    return;
end

HotbarReskin = {};

HotbarReskin.HOTBAR_SIZE = 64;
HotbarReskin.CURRENT_HOTBAR_SIZE = 64;

local HOTBAR_PAD = 8;
local HOTBAR_MARGIN = 0;

local SEP_SIZE = 40;
local DRAG_THRESHOLD = 5;

local function getSlotTexture(textureName)
    local size = HotbarReskin.CURRENT_HOTBAR_SIZE;
    return getTexture("media/ui/Hotbar/" .. size .. "/Slot/" .. textureName .. ".png");
end

local function getHandTexture(textureName)
    local size = HotbarReskin.CURRENT_HOTBAR_SIZE;
    return getTexture("media/ui/Hotbar/" .. size .. "/Hand/" .. textureName .. ".png");
end

local function getFitSize(tex, maxSide)
    local w = tex:getWidth();
    local h = tex:getHeight();
    if w <= maxSide and h <= maxSide then
        return w, h;
    end
    local ratio = maxSide / math.max(w, h);
    return math.floor(w * ratio + 0.5), math.floor(h * ratio + 0.5);
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

local function getConditionTexture(conditionPercent, currentTexVal, kind)
    local size = HotbarReskin.CURRENT_HOTBAR_SIZE;
    local texVal, phase = getBestConditionTexture(conditionPercent, currentTexVal ~= nil and currentTexVal or -1);
    if not texVal or not phase then return nil, nil; end
    local phaseLevel = phase[3];
    return getTexture("media/ui/Hotbar/" .. size .. "/" .. kind .. "/" .. kind .. "_" .. phaseLevel .. "_" .. texVal .. ".png"), texVal;
end

local function getItemConditionPercent(item)
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
            return math.floor(ratio * 100 + 0.5);
        end
    elseif instanceof(item, "DrainableComboItem") and item:canBeActivated() and item:isActivated() then
        return math.floor(item:getCurrentUsesFloat() * 100 + 0.5);
    elseif instanceof(item, "Radio") then
        local deviceData = item:getDeviceData();
        if deviceData and deviceData:getIsTurnedOn() and deviceData:getIsBatteryPowered() and deviceData:getHasBattery() then
            return math.floor(deviceData:getPower() * 100 + 0.5);
        end
    end
    return nil;
end

local dragPreviewUI = nil;

local function getMainWidth(slotCount)
    return slotCount * HotbarReskin.CURRENT_HOTBAR_SIZE + (slotCount - 1) * HOTBAR_PAD;
end

function HotbarReskin.calcTotalWidth(slotCount)
    local mainW = getMainWidth(slotCount);
    if SurvivalHUD.ShowHandSlots then
        return HotbarReskin.CURRENT_HOTBAR_SIZE + SEP_SIZE + mainW + SEP_SIZE + HotbarReskin.CURRENT_HOTBAR_SIZE;
    else
        return mainW;
    end
end

function HotbarReskin.getHeight()
    return HotbarReskin.CURRENT_HOTBAR_SIZE + HOTBAR_MARGIN * 2;
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
        local val = getItemConditionPercent(item);
        if val then
            val = math.max(0, math.min(100, val));
            local key = isPrimary and "primary" or "secondary";
            local conTex, newTexVal = getConditionTexture(val, self.handTexVal[key], "Hand");
            if newTexVal then self.handTexVal[key] = newTexVal; end
            if conTex then
                self:drawTexture(conTex, x, HOTBAR_MARGIN, 1, 1, 1, 1);
            end
        end
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
        local fontHgt = getTextManager():getFontHeight(UIFont.Small);
        local slotName = isPrimary and getText("IGUI_PrimaryTooltip") or getText("IGUI_SecondaryTooltip");
        local textWid = getTextManager():MeasureStringX(UIFont.Small, slotName);
        local labelX = x + math.floor((size - textWid) / 2);
        self:drawRect(labelX - 2, -fontHgt, textWid + 4, fontHgt, 0.6, 0, 0, 0);
        self:drawText(slotName, labelX, -fontHgt, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, UIFont.Small);
    end

    if item then
        local tex = item:getTexture();
        local w, h = getFitSize(tex, size - 8);
        local ix = x + math.floor((size - w) / 2);
        local iy = HOTBAR_MARGIN + math.floor((size - h) / 2);
        self:drawTextureScaled(tex, ix + 1, iy + 1, w, h, 0.25, 0, 0, 0);
        self:drawTextureScaled(tex, ix, iy, w, h, 1, 1, 1, 1);
    end
end

local function drawSeparator(self, x)
    local sepCfg = Utils.SeparatorConfig[HotbarReskin.CURRENT_HOTBAR_SIZE];
    local sepSize = SEP_SIZE;
    local hotbarSize = HotbarReskin.CURRENT_HOTBAR_SIZE;
    if sepCfg then
        local renderSize = sepCfg.renderSize;
        local texSize = sepCfg.texSize;
        local sep = getTexture("media/ui/Separator/" .. texSize .. "/Separator.png");
        if sep then
            local sx = x + math.floor((sepSize - renderSize) / 2);
            local sy = HOTBAR_MARGIN + math.floor((hotbarSize - renderSize) / 2);
            self:drawTextureScaled(sep, sx, sy, renderSize, renderSize, 0.5, 1, 1, 1);
        else
            self:drawRect(x + math.floor(sepSize / 2), HOTBAR_MARGIN + 4, 1, hotbarSize - 8, 0.4, 1, 1, 1);
        end
    else
        self:drawRect(x + math.floor(sepSize / 2), HOTBAR_MARGIN + 4, 1, hotbarSize - 8, 0.4, 1, 1, 1);
    end
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

local function ensureDragPreviewUI()
    if not dragPreviewUI and ISHotbar.hotbarDraggingItem then
        dragPreviewUI = ISPanel:new(0, 0, 1, 1);
        dragPreviewUI:noBackground();
        dragPreviewUI.suspend = true;
        dragPreviewUI.prerender = function() end
        dragPreviewUI.render = function(self)
            if ISHotbar.hotbarDraggingItem then
                local tex = ISHotbar.hotbarDraggingItem:getTexture();
                if tex then
                    local w, h = getFitSize(tex, HotbarReskin.CURRENT_HOTBAR_SIZE);
                    local mx = getMouseX() - math.floor(w / 2);
                    local my = getMouseY() - math.floor(h / 2);
                    self:drawTextureScaled(tex, mx, my, w, h, 0.5, 1, 1, 1);
                end
            end
        end
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
        slotX = HotbarReskin.CURRENT_HOTBAR_SIZE + SEP_SIZE;
    end

    for i, slot in pairs(self.availableSlot) do
        local slotItem = self.attachedItems[i];
        local isSelected = slotItem and slotItem:isEquipped();
        local bgAlpha = isSelected and 1.0 or 0.75;

        if bg then
            self:drawTexture(bg, slotX, HOTBAR_MARGIN, bgAlpha, 1, 1, 1);
        end

        if isSelected then
            local val = getItemConditionPercent(slotItem);
            if val then
                val = math.max(0, math.min(100, val));
                local conTex, newTexVal = getConditionTexture(val, self.slotTexVal[i], "Slot");
                if newTexVal then self.slotTexVal[i] = newTexVal; end
                if conTex then
                    self:drawTexture(conTex, slotX, HOTBAR_MARGIN, 1, 1, 1, 1);
                end
            end
            local selTex = getSlotTexture("Slot_Selected");
            if selTex then
                self:drawTexture(selTex, slotX, HOTBAR_MARGIN, 1, 1, 1, 1);
            end
        end

        self:drawText(tostring(i), slotX + 8, HOTBAR_MARGIN + 5, 0, 0, 0, 0.75, self.font);
        self:drawText(tostring(i), slotX + 7, HOTBAR_MARGIN + 4, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, self.font);

        local item = self.attachedItems[i];

        if i == mouseOverSlotIndex then
            local r, g, b = 1, 1, 1;
            if draggedItem then
                if not self:canBeAttached(slot, draggedItem) then
                    r, g, b = 1, 0, 0;
                end
            end
            self:drawRect(slotX + 3, HOTBAR_MARGIN + 3, size - 6, size - 6, 0.25, r, g, b);

            local fontHgt = getTextManager():getFontHeight(UIFont.Small);
            local slotName = getTextOrNull("IGUI_HotbarAttachment_" .. slot.slotType) or slot.name;
            local textWid = getTextManager():MeasureStringX(UIFont.Small, slotName);
            local labelX = slotX + math.floor((size - textWid) / 2);
            self:drawRect(labelX - 2, -fontHgt, textWid + 4, fontHgt, 0.6, 0, 0, 0);
            self:drawText(slotName, labelX, -fontHgt, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, self.font);
        end

        if item then
            local tex = item:getTexture();
            local w, h = getFitSize(tex, size - 8);
            local ix = slotX + math.floor((size - w) / 2);
            local iy = HOTBAR_MARGIN + math.floor((size - h) / 2);
            self:drawTextureScaled(tex, ix + 1, iy + 1, w, h, 0.25, 0, 0, 0);
            self:drawTextureScaled(tex, ix, iy, w, h, 1, 1, 1, 1);
        elseif slot.texture then
            local st = slot.texture;
            local ix = slotX + math.floor((size - st:getWidth()) / 2);
            local iy = HOTBAR_MARGIN + math.floor((size - st:getHeight()) / 2);
            self:drawTexture(st, ix, iy, 0.25, 1, 1, 1);
        end

        slotX = slotX + size + HOTBAR_PAD;
    end

    if SurvivalHUD.ShowHandSlots then
        local rightSepX = slotX - HOTBAR_PAD;
        drawSeparator(self, rightSepX);

        local rightHandX = rightSepX + SEP_SIZE;
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
    o.slotPad = HOTBAR_PAD;
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
    self.slotPad = HOTBAR_PAD;
    self.margins = HOTBAR_MARGIN;

    local count = math.max(#self.availableSlot, 1);
    self:setWidth(HotbarReskin.calcTotalWidth(count));
    self:setHeight(HotbarReskin.getHeight());
end)

function ISHotbar:getSlotIndexAt(x, y)
    if y < 0 or y >= self.height then return -1 end
    local mainStartX = 0;
    if SurvivalHUD.ShowHandSlots then
        mainStartX = HotbarReskin.CURRENT_HOTBAR_SIZE + SEP_SIZE;
    end
    local slotCount = #self.availableSlot;
    local mainEndX = mainStartX + getMainWidth(slotCount);
    if x >= mainStartX and x < mainEndX then
        local index = math.floor((x - mainStartX) / (HotbarReskin.CURRENT_HOTBAR_SIZE + HOTBAR_PAD)) + 1;
        index = math.max(index, 1);
        return math.min(index, slotCount);
    end
    return -1;
end

function ISHotbar:getHandSlotIndexAt(x, y)
    if y < 0 or y >= self.height then return -1 end
    if not SurvivalHUD.ShowHandSlots then return -1 end
    local slotCount = #self.availableSlot;
    local mainEndX = HotbarReskin.CURRENT_HOTBAR_SIZE + SEP_SIZE + getMainWidth(slotCount);
    if x >= 0 and x < HotbarReskin.CURRENT_HOTBAR_SIZE then
        return -2;
    end
    local rightHandX = mainEndX + SEP_SIZE;
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
            ISHotbar.dragCandidateSlot = nil;
            ISHotbar.dragStartX = nil;
            ISHotbar.dragStartY = nil;
            ISHotbar.dragCandidatePlayer = nil;
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
        ISHotbar.dragCandidateSlot = nil;
        ISHotbar.dragStartX = nil;
        ISHotbar.dragStartY = nil;
        ISHotbar.dragCandidatePlayer = nil;
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
        ISHotbar.dragCandidateSlot = nil;
        ISHotbar.dragStartX = nil;
        ISHotbar.dragStartY = nil;
        ISHotbar.dragCandidatePlayer = nil;
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
        getTexture("media/ui/Hotbar/" .. size .. "/Slot/Slot_Background.png");
        getTexture("media/ui/Hotbar/" .. size .. "/Slot/Slot_Selected.png");

        for _, phaseData in ipairs(CONDITION_PHASES) do
            local phaseLevel = phaseData[3];
            local thresholds = phaseData[4];
            for _, threshold in ipairs(thresholds) do
                getTexture("media/ui/Hotbar/" .. size .. "/Slot/Slot_" .. phaseLevel .. "_" .. threshold .. ".png");
            end
        end

        getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_Background.png");
        getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_Selected.png");
        getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_Hover.png");

        for _, phaseData in ipairs(CONDITION_PHASES) do
            local phaseLevel = phaseData[3];
            local thresholds = phaseData[4];
            for _, threshold in ipairs(thresholds) do
                getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_" .. phaseLevel .. "_" .. threshold .. ".png");
            end
        end
    end
end

Events.OnPlayerDeath.Add(onPlayerDeath);
Events.OnGameBoot.Add(onGameBoot);