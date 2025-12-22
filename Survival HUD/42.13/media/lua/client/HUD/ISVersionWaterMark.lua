require "ISUI/ISVersionWaterMark"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.NewSmall)

WaterMarkUI.render = function(self)
    if self.revButton then
        self.revButton:setVisible(false)
    end

    ISPanel.render(self)

    self:setWidth(200); self:setX(getCore():getScreenWidth() - 10 - self.width); self:setY(getCore():getScreenHeight() - 100)

    local y = -FONT_HGT_SMALL - 3
    local alpha, width = 0.3, self.width
    
    if ISBuildMenu and ISBuildMenu.cheat then
        self:drawTextRight(getText("IGUI_CheatPanel_BuildCheat"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if self.chr:isInvisible() then
        self:drawTextRight(getText("IGUI_CheatPanel_Invisible"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if self.chr:isGodMod() then
        self:drawTextRight(getText("IGUI_CheatPanel_GodMod"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if self.chr:isNoClip() then
        self:drawTextRight(getText("IGUI_CheatPanel_NoClip"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if ISFastTeleportMove and ISFastTeleportMove.cheat then
        self:drawTextRight(getText("IGUI_CheatPanel_FastMove"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if self.chr:isTimedActionInstantCheat() then
        self:drawTextRight(getText("IGUI_CheatPanel_TimedActionInstant"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if self.chr:isUnlimitedCarry() then
        self:drawTextRight(getText("IGUI_CheatPanel_UnlimitedCarry"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if self.chr:isUnlimitedEndurance() then
        self:drawTextRight(getText("IGUI_CheatPanel_UnlimitedEndurance"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if self.chr:isUnlimitedAmmo() then
        self:drawTextRight(getText("IGUI_CheatPanel_UnlimitedAmmo"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if self.chr:isKnowAllRecipes() then
        self:drawTextRight(getText("IGUI_CheatPanel_KnowAllRecipes"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if ISFarmingMenu and ISFarmingMenu.cheat then
        self:drawTextRight(getText("IGUI_CheatPanel_FarmingCheat"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if ISHealthPanel and ISHealthPanel.cheat then
        self:drawTextRight(getText("IGUI_CheatPanel_HealthCheat"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if ISVehicleMechanics and ISVehicleMechanics.cheat then
        self:drawTextRight(getText("IGUI_CheatPanel_MechanicsCheat"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if ISMoveableDefinitions and ISMoveableDefinitions.cheat then
        self:drawTextRight(getText("IGUI_CheatPanel_MoveableCheat"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end
    if AnimalContextMenu and AnimalContextMenu.cheat then
        self:drawTextRight(getText("IGUI_CheatPanel_AnimalCheat"), width, y, 1, 1, 1, alpha, UIFont.NewSmall)
        y = y - FONT_HGT_SMALL - 3
    end

    if y == (-FONT_HGT_SMALL - 3) then
        if self:isVisible() then self:setVisible(false) end
    else
        if not self:isVisible() then self:setVisible(true) end
    end
end