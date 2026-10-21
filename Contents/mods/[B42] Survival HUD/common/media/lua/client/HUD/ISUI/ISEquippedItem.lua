require "ISUI/ISEquippedItem";

local Utils = require("HUD/Utils");

local function filterButtons(...)
    local list = {};
    for i = 1, select("#", ...) do
        local btn = select(i, ...);
        if btn then
            table.insert(list, btn);
        end
    end
    return list;
end

local function isTabActive(infoPanel, tabName)
    if not infoPanel or not infoPanel:getIsVisible() or not infoPanel.panel then
        return false;
    end
    local activeView = infoPanel.panel:getActiveView();
    return activeView ~= nil and activeView == infoPanel.panel:getView(tabName);
end

local original_ISEquippedItem_checkBounds = ISEquippedItem.checkBounds;
function ISEquippedItem:checkBounds(boundsItem, x, y)
    if boundsItem == nil then
        return original_ISEquippedItem_checkBounds(self, boundsItem, x, y);
    end
    if not boundsItem:getIsVisible() then
        return false;
    end
    local absX = boundsItem.getAbsoluteX and boundsItem:getAbsoluteX() or (self:getAbsoluteX() + boundsItem:getX());
    local absY = boundsItem.getAbsoluteY and boundsItem:getAbsoluteY() or (self:getAbsoluteY() + boundsItem:getY());
    return x >= absX and x <= absX + boundsItem:getWidth() and y >= absY and y <= absY + boundsItem:getHeight();
end

local ACTIVATE_TICKS = 10;

function ISEquippedItem:checkToolTip()
    local mx, my = getMouseX(), getMouseY();
    local mouseOverID, tooltiptext = -1, nil;
    if self:isMouseOver() and self.mouseOverList ~= nil then
        for k, v in ipairs(self.mouseOverList) do
            if self:checkBounds(v.object, mx, my) then
                mouseOverID = k;
                tooltiptext = v.displayString;
            end
        end
    end
    if self.toolRender and self.toolRender:getIsVisible() then
        self.toolRender:setVisible(false);
    end
    self.activateCounter = self.activateCounter or 0;
    local activate = false;
    if mouseOverID ~= -1 then
        if self.activateCounter < ACTIVATE_TICKS then
            self.activateCounter = self.activateCounter + 1;
        end
        if self.activateCounter > ACTIVATE_TICKS / 2 then
            activate = true;
        elseif mouseOverID ~= self.lastId then
            self.activateCounter = 0;
        end
        self.lastId = mouseOverID;
    elseif self.activateCounter > 0 then
        self.activateCounter = self.activateCounter - 1;
    end
    self:doToolTip(activate, tooltiptext);
end

function ISEquippedItem:shrinkWrap()
    local xMax = 0;
    local yMax = 0;
    local children = self:getChildren();
    for _, child in pairs(children) do
        if child ~= self.adminBtn and child ~= self.warManagerBtn and child ~= self.arfBtn and child ~= self.skillsBtn then
            if child.Type == "ISButton" or child.Type == "ISImage" then
                xMax = math.max(xMax, child:getRight());
                yMax = math.max(yMax, child:getBottom());
            end
        end
    end
    self:setWidth(xMax);
    self:setHeight(yMax);
end

