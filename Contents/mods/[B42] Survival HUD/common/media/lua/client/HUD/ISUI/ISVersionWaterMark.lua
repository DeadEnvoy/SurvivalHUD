require "ISUI/ISVersionWaterMark";

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.NewSmall);
local WATERMARK_WIDTH = 200;
local HUD_TOP_OFFSET = 26;

WaterMarkUI.render = function(self)
    self.chr = getPlayer();
    if not self.chr then return; end

    self.revButton:setVisible(false);
    self.javaObject:setConsumeMouseEvents(false);

    ISPanel.render(self);

    self:setWidth(WATERMARK_WIDTH);
    self:setX(getCore():getScreenWidth() - 10 - self.width);

    local hudHeight = SurvivalHUD.ICON_SIZE + HUD_TOP_OFFSET;
    self:setY(getCore():getScreenHeight() - hudHeight);

    local y = -FONT_HGT_SMALL - 3;
    local alpha, width = 0.3, self.width;

    if isClient() then
        local statusData = getMPStatus();
        if tonumber(getMaxPlayers()) > 32 then
            self:drawTextRight(getText("UI_MaxPlayers_Notification"), width, y, 1, 1, 1, 1, UIFont.NewSmall);
			y = y - FONT_HGT_SMALL - 3;
        end

        if isShowServerInfo() then
            self:drawTextRight(getText("UI_ServerTime", statusData.serverTime, statusData.lastPing), width, y, 1, 1, 1, 1, UIFont.NewSmall);
			y = y - FONT_HGT_SMALL - 3;
        end

        if isShowConnectionInfo() then
            self:drawTextRight("\"" .. getServerName() .. "\" (" .. getServerIP() .. ":" .. getServerPort() .. ")", width, y, 1, 1, 1, 1, UIFont.NewSmall);
			y = y - FONT_HGT_SMALL - 3;
        end
    end

    local cheats = getCheatTypes();
    for i = 0, cheats:size() - 1 do
        local cheat = cheats:get(i);
        if self.chr:isCheatSet(cheat) then
            self:drawTextRight(getText("IGUI_CheatPanel_" .. cheat:getTooltip()), width, y, 1, 1, 1, alpha, UIFont.NewSmall);
            y = y - FONT_HGT_SMALL - 3;
        end
    end
end