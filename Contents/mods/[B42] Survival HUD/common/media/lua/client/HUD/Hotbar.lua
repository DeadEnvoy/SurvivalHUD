require "ISUI/ISHotbar";

if getActivatedMods():contains("CleanHotBar") then
    return;
end

HotbarReskin = {};

HotbarReskin.HOTBAR_SIZE = 64;
HotbarReskin.BASE_HOTBAR_SIZE = 64;
HotbarReskin.HOTBAR_PAD = 8;
HotbarReskin.HOTBAR_MARGIN = 0;
HotbarReskin.SEP_SIZE = 40;
HotbarReskin.DRAG_THRESHOLD = 5;
HotbarReskin.CollisionSizes = { 80, 64, 48 };

HotbarReskin.getNextSmallerSize = function(currentSize)
	local sizes = HotbarReskin.CollisionSizes;
	local found = false;
	for _, size in ipairs(sizes) do
		if found then return size; end
		if size == currentSize then found = true; end
	end
	return nil;
end

HotbarReskin.getSlotTexture = function(textureName)
	local size = HotbarReskin.HOTBAR_SIZE;
	return getTexture("media/ui/Hotbar/" .. size .. "/Slot/" .. textureName .. ".png");
end

HotbarReskin.getHandTexture = function(textureName)
	local size = HotbarReskin.HOTBAR_SIZE;
	return getTexture("media/ui/Hotbar/" .. size .. "/Hand/" .. textureName .. ".png");
end

HotbarReskin.ConditionPhases = {
	{ 75, 100, 0, { 100, 95, 90, 85, 80 } },
	{ 50, 75, 1, { 75, 70, 65, 60, 55 } },
	{ 25, 50, 2, { 50, 45, 40, 35, 30 } },
	{ 10, 25, 3, { 25, 30, 25, 20, 15 } },
	{ 0, 10, 4, { 10, 5 } },
};