Functions.PostHook.Add(ISEquippedItem, "initialise", function(self)
    local size = getCore():getOptionSidebarSize();
    if size == 6 then
        size = getCore():getOptionFontSizeReal() - 1;
    end

    local width = 48;
    if size == 2 then
        width = 64;
    elseif size == 3 then
        width = 80;
    elseif size == 4 then
        width = 96;
    elseif size == 5 then
        width = 128;
    end

    self.btnWidth = width;
    self.btnHeight = width * 0.75;
    self.btnGap = math.floor(20 * width / 64 + 0.5);
    self.healthIconOscillatorScalar = 15.6 * (self.btnWidth / 48);

    self:removeChild(self.mainHand);
    self.mainHand:setX(-1000);
    self.mainHand:setY(-1000);

    self:removeChild(self.offHand);
    self.offHand:setX(-1000);
    self.offHand:setY(-1000);

    if self.mouseOverList then
        for i = #self.mouseOverList, 1, -1 do
            local entry = self.mouseOverList[i];
            if entry.displayString == getText("IGUI_PrimaryTooltip") or entry.displayString == getText("IGUI_SecondaryTooltip") then
                table.remove(self.mouseOverList, i);
            end
        end
    end

    self.skillsIconOn = Utils.getPackTexture("media/ui/Sidebar/" .. self.btnWidth .. "/Skills_On_" .. self.btnWidth .. ".png");
    self.skillsIconOff = Utils.getPackTexture("media/ui/Sidebar/" .. self.btnWidth .. "/Skills_Off_" .. self.btnWidth .. ".png");

    if self.invBtn then
        self.tutorialIconOn = Utils.getPackTexture("media/ui/Sidebar/" .. self.btnWidth .. "/Tutorial_On_" .. self.btnWidth .. ".png");
        self.tutorialIconOff = Utils.getPackTexture("media/ui/Sidebar/" .. self.btnWidth .. "/Tutorial_Off_" .. self.btnWidth .. ".png");

        self.tutorialBtn = ISButton:new(0, 0, self.btnWidth, self.btnHeight, "", self, ISEquippedItem.onOptionMouseDown);
        self.tutorialBtn:setImage(self.tutorialIconOff);
        self.tutorialBtn.internal = "TUTORIAL";
        self.tutorialBtn:initialise();
        self.tutorialBtn:instantiate();
        self.tutorialBtn:setDisplayBackground(false);
        self.tutorialBtn:ignoreWidthChange();
        self.tutorialBtn:ignoreHeightChange();
        self:addChild(self.tutorialBtn);
        self:addMouseOverToolTipItem(self.tutorialBtn, getText("SurvivalGuide_WindowTitle"));
    end

    local vanillaButtons = filterButtons(
        self.tutorialBtn,
        self.invBtn,
        self.healthBtn,
        self.craftingBtn,
        self.buildBtn,
        self.movableBtn,
        self.searchBtn,
        self.zoneBtn,
        self.mapBtn,
        self.debugBtn,
        self.safetyBtn,
        self.clientBtn
    );

    local isVanilla = {};
    for _, btn in ipairs(vanillaButtons) do
        isVanilla[btn] = true;
    end

    local extraButtons = {};
    for _, child in pairs(self:getChildren()) do
        if child.Type == "ISButton" and not isVanilla[child] then
            if child ~= self.adminBtn and child ~= self.warManagerBtn and child ~= self.arfBtn and child ~= self.skillsBtn then
                table.insert(extraButtons, child);
            end
        end
    end
    table.sort(extraButtons, function(a, b) return a:getY() < b:getY() end);

    for _, btn in ipairs(extraButtons) do
        table.insert(vanillaButtons, btn);
    end

    local curY = 0;
    for _, btn in ipairs(vanillaButtons) do
        if btn then
            btn:setY(curY);
            curY = curY + btn:getHeight() + self.btnGap;
        end
    end

    if self.radialIcon then
        self.radialIcon:setY(self.safetyBtn:getY());
    end

    if self.healthBtn then
        self.healthPopupShown = false;
        self.healthBaseX = self.healthBtn:getX();
        self.healthBaseY = self.healthBtn:getY();
        self.healthBaseW = self.healthBtn:getWidth();

        self.skillsBtn = ISButton:new(self.healthBaseX + self.healthBaseW + self.btnGap, self.healthBaseY, self.btnWidth, self.btnHeight, "", self, ISEquippedItem.onOptionMouseDown);
        self.skillsBtn:setImage(self.skillsIconOff);
        self.skillsBtn.internal = "SKILLS";
        self.skillsBtn:initialise();
        self.skillsBtn:instantiate();
        self.skillsBtn:setDisplayBackground(false);
        self.skillsBtn:ignoreWidthChange();
        self.skillsBtn:ignoreHeightChange();
        self.skillsBtn:setVisible(false);
        self:addChild(self.skillsBtn);
        self:addMouseOverToolTipItem(self.skillsBtn, getText("IGUI_XP_Skills"));
    end

    if self.debugBtn then
        self.debugPopupShown = false;
        self.debugBaseX = self.debugBtn:getX();
        self.debugBaseY = self.debugBtn:getY();
        self.debugBaseW = self.debugBtn:getWidth();

        if self.arfBtn then
            self.arfBtn:setWidth(self.debugBtn:getHeight());
            self.arfBtn:setX(self.debugBaseX + self.debugBaseW + self.btnGap);
            self.arfBtn:setY(self.debugBaseY);
            self.arfBtn:setVisible(false);
        end
    end

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
            self.adminBtn:setX(newX + newW + self.btnGap);
            self.adminBtn:setY(btnY);
            self.adminBtn:setVisible(false);
        end

        if self.warManagerBtn then
            self.warManagerBtn:setWidth(newW);
            if self.adminBtn then
                self.warManagerBtn:setX(self.adminBtn:getX() + self.adminBtn:getWidth() + self.btnGap);
            else
                self.warManagerBtn:setX(newX + newW + self.btnGap);
            end
            self.warManagerBtn:setY(btnY);
            self.warManagerBtn:setVisible(false);
        end

        self.clientBaseX = self.clientBtn:getX();
        self.clientBaseY = self.clientBtn:getY();
        self.clientBaseW = self.clientBtn:getWidth();
        self:addMouseOverToolTipItem(self.clientBtn, getText("IGUI_UserPanelTooltip"));
    end

    if self.mapBtn then
        self:addMouseOverToolTipItem(self.mapBtn, getText("IGUI_ViewMap"));
    end
    if self.adminBtn then
        self:addMouseOverToolTipItem(self.adminBtn, getText("IGUI_AdminPanelTooltip"));
    end
    if self.warManagerBtn then
        self:addMouseOverToolTipItem(self.warManagerBtn, getText("IGUI_WarManagerTooltip"));
    end

    self:shrinkWrap();

    if self.movableBtn then
        local btnX = self.movableBtn:getAbsoluteX();
        local btnY = self.movableBtn:getAbsoluteY();
        if self.movablePopup then
            self.movablePopup:setX(btnX);
            self.movablePopup:setY(btnY);
        end
        if self.movableTooltip then
            self.movableTooltip:setY(self.movableBtn:getY());
        end
    end
    if self.mapPopup then
        self.mapPopup:setX(self.mapBtn:getAbsoluteX());
        self.mapPopup:setY(self.mapBtn:getAbsoluteY());
    end
end)

