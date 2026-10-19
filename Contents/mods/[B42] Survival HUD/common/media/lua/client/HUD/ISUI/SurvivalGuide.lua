require "SurvivalGuide/SurvivalGuide";
require "OptionScreens/MainOptions";

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.NewSmall);
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.NewMedium);
local VIDEO_WIDTH, VIDEO_HEIGHT = 960, 480;
local MIN_LIST_WIDTH = 100;
local DESCRIPTION_HEIGHT = 150;

function SurvivalGuide:new()
    local rh = self:resizeWidgetHeight();
    local o = ISCollapsableWindowJoypad.new(self, 0, 0, 0, VIDEO_HEIGHT + DESCRIPTION_HEIGHT + rh);
    o.resizable = false;
    o.title = getText("SurvivalGuide_WindowTitle");
    o:setWantKeyEvents(true);
    o.smallResolution = false;
    o.mediumResolution = false;
    setmetatable(o, self)
    self.__index = self
    return o
end

function SurvivalGuide:createChildren()
    ISCollapsableWindowJoypad.createChildren(self);

    local rh = self:resizeWidgetHeight();
    self.listBox = ISScrollingListBox:new(0, self:titleBarHeight(), MIN_LIST_WIDTH, self.height - self:titleBarHeight() - rh);
    self.listBox:initialise();
    self.listBox:instantiate();
    self.listBox:setAnchorsTBLR(true, true, true, false);
    self.listBox.itemheight = FONT_HGT_SMALL + 2;
    self.listBox.drawBorder = true;
    self.listBox.backgroundColor = {r=0, g=0, b=0, a=0.5};
    self.listBox.font = UIFont.NewSmall;
    self.listBox.doDrawItem = SurvivalGuide.doDrawItem;
    self.listBox:setOnMouseDownFunction(self, SurvivalGuide.onClickList);
    self.listBox:setOverrideAButtonFunction(self, SurvivalGuide.onClose);
    self:addChild(self.listBox);

    self.videoRichText = ISRichTextPanel:new(self.listBox:getRight(), self.listBox:getY(), VIDEO_WIDTH, VIDEO_HEIGHT);
    self.videoRichText:initialise();
    self.videoRichText:setAnchorsTBLR(true, false, true, false);
    self.videoRichText.autosetheight = false;
    self.videoRichText.clip = true;
    self.videoRichText.doRepaintStencil = true;
    self.videoRichText:setMargins(0, 0, 0, 0);
    self.videoRichText.blockMouseWheel = true;
    self:addChild(self.videoRichText);

    local scrollbarWid = 13;

    self.descriptionRichText = ISRichTextPanel:new(self.listBox:getRight(), self.videoRichText:getBottom(), self.videoRichText:getWidth(), self.listBox:getHeight() - self.videoRichText:getHeight());
    self.descriptionRichText:initialise();
    self.descriptionRichText:setAnchorsTBLR(false, true, true, false);
    self.descriptionRichText.autosetheight = false;
    self.descriptionRichText:setMargins(10, 10, 10 + scrollbarWid, 0);
    self.descriptionRichText.clip = true;
    self.descriptionRichText.doRepaintStencil = true;
    self:addChild(self.descriptionRichText);
    self.descriptionRichText:addScrollBars();

    self:populateList();
    self:restorePosition();

    self.listBox.selected = 2;
    self:onClickList();
end

function SurvivalGuide:populateList()
    self.listBox:clear();
    if not self.smallResolution then
        self.listBox:setFont(UIFont.NewMedium);
        self.listBox.itemheight = FONT_HGT_MEDIUM;
    end
    local entries = SurvivalGuideEntry.getAll();
    local listWidth = MIN_LIST_WIDTH;
    for i = 0, entries:size() - 1 do
        local entry = entries:get(i);
        local name = getText(entry:getTitle());
        local title = name;
        local subCategory = false;
        if entry:getSubCategory() then
            subCategory = true;
            name = "    " .. name;
            local text = entry:getText(JoypadState.players[1] ~= nil);
            if text then
                self.listBox:addItem(name, { title = title, description = text, video = entry:getVideo(), subCategory = subCategory, id = entry:toString() });
            end
        else
            self.listBox:addItem(name, { title = title, spiffo = getText(entry:getDescription()), id = entry:toString(), category_image = getTextOrNull(entry:getCategoryImage()) });
        end
        local extraPad = subCategory and 35 or (self.listBox.itemheight + 25);
        local textWidth = getTextManager():MeasureStringX(subCategory and UIFont.NewSmall or UIFont.NewMedium, name) + extraPad;
        if textWidth > listWidth then
            listWidth = textWidth;
        end
    end
    self.listBox:setWidth(listWidth);
    self.listBox.vscroll:setX(self.listBox.width - 16);
end

function SurvivalGuide:restorePosition()
    self.smallResolution = getCore():getScreenWidth() <= 1600;
    self.mediumResolution = getCore():getScreenWidth() <= 1920;

    self:setWidth(self.listBox:getWidth() + VIDEO_WIDTH);
    self.videoRichText:setX(self.listBox:getRight());
    self.descriptionRichText:setX(self.listBox:getRight());
    self:setX(getCore():getScreenWidth() / 2 - self:getWidth() / 2);
    self:setY(getCore():getScreenHeight() / 2 - self:getHeight() / 2);

    local btnHeight = self:titleBarHeight() - 2;
    local btnX = self.width - 1 - btnHeight;
    self.pinButton:setX(btnX);
    self.pinButton:setVisible(not self.pin);
    self.collapseButton:setX(btnX);
    self.collapseButton:setVisible(self.pin);
end

function SurvivalGuide:render()
    if not self.isCollapsed and self.drawFrame then
        local rh = self:resizeWidgetHeight();
        local height = self:getHeight();
        local color = self.widgetTextureColor;
        self:drawRectBorder(0, height - rh, self:getWidth(), rh, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
        self:drawTextureScaled(self.statusbarbkg, 1, height - rh + 1, self:getWidth() - 2, rh - 2, color.a, color.r, color.g, color.b);
    end

    ISCollapsableWindowJoypad.render(self);
end

function SurvivalGuide:prerender()
    ISCollapsableWindowJoypad.prerender(self);
    local joypadData = getJoypadData(0);
    if joypadData then
        self.descriptionRichText:doRightJoystickScrolling(joypadData, 20, 10);
    end
end

function SurvivalGuide:RestoreLayout()
end

function SurvivalGuide:setVisible(visible, joypadData)
    ISCollapsableWindowJoypad.setVisible(self, visible);
    local joypad = joypadData or JoypadState.players[1];
    if joypad then
        joypad.focus = visible and self or nil;
        if visible then
            joypad.activeWhilePaused = true;
        else
            joypad.focus = self.previousJoypadFocus;
            self.previousJoypadFocus = nil;
        end
        updateJoypadFocus(joypad);
    end
end

Events.OnGameStart.Remove(SurvivalGuide.OnGameStart);

local _original_MainOptions_addUIPanel = MainOptions.addUIPanel;
MainOptions.addUIPanel = function(self)
    local _original_addYesNo = self.addYesNo;
    self.addYesNo = function(panel, x, y, w, h, name)
        if name == getText("UI_optionscreen_ShowSurvivalGuide") then
            return {
                setSelected = function() end,
                isSelected = function() return getCore():getOptionShowSurvivalGuide(); end,
            };
        end
        return _original_addYesNo(panel, x, y, w, h, name);
    end

    _original_MainOptions_addUIPanel(self);
    self.addYesNo = _original_addYesNo;
end