HotbarReskin.getConditionPhase = function(conditionPercent)
	for _, phase in ipairs(HotbarReskin.ConditionPhases) do
		if conditionPercent >= phase[1] and conditionPercent <= phase[2] then
			return phase;
		end
	end
	return HotbarReskin.ConditionPhases[#HotbarReskin.ConditionPhases];
end

HotbarReskin.getBestConditionTexture = function(conditionPercent, currentTexVal)
	local phase = HotbarReskin.getConditionPhase(conditionPercent);
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

HotbarReskin.getConditionTexture = function(conditionPercent, currentTexVal)
	local size = HotbarReskin.HOTBAR_SIZE;
	local texVal, phase = HotbarReskin.getBestConditionTexture(conditionPercent, currentTexVal ~= nil and currentTexVal or -1);
	if not texVal or not phase then return nil, nil; end
	local phaseLevel = phase[3];
	return getTexture("media/ui/Hotbar/" .. size .. "/Slot/Slot_" .. phaseLevel .. "_" .. texVal .. ".png"), texVal;
end

HotbarReskin.getHandConditionTexture = function(conditionPercent, currentTexVal)
	local size = HotbarReskin.HOTBAR_SIZE;
	local texVal, phase = HotbarReskin.getBestConditionTexture(conditionPercent, currentTexVal ~= nil and currentTexVal or -1);
	if not texVal or not phase then return nil, nil; end
	local phaseLevel = phase[3];
	return getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_" .. phaseLevel .. "_" .. texVal .. ".png"), texVal;
end

HotbarReskin.dragPreviewUI = nil;

HotbarReskin.calcTotalWidth = function(slotCount)
	local mainW = slotCount * HotbarReskin.HOTBAR_SIZE + (slotCount - 1) * HotbarReskin.HOTBAR_PAD;
	if SurvivalHUD.ShowHandSlots then
		return HotbarReskin.HOTBAR_SIZE + HotbarReskin.SEP_SIZE + mainW + HotbarReskin.SEP_SIZE + HotbarReskin.HOTBAR_SIZE;
	else
		return mainW;
	end
end

HotbarReskin.drawHandSlot = function(self, x, item, isSelected, isHovered, isPrimary)
	local size = HotbarReskin.HOTBAR_SIZE;
	local bg = HotbarReskin.getHandTexture("Hand_Background");
	local inHotbar = item and self:isInHotbar(item);
	local showSelected = isSelected and not inHotbar;
	local alpha = showSelected and 1.0 or 0.75;

	if bg then
		self:drawTexture(bg, x, HotbarReskin.HOTBAR_MARGIN, alpha, 1, 1, 1);
	end

	if showSelected and item then
		local val = nil;
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
				val = math.floor(ratio * 100 + 0.5);
			end
		elseif instanceof(item, "DrainableComboItem") and item:canBeActivated() and item:isActivated() then
			val = math.floor(item:getCurrentUsesFloat() * 100 + 0.5);
		elseif instanceof(item, "Radio") then
			local deviceData = item:getDeviceData();
			if deviceData and deviceData:getIsTurnedOn() and deviceData:getIsBatteryPowered() and deviceData:getHasBattery() then
				val = math.floor(deviceData:getPower() * 100 + 0.5);
			end
		end
		if val then
			val = math.max(0, math.min(100, val));
			local key = isPrimary and "primary" or "secondary";
			local conTex, newTexVal = HotbarReskin.getHandConditionTexture(val, self.handTexVal[key]);
			if newTexVal then self.handTexVal[key] = newTexVal; end
			if conTex then
				self:drawTexture(conTex, x, HotbarReskin.HOTBAR_MARGIN, 1, 1, 1, 1);
			end
		end
	end

	if showSelected then
		local selTex = HotbarReskin.getHandTexture("Hand_Selected");
		if selTex then
			self:drawTexture(selTex, x, HotbarReskin.HOTBAR_MARGIN, 1, 1, 1, 1);
		end
	end

	if isHovered then
		local hoverTex = HotbarReskin.getHandTexture("Hand_Hover");
		if hoverTex then
			self:drawTexture(hoverTex, x, HotbarReskin.HOTBAR_MARGIN, 0.25, 1, 1, 1);
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
		local ix = x + math.floor((size - tex:getWidth()) / 2);
		local iy = HotbarReskin.HOTBAR_MARGIN + math.floor((size - tex:getHeight()) / 2);
		self:drawTexture(tex, ix + 1, iy + 1, 0.25, 0, 0, 0);
		self:drawTexture(tex, ix, iy, 1, 1, 1, 1);
	end
end

HotbarReskin.drawSeparator = function(self, x)
	local sepCfg = (SurvivalHUD and SurvivalHUD.SeparatorConfig) and SurvivalHUD.SeparatorConfig[HotbarReskin.HOTBAR_SIZE];
	local sepSize = HotbarReskin.SEP_SIZE;
	local hotbarSize = HotbarReskin.HOTBAR_SIZE;
	if sepCfg then
		local renderSize = sepCfg.renderSize;
		local texSize = sepCfg.texSize;
		local sep = getTexture("media/ui/Separator/" .. texSize .. "/Separator.png");
		if sep then
			local sx = x + math.floor((sepSize - renderSize) / 2);
			local sy = HotbarReskin.HOTBAR_MARGIN + math.floor((hotbarSize - renderSize) / 2);
			self:drawTextureScaled(sep, sx, sy, renderSize, renderSize, 0.5, 1, 1, 1);
		else
			self:drawRect(x + math.floor(sepSize / 2), HotbarReskin.HOTBAR_MARGIN + 4, 1, hotbarSize - 8, 0.4, 1, 1, 1);
		end
	else
		self:drawRect(x + math.floor(sepSize / 2), HotbarReskin.HOTBAR_MARGIN + 4, 1, hotbarSize - 8, 0.4, 1, 1, 1);
	end
end

HotbarReskin.isMouseBlocked = function(self)
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

HotbarReskin.ensureDragPreviewUI = function()
	if not HotbarReskin.dragPreviewUI and ISHotbar.hotbarDraggingItem then
		HotbarReskin.dragPreviewUI = ISPanel:new(0, 0, 1, 1);
		HotbarReskin.dragPreviewUI:noBackground();
		HotbarReskin.dragPreviewUI.suspend = true;
		HotbarReskin.dragPreviewUI.prerender = function() end
		HotbarReskin.dragPreviewUI.render = function(self)
			if ISHotbar.hotbarDraggingItem then
				local tex = ISHotbar.hotbarDraggingItem:getTexture();
				if tex then
					local mx = getMouseX() - math.floor(tex:getWidth() / 2);
					local my = getMouseY() - math.floor(tex:getHeight() / 2);
					self:drawTexture(tex, mx, my, 0.5, 1, 1, 1);
				end
			end
		end
		HotbarReskin.dragPreviewUI:initialise();
		HotbarReskin.dragPreviewUI:addToUIManager();
		HotbarReskin.dragPreviewUI:setAlwaysOnTop(true);
	end
end

HotbarReskin.removeDragPreviewUI = function()
	if HotbarReskin.dragPreviewUI then
		HotbarReskin.dragPreviewUI:removeFromUIManager();
		HotbarReskin.dragPreviewUI = nil;
	end
end

ISHotbar.prerender = function(self)
	self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
	self.borderColor = { r = 0, g = 0, b = 0, a = 0 };
end

ISHotbar.render = function(self)
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

	local size = HotbarReskin.HOTBAR_SIZE;
	local bg = HotbarReskin.getSlotTexture("Slot_Background");
	local slotX = 0;

	if SurvivalHUD.ShowHandSlots then
		HotbarReskin.drawHandSlot(self, 0, secondaryItem, secondaryItem ~= nil, hoveredHand == -2, false);
		HotbarReskin.drawSeparator(self, HotbarReskin.HOTBAR_SIZE);
		slotX = HotbarReskin.HOTBAR_SIZE + HotbarReskin.SEP_SIZE;
	end

	for i, slot in pairs(self.availableSlot) do
		local slotItem = self.attachedItems[i];
		local isSelected = slotItem and slotItem:isEquipped();
		local bgAlpha = isSelected and 1.0 or 0.75;

		if bg then
			self:drawTexture(bg, slotX, HotbarReskin.HOTBAR_MARGIN, bgAlpha, 1, 1, 1);
		end

		if isSelected then
			local val = nil;
			if instanceof(slotItem, "HandWeapon") then
				local maxCond = slotItem:getConditionMax();
				if maxCond and maxCond > 0 then
					local handleRatio = slotItem:getCondition() / maxCond;
					local ratio = handleRatio;
					if slotItem.hasHeadCondition and slotItem:hasHeadCondition() then
						local headMax = slotItem:getHeadConditionMax();
						if headMax and headMax > 0 then
							local headRatio = slotItem:getHeadCondition() / headMax;
							ratio = math.min(handleRatio, headRatio);
						end
					end
					ratio = math.max(0, math.min(1, ratio));
					val = math.floor(ratio * 100 + 0.5);
				end
			elseif instanceof(slotItem, "DrainableComboItem") and slotItem:canBeActivated() and slotItem:isActivated() then
				val = math.floor(slotItem:getCurrentUsesFloat() * 100 + 0.5);
			elseif instanceof(slotItem, "Radio") then
				local deviceData = slotItem:getDeviceData();
				if deviceData and deviceData:getIsTurnedOn() and deviceData:getIsBatteryPowered() and deviceData:getHasBattery() then
					local power = deviceData:getPower();
					val = math.floor(power * 100 + 0.5);
				end
			end
			if val then
				val = math.max(0, math.min(100, val));
				local conTex, newTexVal = HotbarReskin.getConditionTexture(val, self.slotTexVal[i]);
				if newTexVal then self.slotTexVal[i] = newTexVal; end
				if conTex then
					self:drawTexture(conTex, slotX, HotbarReskin.HOTBAR_MARGIN, 1, 1, 1, 1);
				end
			end
			local selTex = HotbarReskin.getSlotTexture("Slot_Selected");
			if selTex then
				self:drawTexture(selTex, slotX, HotbarReskin.HOTBAR_MARGIN, 1, 1, 1, 1);
			end
		end

		self:drawText(tostring(i), slotX + 8, HotbarReskin.HOTBAR_MARGIN + 5, 0, 0, 0, 0.75, self.font);
		self:drawText(tostring(i), slotX + 7, HotbarReskin.HOTBAR_MARGIN + 4, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, self.font);

		local item = self.attachedItems[i];

		if i == mouseOverSlotIndex then
			local r, g, b = 1, 1, 1;
			if draggedItem then
				if not self:canBeAttached(slot, draggedItem) then
					r, g, b = 1, 0, 0;
				end
			end
			self:drawRect(slotX + 3, HotbarReskin.HOTBAR_MARGIN + 3, size - 6, size - 6, 0.25, r, g, b, 1);

			local fontHgt = getTextManager():getFontHeight(UIFont.Small);
			local slotName = getTextOrNull("IGUI_HotbarAttachment_" .. slot.slotType) or slot.name;
			local textWid = getTextManager():MeasureStringX(UIFont.Small, slotName);
			local labelX = slotX + math.floor((size - textWid) / 2);
			self:drawRect(labelX - 2, -fontHgt, textWid + 4, fontHgt, 0.6, 0, 0, 0);
			self:drawText(slotName, labelX, -fontHgt, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, self.font);
		end

		if item then
			local tex = item:getTexture();
			local ix = slotX + math.floor((size - tex:getWidth()) / 2);
			local iy = HotbarReskin.HOTBAR_MARGIN + math.floor((size - tex:getHeight()) / 2);
			self:drawTexture(tex, ix + 1, iy + 1, 0.25, 0, 0, 0);
			self:drawTexture(tex, ix, iy, 1, 1, 1, 1);
		elseif slot.texture then
			local st = slot.texture;
			local ix = slotX + math.floor((size - st:getWidth()) / 2);
			local iy = HotbarReskin.HOTBAR_MARGIN + math.floor((size - st:getHeight()) / 2);
			self:drawTexture(st, ix, iy, 0.25, 1, 1, 1);
		end

		slotX = slotX + size + HotbarReskin.HOTBAR_PAD;
	end

	if SurvivalHUD.ShowHandSlots then
		local rightSepX = slotX - HotbarReskin.HOTBAR_PAD;
		HotbarReskin.drawSeparator(self, rightSepX);

		local rightHandX = rightSepX + HotbarReskin.SEP_SIZE;
		HotbarReskin.drawHandSlot(self, rightHandX, primaryItem, primaryItem ~= nil, hoveredHand == -3, true);
	end
end

ISHotbar.setSizeAndPosition = function(self)
	local count = math.max(#self.availableSlot, 1);
	local w = HotbarReskin.calcTotalWidth(count);
	local h = HotbarReskin.HOTBAR_SIZE + HotbarReskin.HOTBAR_MARGIN * 2;
	self:setWidth(w);
	self:setHeight(h);

	local screenX = getPlayerScreenLeft(self.playerNum);
	local screenY = getPlayerScreenTop(self.playerNum);
	local screenW = getPlayerScreenWidth(self.playerNum);
	local screenH = getPlayerScreenHeight(self.playerNum);

	self:setX(screenX + math.floor((screenW - w) / 2));
	self:setY(screenY + screenH - h - 15);
end

local original_new = ISHotbar.new;
ISHotbar.new = function(self, character)
	local o = original_new(self, character);

	o.slotWidth = HotbarReskin.HOTBAR_SIZE;
	o.slotHeight = HotbarReskin.HOTBAR_SIZE;
	o.slotPad = HotbarReskin.HOTBAR_PAD;
	o.margins = HotbarReskin.HOTBAR_MARGIN;

	o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };
	o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
	o.slotTexVal = {};
	o.handTexVal = {};

	local count = math.max(#o.availableSlot, 1);
	o.width = HotbarReskin.calcTotalWidth(count);
	o.height = HotbarReskin.HOTBAR_SIZE + HotbarReskin.HOTBAR_MARGIN * 2;

	return o;
end

local original_refresh = ISHotbar.refresh;
ISHotbar.refresh = function(self)
	original_refresh(self);

	self.slotWidth = HotbarReskin.HOTBAR_SIZE;
	self.slotHeight = HotbarReskin.HOTBAR_SIZE;
	self.slotPad = HotbarReskin.HOTBAR_PAD;
	self.margins = HotbarReskin.HOTBAR_MARGIN;

	local count = math.max(#self.availableSlot, 1);
	self:setWidth(HotbarReskin.calcTotalWidth(count));
	self:setHeight(HotbarReskin.HOTBAR_SIZE + HotbarReskin.HOTBAR_MARGIN * 2);
end

ISHotbar.getSlotIndexAt = function(self, x, y)
	if y < 0 or y >= self.height then return -1 end
	local mainStartX = 0;
	if SurvivalHUD.ShowHandSlots then
		mainStartX = HotbarReskin.HOTBAR_SIZE + HotbarReskin.SEP_SIZE;
	end
	local slotCount = #self.availableSlot;
	local mainEndX = mainStartX + slotCount * HotbarReskin.HOTBAR_SIZE + (slotCount - 1) * HotbarReskin.HOTBAR_PAD;
	if x >= mainStartX and x < mainEndX then
		local index = math.floor((x - mainStartX) / (HotbarReskin.HOTBAR_SIZE + HotbarReskin.HOTBAR_PAD)) + 1;
		index = math.max(index, 1);
		return math.min(index, slotCount);
	end
	return -1;
end

function ISHotbar:getHandSlotIndexAt(x, y)
	if y < 0 or y >= self.height then return -1 end
	if not SurvivalHUD.ShowHandSlots then return -1 end
	local slotCount = #self.availableSlot;
	local mainEndX = HotbarReskin.HOTBAR_SIZE + HotbarReskin.SEP_SIZE + slotCount * HotbarReskin.HOTBAR_SIZE + (slotCount - 1) * HotbarReskin.HOTBAR_PAD;
	if x >= 0 and x < HotbarReskin.HOTBAR_SIZE then
		return -2;
	end
	local rightHandX = mainEndX + HotbarReskin.SEP_SIZE;
	if x >= rightHandX and x < rightHandX + HotbarReskin.HOTBAR_SIZE then
		return -3;
	end
	return -1;
end

ISHotbar.update = function(self)
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
		if dx > HotbarReskin.DRAG_THRESHOLD or dy > HotbarReskin.DRAG_THRESHOLD then
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
				HotbarReskin.ensureDragPreviewUI();
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

	if HotbarReskin.isMouseBlocked(self) then
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

ISHotbar.onRightMouseUp = function(self, x, y)
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

ISHotbar.activateSlot = function(self, slotIndex)
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

	local both_hands = item:isTwoHandWeapon();
	local goToPrimary = both_hands or item:IsWeapon();

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
		ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, true, both_hands));
	else
		ISTimedActionQueue.add(ISEquipWeaponAction:new(self.chr, item, 20, false, false));
	end

	self.chr:getInventory():setDrawDirty(true);
	getPlayerData(self.chr:getPlayerNum()).playerInventory:refreshBackpacks();
end

ISHotbar.onMouseUp = function(self, x, y)
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
		HotbarReskin.removeDragPreviewUI();

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
		HotbarReskin.removeDragPreviewUI();
		return;
	end
end

ISHotbar.onMouseDown = function(self, x, y)
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

Events.OnPlayerDeath.Add(function()
	ISMouseDrag.dragging = nil;
	ISMouseDrag.draggingFocus = nil;
	ISMouseDrag.dragView = nil;
end);

Events.OnGameBoot.Add(function()
	for _, size in ipairs({ 48, 64, 80 }) do
		getTexture("media/ui/Hotbar/" .. size .. "/Slot/Slot_Background.png");
		getTexture("media/ui/Hotbar/" .. size .. "/Slot/Slot_Selected.png");

		for _, phaseData in ipairs(HotbarReskin.ConditionPhases) do
			local phaseLevel = phaseData[3];
			local thresholds = phaseData[4];
			for _, threshold in ipairs(thresholds) do
				getTexture("media/ui/Hotbar/" .. size .. "/Slot/Slot_" .. phaseLevel .. "_" .. threshold .. ".png");
			end
		end

		getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_Background.png");
		getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_Selected.png");
		getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_Hover.png");

		for _, phaseData in ipairs(HotbarReskin.ConditionPhases) do
			local phaseLevel = phaseData[3];
			local thresholds = phaseData[4];
			for _, threshold in ipairs(thresholds) do
				getTexture("media/ui/Hotbar/" .. size .. "/Hand/Hand_" .. phaseLevel .. "_" .. threshold .. ".png");
			end
		end
	end
end);