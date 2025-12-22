require "ISUI/ISEquippedItem"

local original_ISEquippedItem_initialise = ISEquippedItem.initialise
local original_ISEquippedItem_onOptionMouseDown = ISEquippedItem.onOptionMouseDown
local original_ISEquippedItem_prerender = ISEquippedItem.prerender

function ISEquippedItem:initialise()
    original_ISEquippedItem_initialise(self)

    local sidebarSize = getCore():getOptionSidebarSize()
    local texWidth = 48
    
    if sidebarSize == 2 then texWidth = 64
    elseif sidebarSize == 3 then texWidth = 80
    elseif sidebarSize == 4 then texWidth = 96
    elseif sidebarSize == 5 then texWidth = 128 end

    self.perksIconOn = getTexture("media/ui/Sidebar/" .. texWidth .. "/Perks_On_" .. texWidth .. ".png")
    self.perksIconOff = getTexture("media/ui/Sidebar/" .. texWidth .. "/Perks_Off_" .. texWidth .. ".png")
end

function ISEquippedItem:prerender()
    original_ISEquippedItem_prerender(self)

    local isInjured = self.healthIconOscillatorLevel > 0.01
    local isInfoOpen = getPlayerInfoPanel(self.playerNum) and getPlayerInfoPanel(self.playerNum):getIsVisible()

    if self.healthBtn then
        if isInjured then
            if isInfoOpen then
                self.healthBtn:setImage(self.heartIconOn)
            else
                self.healthBtn:setImage(self.heartIconOff)
            end
            
            self:updateTooltipText(getText("IGUI_HealthTooltip"))
        else
            if isInfoOpen then
                self.healthBtn:setImage(self.perksIconOn)
            else
                self.healthBtn:setImage(self.perksIconOff)
            end

            self:updateTooltipText(getText("IGUI_XP_Skills"))
        end
    end
end

function ISEquippedItem:updateTooltipText(newText)
    if self.mouseOverList then
        for _, v in ipairs(self.mouseOverList) do
            if v.object == self.healthBtn then
                v.displayString = newText
                break
            end
        end
    end
end

function ISEquippedItem:onOptionMouseDown(button, x, y)
    if button.internal == "HEALTH" then
        local isInjured = self.healthIconOscillatorLevel > 0.01

        if isInjured then
            original_ISEquippedItem_onOptionMouseDown(self, button, x, y)
        else
            if self.infopanel then
                self.infopanel:toggleView(getText("IGUI_XP_Skills"))
            end
        end
    else
        original_ISEquippedItem_onOptionMouseDown(self, button, x, y)
    end
end