local original_ISEquippedItem_prerender = ISEquippedItem.prerender;
function ISEquippedItem:prerender()
    local adminBtn = self.adminBtn;
    local warManagerBtn = self.warManagerBtn;
    self.adminBtn = nil;
    self.warManagerBtn = nil;

    local infoPanel = getPlayerInfoPanel(self.playerNum);

    original_ISEquippedItem_prerender(self);

    self.adminBtn = adminBtn;
    self.warManagerBtn = warManagerBtn;

    if self.healthBtn then
        local healthTex = isTabActive(infoPanel, getText("IGUI_XP_Health")) and self.heartIconOn or self.heartIconOff;
        if self.healthBtn.image ~= healthTex then
            self.healthBtn:setImage(healthTex);
        end
    end

    if self.tutorialBtn then
        local tutorialTex = (SurvivalGuide.instance and SurvivalGuide.instance:getIsVisible()) and self.tutorialIconOn or self.tutorialIconOff;
        if self.tutorialBtn.image ~= tutorialTex then
            self.tutorialBtn:setImage(tutorialTex);
        end
    end

    local debugRightmost = self.btnWidth;
    if self.debugBtn then
        local zoneX = self.debugBtn:getAbsoluteX() - self.btnGap / 2;
        local zoneY = self.debugBtn:getAbsoluteY() - self.btnGap / 2;
        local zoneW = self.debugBaseW;
        if self.arfBtn then
            zoneW = zoneW + self.btnGap + self.arfBtn:getWidth();
        end
        zoneW = zoneW + self.btnGap;
        local zoneH = self.debugBtn:getHeight() + self.btnGap;

        local mx, my = getMouseX(), getMouseY();
        local isOverZone = mx >= zoneX and mx <= zoneX + zoneW and my >= zoneY and my <= zoneY + zoneH;

        local isRecording = isAnimationRecorderActive();
        local showPopup = isRecording or (self.debugPopupShown and isOverZone) or self.debugBtn:isMouseOver();
        self.debugPopupShown = showPopup;

        if self.arfBtn then
            if self.arfBtn:getIsVisible() ~= showPopup then
                self.arfBtn:setVisible(showPopup);
            end
            local arfTex = isRecording and self.arfIconOn or self.arfIconOff;
            if self.arfBtn.image ~= arfTex then
                self.arfBtn:setImage(arfTex);
            end
            if showPopup and self.arfBtn:getIsVisible() then
                debugRightmost = math.max(debugRightmost, self.arfBtn:getX() + self.arfBtn:getWidth());
            end
        end

        local debugTex = ISDebugMenu.instance and self.debugIconOn or self.debugIconOff;
        if self.debugBtn.image ~= debugTex then
            self.debugBtn:setImage(debugTex);
        end
    end

    local clientRightmost = self.btnWidth;
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

        local btnX = self.clientBaseX;
        local btnY = self.clientBaseY;
        local btnW = self.clientBaseW;

        for i, btn in ipairs(buttons) do
            local targetX = btnX + (btnW + self.btnGap) * (i - 1);
            if btn:getX() ~= targetX then
                btn:setX(targetX);
            end
            if btn:getY() ~= btnY then
                btn:setY(btnY);
            end
        end

        if war and self.warManagerBtn then
            local timerString = tostring(war:getTime());
            local timerWidth = getTextManager():MeasureStringX(UIFont.Small, timerString);
            local timerOffset = self.warManagerBtn:getX() + (self.btnWidth / 2) - (timerWidth / 2);

            local warState = war:getState();
            local stateName = warState and warState:name();
            if stateName == "Claimed" or stateName == "Accepted" or stateName == "Started" then
                self:drawText(timerString, timerOffset, self.warManagerBtn:getBottom(), 1, 1, 1, 1, UIFont.Small);
                if stateName == "Claimed" then
                    self.warManagerBtn:setImage(self.warIconOff);
                elseif stateName == "Accepted" then
                    self.warIconTimer = self.warIconTimer - 0.05;
                    if self.warIconTimer < 0 then
                        self.warIconTimer = 1.0;
                    elseif self.warIconTimer < 0.5 then
                        self.warManagerBtn:setImage(self.warIconOff);
                    else
                        self.warManagerBtn:setImage(self.warIconOn);
                    end
                elseif stateName == "Started" then
                    self.warManagerBtn:setImage(self.warIconOn);
                end
            end
        end

        local role = self.chr:getRole();
        local adminAllowed = role and role:hasAdminTool();

        local zoneW = btnW;
        if hasWar then
            zoneW = zoneW + self.btnGap + self.clientBtn:getWidth();
            if adminAllowed and self.adminBtn then
                zoneW = zoneW + self.btnGap + self.adminBtn:getWidth();
            end
        elseif adminAllowed and self.adminBtn then
            zoneW = zoneW + self.btnGap + self.adminBtn:getWidth();
        end

        local parentBtn = buttons[1];
        local zoneX = parentBtn:getAbsoluteX() - self.btnGap / 2;
        local zoneY = parentBtn:getAbsoluteY() - self.btnGap / 2;
        zoneW = zoneW + self.btnGap;
        local zoneH = parentBtn:getHeight() + self.btnGap;

        local mx, my = getMouseX(), getMouseY();
        local isOverZone = mx >= zoneX and mx <= zoneX + zoneW and my >= zoneY and my <= zoneY + zoneH;

        local isChildWindowOpen = (adminAllowed and ISAdminPanelUI.instance ~= nil) or (hasWar and ISUserPanelUI.instance ~= nil);

        local showPopup = isChildWindowOpen or (self.clientPopupShown and isOverZone) or parentBtn:isMouseOver();
        self.clientPopupShown = showPopup;

        if self.adminBtn then
            local isAdminVisible = showPopup and adminAllowed;
            if self.adminBtn:getIsVisible() ~= isAdminVisible then
                self.adminBtn:setVisible(isAdminVisible);
            end
            if not isAdminVisible and ISAdminPanelUI.instance then
                ISAdminPanelUI.instance:close();
            end
            local adminTex = ISAdminPanelUI.instance and self.adminIconOn or self.adminIconOff;
            if self.adminBtn.image ~= adminTex then
                self.adminBtn:setImage(adminTex);
            end
        end

        if self.warManagerBtn then
            local warVisible = hasWar;
            if self.warManagerBtn:getIsVisible() ~= warVisible then
                self.warManagerBtn:setVisible(warVisible);
            end
            if not warVisible and ISWarManagerUI.instance then
                ISWarManagerUI.instance:closeModal();
            end
        end

        local isClientVisible = not hasWar or showPopup;
        if self.clientBtn:getIsVisible() ~= isClientVisible then
            self.clientBtn:setVisible(isClientVisible);
        end

        if showPopup then
            local rightmost = self.btnWidth;
            if self.clientBtn:getIsVisible() then
                rightmost = math.max(rightmost, self.clientBtn:getX() + self.clientBtn:getWidth());
            end
            if self.adminBtn and self.adminBtn:getIsVisible() then
                rightmost = math.max(rightmost, self.adminBtn:getX() + self.adminBtn:getWidth());
            end
            if self.warManagerBtn and self.warManagerBtn:getIsVisible() then
                rightmost = math.max(rightmost, self.warManagerBtn:getX() + self.warManagerBtn:getWidth());
            end
            clientRightmost = rightmost;
        end
    end

    local healthRightmost = self.btnWidth;
    if self.skillsBtn then
        self.skillsBtn:setY(self.healthBtn:getY());
        self.skillsBtn:setX(self.healthBaseX + self.healthBaseW + self.btnGap);

        local zoneX = self:getAbsoluteX() + self.healthBaseX - self.btnGap / 2;
        local zoneY = self.healthBtn:getAbsoluteY() - self.btnGap / 2;
        local zoneW = self.healthBaseW + self.btnGap + self.skillsBtn:getWidth() + self.btnGap;
        local zoneH = self.healthBtn:getHeight() + self.btnGap;

        local mx, my = getMouseX(), getMouseY();
        local isOverZone = mx >= zoneX and mx <= zoneX + zoneW and my >= zoneY and my <= zoneY + zoneH;

        local isOscillating = self.healthIconOscillatorLevel > 0.05;
        local isSkillsActive = isTabActive(infoPanel, getText("IGUI_XP_Skills"));

        local showPopup = not isOscillating and (isSkillsActive or (self.healthPopupShown and isOverZone) or self.healthBtn:isMouseOver());
        self.healthPopupShown = showPopup;

        if self.skillsBtn:getIsVisible() ~= showPopup then
            self.skillsBtn:setVisible(showPopup);
        end

        local skillsTex = isSkillsActive and self.skillsIconOn or self.skillsIconOff;
        if self.skillsBtn.image ~= skillsTex then
            self.skillsBtn:setImage(skillsTex);
        end

        if showPopup then
            healthRightmost = math.max(healthRightmost, self.skillsBtn:getX() + self.skillsBtn:getWidth());
        end
    end

    local targetWidth = math.max(self.btnWidth, clientRightmost, debugRightmost, healthRightmost);
    if self:getWidth() ~= targetWidth then
        self:setWidth(targetWidth);
    end
end

local original_ISEquippedItem_onOptionMouseDown = ISEquippedItem.onOptionMouseDown;
function ISEquippedItem:onOptionMouseDown(button, x, y)
    if button.internal == "SKILLS" then
        if self.infopanel then
            self.infopanel:toggleView(getText("IGUI_XP_Skills"));
            if self.infopanel:isVisible() and JoypadState.players[self.playerNum + 1] then
                setJoypadFocus(self.playerNum, self.infopanel.panel:getActiveView());
            end
        end
    elseif button.internal == "TUTORIAL" then
        if not SurvivalGuide.instance then
            createSurvivalGuide();
        end
        local panel = SurvivalGuide.instance;
        if panel then
            panel:populateList();
            panel:setVisible(not panel:getIsVisible());
            panel:restorePosition();
            panel.listBox.selected = 2;
            panel.listBox.smoothScrollY = panel.listBox:getYScroll();
            panel.listBox.smoothScrollTargetY = 0;
            panel:onClickList();
            if panel:getIsVisible() and JoypadState.players[self.playerNum + 1] then
                panel:onGainJoypadFocus(JoypadState.players[self.playerNum + 1]);
            end
        end
    else
        original_ISEquippedItem_onOptionMouseDown(self, button, x, y);
    end
end