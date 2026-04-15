require "PZAPI/ModOptions";
require "HUD/Core";
require "HUD/Hotbar";

SurvivalHUD.Options = PZAPI.ModOptions:create("SurvivalHUD", "Survival HUD");

local iconSizeCombo = SurvivalHUD.Options:addComboBox("iconSize", getText("UI_optionscreen_NeedsSize"), getText("UI_optionscreen_NeedsSize_tt"));
iconSizeCombo:addItem("48");
iconSizeCombo:addItem("64", true);
iconSizeCombo:addItem("80");

if HotbarReskin then
    local hotbarSizeCombo = SurvivalHUD.Options:addComboBox("hotbarSize", getText("UI_optionscreen_HotbarSize"), getText("UI_optionscreen_HotbarSize_tt"));
    hotbarSizeCombo:addItem("48");
    hotbarSizeCombo:addItem("64", true);
    hotbarSizeCombo:addItem("80");
    SurvivalHUD.Options:addTickBox("showHandSlots", getText("UI_optionscreen_ShowHandSlots"), true);
end

SurvivalHUD.Options.apply = function(self)
	local selectedSizes = {48, 64, 80};
	local iconIdx = self:getOption("iconSize"):getValue();
	local iconSize = selectedSizes[iconIdx];

	SurvivalHUD.BaseIconSize = iconSize;
	SurvivalHUD.IconSize = iconSize;

	if SurvivalHUD.instance then
		SurvivalHUD.instance.layoutDirty = true;
	end

	if EnduranceUI.instance then
		EnduranceUI.instance.layoutDirty = true;
	end

    if HotbarReskin then
        local hotbarIdx = self:getOption("hotbarSize"):getValue();
        local hotbarSize = selectedSizes[hotbarIdx];

		HotbarReskin.HOTBAR_SIZE = hotbarSize;
		HotbarReskin.BASE_HOTBAR_SIZE = hotbarSize;
        
        SurvivalHUD.ShowHandSlots = self:getOption("showHandSlots"):getValue();
	end
end

if PZAPI.ModOptions.load then
	PZAPI.ModOptions:load();
end

SurvivalHUD.Options:apply();