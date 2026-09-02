require "OptionScreens/MainOptions";

local function registerSizeOption(self, combo, optionId, pzapiOptionId, tooltipKey)
    local tooltipMap = {};
    tooltipMap["defaultTooltip"] = getText(tooltipKey);
    combo:setToolTipMap(tooltipMap);

    local gameOption = GameOption:new(optionId, combo);

    function gameOption:toUI()
        local opt = SurvivalHUD.Options:getOption(pzapiOptionId);
        self.control.selected = opt.selected or 2;
    end

    function gameOption:apply()
        local opt = SurvivalHUD.Options:getOption(pzapiOptionId);
        opt.selected = self.control.selected;
    end

    self.gameOptions:add(gameOption);
end

local _original_MainOptions_addUIPanel = MainOptions.addUIPanel;
MainOptions.addUIPanel = function(self)
    local sidebarSizeFound = false;
    local moodleSizeFound = false;

    local _original_addCombo = self.addCombo;
    ---@diagnostic disable-next-line: redefined-local
    self.addCombo = function(self, x, y, w, h, name, options, selected, target, onchange)
        local combo = _original_addCombo(self, x, y, w, h, name, options, selected, target, onchange);

        if name == getText("UI_optionscreen_MoodleSize") and not moodleSizeFound then
            moodleSizeFound = true;

            local needsSizeCombo = _original_addCombo(self, x, y, w, h, getText("UI_optionscreen_NeedsSize"), { "48", "64", "80" }, 2);
            registerSizeOption(self, needsSizeCombo, "SurvivalHUD.NeedsSize", "iconSize", "UI_optionscreen_NeedsSize_tt");
        elseif name == getText("UI_optionscreen_SidebarSize") and not sidebarSizeFound and HotbarReskin then
            sidebarSizeFound = true;

            local hotbarSizeCombo = _original_addCombo(self, x, y, w, h, getText("UI_optionscreen_HotbarSize"), { "48", "64", "80" }, 2);
            registerSizeOption(self, hotbarSizeCombo, "SurvivalHUD.HotbarSize", "hotbarSize", "UI_optionscreen_HotbarSize_tt");
        end

        return combo;
    end

    _original_MainOptions_addUIPanel(self);
    self.addCombo = _original_addCombo;
end