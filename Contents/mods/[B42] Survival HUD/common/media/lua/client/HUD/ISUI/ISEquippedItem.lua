require "ISUI/ISEquippedItem";

local GAP = 15;

local function isTabActive(infoPanel, tabName)
    if not infoPanel or not infoPanel:getIsVisible() or not infoPanel.panel then
        return false;
    end
    local activeView = infoPanel.panel:getActiveView();
    return activeView ~= nil and activeView == infoPanel.panel:getView(tabName);
end

local original_ISEquippedItem_checkBounds = ISEquippedItem.checkBounds;
function ISEquippedItem:checkBounds(_boundsItem, _x, _y)
    if _boundsItem == nil then
        return original_ISEquippedItem_checkBounds(self, _boundsItem, _x, _y);
    end
    if _boundsItem.hudHandTooltip and self.hudHandsHidden then
        return false;
    end
    if _boundsItem.getIsVisible and not _boundsItem:getIsVisible() then
        return false;
    end
    if _boundsItem.getAbsoluteX then
        local absX = _boundsItem:getAbsoluteX();
        local absY = _boundsItem:getAbsoluteY();
        if _x >= absX and _x <= absX + _boundsItem:getWidth() and _y >= absY and _y <= absY + _boundsItem:getHeight() then
            return true;
        end
        return false;
    end
    return original_ISEquippedItem_checkBounds(self, _boundsItem, _x, _y);
end

local HAND_PARK_Y = -1000;

local function findHandTooltipEntries(self)
    if not self.mouseOverList then
        return nil, nil;
    end
    local primary, secondary;
    local primaryText = getText("IGUI_PrimaryTooltip");
    local secondaryText = getText("IGUI_SecondaryTooltip");
    for _, entry in ipairs(self.mouseOverList) do
        if entry.displayString == primaryText and primary == nil and entry.object.getIsVisible == nil then
            primary = entry;
        elseif entry.displayString == secondaryText and secondary == nil and entry.object.getIsVisible == nil then
            secondary = entry;
        end
    end
    return primary, secondary;
end

local function updateAnchoredPopups(self)
    local anchorDelta = 0;
    if self.hudHandsHidden == true then
        anchorDelta = -self.hudShiftOffset;
    elseif self.hudShiftOffset then
        anchorDelta = self.hudShiftOffset;
    end

    if anchorDelta ~= 0 then
        if self.movablePopup then
            self.movablePopup:setY(self.movablePopup:getY() + anchorDelta);
        end
        if self.movableTooltip then
            self.movableTooltip:setY(self.movableTooltip:getY() + anchorDelta);
        end
        if self.mapPopup then
            self.mapPopup:setY(self.mapPopup:getY() + anchorDelta);
        end
        if self.clientBaseY then
            self.clientBaseY = self.clientBaseY + anchorDelta;
        end
    end
end

local function updateHandSlots(self)
    local handsHidden = HotbarReskin and SurvivalHUD.ShowHandSlots;
    if self.hudHandsHidden == handsHidden then
        return;
    end
    if self.hudHandsHidden == true then
        for _, child in pairs(self:getChildren()) do
            if child.hudBaseY then
                child:setY(child.hudBaseY);
            end
        end
        self.mainHand:setY(self.mainHand.hudBaseY);
        self.offHand:setY(self.offHand.hudBaseY);
        self:setHeight(self.hudBaseHeight);
        self.hudBaseYAssigned = false;
    end
    if handsHidden then
        if not self.hudBaseYAssigned then
            for _, child in pairs(self:getChildren()) do
                child.hudBaseY = child:getY();
            end
            self.mainHand.hudBaseY = self.mainHand:getY();
            self.offHand.hudBaseY = self.offHand:getY();
            self.hudBaseHeight = self:getHeight();
            local primaryTooltip, secondaryTooltip = findHandTooltipEntries(self);
            if primaryTooltip then
                primaryTooltip.object.hudHandTooltip = true;
            end
            if secondaryTooltip then
                secondaryTooltip.object.hudHandTooltip = true;
            end
            self.hudBaseYAssigned = true;
        end

        local children = self:getChildren();
        local belowTop = nil;
        for _, child in pairs(children) do
            if child ~= self.mainHand and child ~= self.offHand and child:getY() > self.offHand:getBottom() then
                if belowTop == nil or child:getY() < belowTop then
                    belowTop = child:getY();
                end
            end
        end
        if belowTop then
            local offset = belowTop - self.mainHand:getY();
            self.hudShiftOffset = offset;

            self.mainHand:setY(HAND_PARK_Y);
            self.offHand:setY(HAND_PARK_Y);
            for _, child in pairs(children) do
                if child ~= self.mainHand and child ~= self.offHand then
                    child:setY(child:getY() - offset);
                end
            end
            self:setHeight(self:getHeight() - offset);
        end
    end
    self.hudHandsHidden = handsHidden;
    updateAnchoredPopups(self);
end

