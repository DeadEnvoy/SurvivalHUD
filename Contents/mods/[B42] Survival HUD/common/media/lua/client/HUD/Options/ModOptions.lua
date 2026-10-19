require "PZAPI/ModOptions";
require "HUD/Core";
require "HUD/Hotbar";

SurvivalHUD = {};
SurvivalHUD.Options = PZAPI.ModOptions:create("SurvivalHUD", "Survival HUD");

local iconSizeCombo = SurvivalHUD.Options:addComboBox("iconSize", getText("UI_optionscreen_NeedsSize"), getText("UI_optionscreen_NeedsSize_tt"));
iconSizeCombo:addItem("48");
iconSizeCombo:addItem("64", true);
iconSizeCombo:addItem("80");

local hotbarSizeCombo = SurvivalHUD.Options:addComboBox("hotbarSize", getText("UI_optionscreen_HotbarSize"), getText("UI_optionscreen_HotbarSize_tt"));
hotbarSizeCombo:addItem("48");
hotbarSizeCombo:addItem("64", true);
hotbarSizeCombo:addItem("80");

SurvivalHUD.Options.apply = function(self)
    local selectedSizes = {48, 64, 80};
    local iconIdx = self:getOption("iconSize"):getValue();
    local iconSize = selectedSizes[iconIdx];

    NeedsUI:setBaseIconSize(iconSize);

    local hotbarIdx = self:getOption("hotbarSize"):getValue();
    local hotbarSize = selectedSizes[hotbarIdx];

    ISHotbar:setBaseSlotSize(hotbarSize);
end

PZAPI.ModOptions:load();
SurvivalHUD.Options:apply();