function ISEquippedItem:shrinkWrap()
    local xMax = 0
    local yMax = 0
    local children = self:getChildren()
    for _, child in pairs(children) do
        if child ~= self.adminBtn and child ~= self.warManagerBtn then
            if child.Type == "ISButton" then
                xMax = math.max(xMax, child:getRight())
                yMax = math.max(yMax, child:getBottom())
            end
        end
    end
    self:setWidth(xMax)
    self:setHeight(yMax)
end

Functions.PostHook.Add(ISEquippedItem, "initialise", function(self)
    local size = getCore():getOptionSidebarSize()
    if size == 6 then
        size = getCore():getOptionFontSizeReal() - 1
    end
    TEXTURE_WIDTH = 48
    if size == 2 then
        TEXTURE_WIDTH = 64
    elseif size == 3 then
        TEXTURE_WIDTH = 80
    elseif size == 4 then
        TEXTURE_WIDTH = 96
    elseif size == 5 then
        TEXTURE_WIDTH = 128
    end

    TEXTURE_HEIGHT = TEXTURE_WIDTH * 0.75

    self.perksIconOn = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Perks_On_" .. TEXTURE_WIDTH .. ".png");
    self.perksIconOff = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .. "/Perks_Off_" .. TEXTURE_WIDTH .. ".png");

    if self.clientBtn then
        local btnX = self.clientBtn:getX();
        local btnY = self.clientBtn:getY();
        local btnW = self.clientBtn:getWidth();
        local btnH = self.clientBtn:getHeight();

        local newW = btnH;
        local newX = btnX + (btnW - btnH) / 2;

        self.clientBtn:setX(newX);
        self.clientBtn:setWidth(newW);

        self.clientPopupShown = false;

        if self.adminBtn then
            self.adminBtn:setWidth(newW);
            self.adminBtn:setX(newX + newW + GAP);
            self.adminBtn:setY(btnY);
            self.adminBtn:setVisible(false);
        end

        if self.warManagerBtn then
            self.warManagerBtn:setWidth(newW);
            if self.adminBtn then
                self.warManagerBtn:setX(self.adminBtn:getX() + self.adminBtn:getWidth() + GAP);
            else
                self.warManagerBtn:setX(newX + newW + GAP);
            end
            self.warManagerBtn:setY(btnY);
            self.warManagerBtn:setVisible(false);
        end
    end

    if not ISMiniMap.IsAllowed() then
        if self.mapBtn then
            local mapBtnY = self.mapBtn:getY();
            local offset = self.mapBtn:getHeight() + 15;

            self:removeChild(self.mapBtn);
            self.mapBtn = nil;

            if self.mapPopup then
                self.mapPopup:removeFromUIManager();
                self.mapPopup = nil;
            end

            local children = self:getChildren();
            for _, child in pairs(children) do
                if child:getY() > mapBtnY then
                    child:setY(child:getY() - offset);
                end
            end
        end
    end

    if self.clientBtn then
        self.clientBaseX = self.clientBtn:getX();
        self.clientBaseY = self.clientBtn:getY();
        self.clientBaseW = self.clientBtn:getWidth();
    end

    if self.clientBtn then
        self:addMouseOverToolTipItem(self.clientBtn, getText("IGUI_UserPanelTooltip"));
    end
    if self.adminBtn then
        self:addMouseOverToolTipItem(self.adminBtn, getText("IGUI_AdminPanelTooltip"));
    end
    if self.warManagerBtn then
        self:addMouseOverToolTipItem(self.warManagerBtn, getText("IGUI_WarManagerTooltip"));
    end

    self:shrinkWrap();

    self:updateTooltipText(getText("IGUI_XP_Skills"));
end)

local original_ISEquippedItem_prerender = ISEquippedItem.prerender;
function ISEquippedItem:prerender()
    updateHandSlots(self);

    local adminBtn = self.adminBtn;
    local warManagerBtn = self.warManagerBtn;
    self.adminBtn = nil;
    self.warManagerBtn = nil;

    local infoPanel = getPlayerInfoPanel(self.playerNum);

    original_ISEquippedItem_prerender(self);

    self.adminBtn = adminBtn;
    self.warManagerBtn = warManagerBtn;

    if self.healthBtn then
        if isTabActive(infoPanel, getText("IGUI_XP_Skills")) then
            self.healthBtn:setImage(self.perksIconOn);
        else
            self.healthBtn:setImage(self.perksIconOff);
        end
    end

    if self.clientBtn then
        local war = isClient() and getWarNearest() or nil;
        local hasWar = war ~= nil;

        local buttons = {};
        if hasWar then
            table.insert(buttons, self.warManagerBtn);
            table.insert(buttons, self.clientBtn);
        else
            table.insert(buttons, self.clientBtn);
        end
        if self.adminBtn then
            table.insert(buttons, self.adminBtn);
        end
        local parentBtn = buttons[1];

        local btnX = self.clientBaseX;
        local btnY = self.clientBaseY;
        local btnW = self.clientBaseW;

        for i, btn in ipairs(buttons) do
            btn:setX(btnX + (btnW + GAP) * (i - 1));
            btn:setY(btnY);
        end

        if war and self.warManagerBtn then
            local timerString = tostring(war:getTime());
            local timerWidth = getTextManager():MeasureStringX(UIFont.Small, timerString);
            local timerOffset = self.warManagerBtn:getX() + (TEXTURE_WIDTH / 2) - (timerWidth / 2);

            if war:getState():name() == "Claimed" then
                self:drawText(timerString, timerOffset, self.warManagerBtn:getBottom(), 1, 1, 1, 1, UIFont.Small);
                self.warManagerBtn:setImage(self.warIconOff);
            elseif war:getState():name() == "Accepted" then
                self:drawText(timerString, timerOffset, self.warManagerBtn:getBottom(), 1, 1, 1, 1, UIFont.Small);
                self.warIconTimer = self.warIconTimer - 0.05;
                if self.warIconTimer < 0 then
                    self.warIconTimer = 1.0;
                elseif self.warIconTimer < 0.5 then
                    self.warManagerBtn:setImage(self.warIconOff);
                else
                    self.warManagerBtn:setImage(self.warIconOn);
                end
            elseif war:getState():name() == "Started" then
                self:drawText(timerString, timerOffset, self.warManagerBtn:getBottom(), 1, 1, 1, 1, UIFont.Small);
                self.warManagerBtn:setImage(self.warIconOn);
            end
        end

        local adminAllowed = self.chr:getRole():hasAdminTool();

        local zoneW = btnW;
        if hasWar then
            zoneW = zoneW + GAP + self.clientBtn:getWidth();
            if adminAllowed and self.adminBtn then
                zoneW = zoneW + GAP + self.adminBtn:getWidth();
            end
        elseif adminAllowed and self.adminBtn then
            zoneW = zoneW + GAP + self.adminBtn:getWidth();
        end

        local zoneX = parentBtn:getAbsoluteX() - GAP / 2;
        local zoneY = parentBtn:getAbsoluteY() - GAP / 2;
        zoneW = zoneW + GAP;
        local zoneH = parentBtn:getHeight() + GAP;

        local mx, my = getMouseX(), getMouseY();
        local isOverZone = mx >= zoneX and mx <= zoneX + zoneW and my >= zoneY and my <= zoneY + zoneH;

        local isAnyWindowOpen = ISAdminPanelUI.instance ~= nil or ISWarManagerUI.instance ~= nil or ISUserPanelUI.instance ~= nil;

        local showPopup = false;
        if isAnyWindowOpen then
            showPopup = true;
            self.clientPopupShown = true;
        elseif self.clientPopupShown then
            if isOverZone then
                showPopup = true;
            else
                self.clientPopupShown = false;
            end
        else
            if parentBtn:isMouseOver() then
                showPopup = true;
                self.clientPopupShown = true;
            end
        end

        if self.adminBtn then
            local isAdminVisible = showPopup and adminAllowed;
            self.adminBtn:setVisible(isAdminVisible);
            if not isAdminVisible and ISAdminPanelUI.instance then
                ISAdminPanelUI.instance:close();
            end
            if ISAdminPanelUI.instance then
                self.adminBtn:setImage(self.adminIconOn);
            else
                self.adminBtn:setImage(self.adminIconOff);
            end
        end

        if self.warManagerBtn then
            local warVisible = hasWar;
            self.warManagerBtn:setVisible(warVisible);
            if not warVisible and ISWarManagerUI.instance then
                ISWarManagerUI.instance:closeModal();
            end
        end

        self.clientBtn:setVisible(not hasWar or showPopup);

        local expandedWidth = TEXTURE_WIDTH;
        if showPopup then
            local rightmost = expandedWidth;
            if self.clientBtn and self.clientBtn:getIsVisible() then
                rightmost = math.max(rightmost, self.clientBtn:getX() + self.clientBtn:getWidth());
            end
            if self.adminBtn and self.adminBtn:getIsVisible() then
                rightmost = math.max(rightmost, self.adminBtn:getX() + self.adminBtn:getWidth());
            end
            if self.warManagerBtn and self.warManagerBtn:getIsVisible() then
                rightmost = math.max(rightmost, self.warManagerBtn:getX() + self.warManagerBtn:getWidth());
            end
            expandedWidth = rightmost;
        end
        self:setWidth(expandedWidth);
    end
end

function ISEquippedItem:updateTooltipText(newText)
    if self.mouseOverList then
        for _, v in ipairs(self.mouseOverList) do
            if v.object == self.healthBtn then
                v.displayString = newText;
                break;
            end
        end
    end
end

local original_ISEquippedItem_onOptionMouseDown = ISEquippedItem.onOptionMouseDown;
function ISEquippedItem:onOptionMouseDown(button, x, y)
    if button.internal == "HEALTH" then
        if self.infopanel then
            self.infopanel:toggleView(getText("IGUI_XP_Skills"));
        end
    else
        original_ISEquippedItem_onOptionMouseDown(self, button, x, y);
    end
end

Functions.PostHook.Add(ISEquippedItem, "render", function(self)
    if self.healthBtn then
        self.healthBtn:setX(0);
    end
end)