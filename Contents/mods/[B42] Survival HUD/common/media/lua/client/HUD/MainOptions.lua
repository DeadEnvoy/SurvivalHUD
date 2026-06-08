require "HUD/Hotbar";
require "HUD/ModOptions";
require "OptionScreens/MainOptions";

local function createGameOption(name, control)
    local o = {};
    o.name = name;
    o.control = control;
    o.gameOptions = nil;
    o.storedValue = nil;

    function o:toUI()
    end

    function o:apply()
    end

    function o:storeCurrentValue()
        self.storedValue = self.control.selected;
    end

    function o:restoreOriginalValue()
        if self.storedValue then
            self.control.selected = self.storedValue;
        end
    end

    if control.isCombobox then
        control.onChange = function()
            if o.gameOptions then
                o.gameOptions:onChange(o);
            end
        end
        control.target = o;
    end

    return o;
end

local _original_MainOptions_addUIPanel = MainOptions.addUIPanel;
MainOptions.addUIPanel = function(self)
    local sidebarSizeFound = false;
    local moodleSizeFound = false;

    local _original_addCombo = self.addCombo;
    self.addCombo = function(self, x, y, w, h, name, options, selected, target, onchange)
        local combo = _original_addCombo(self, x, y, w, h, name, options, selected, target, onchange);

        if name == getText("UI_optionscreen_MoodleSize") and not moodleSizeFound then
            moodleSizeFound = true;

            local needsSizeCombo = _original_addCombo(self, x, y, w, h, getText("UI_optionscreen_NeedsSize"), {"48", "64", "80"}, 2);
            local needsTooltipMap = {};
            needsTooltipMap["defaultTooltip"] = getText("UI_optionscreen_NeedsSize_tt");
            needsSizeCombo:setToolTipMap(needsTooltipMap);
            local needsOption = createGameOption("SurvivalHUD.NeedsSize", needsSizeCombo);

            function needsOption:toUI()
                local opt = SurvivalHUD.Options:getOption("iconSize");
                self.control.selected = opt.selected or 2;
            end

            function needsOption:apply()
                local opt = SurvivalHUD.Options:getOption("iconSize");
                opt.selected = self.control.selected;
            end

            self.gameOptions:add(needsOption);
        elseif name == getText("UI_optionscreen_SidebarSize") and not sidebarSizeFound and HotbarReskin then
            sidebarSizeFound = true;

            local hotbarSizeCombo = _original_addCombo(self, x, y, w, h, getText("UI_optionscreen_HotbarSize"), {"48", "64", "80"}, 2);
                local hotbarTooltipMap = {};
                hotbarTooltipMap["defaultTooltip"] = getText("UI_optionscreen_HotbarSize_tt");
                hotbarSizeCombo:setToolTipMap(hotbarTooltipMap);
                local hotbarOption = createGameOption("SurvivalHUD.HotbarSize", hotbarSizeCombo);

            function hotbarOption:toUI()
                local opt = SurvivalHUD.Options:getOption("hotbarSize");
                self.control.selected = opt.selected or 2;
            end

            function hotbarOption:apply()
                local opt = SurvivalHUD.Options:getOption("hotbarSize");
                opt.selected = self.control.selected;
            end

            self.gameOptions:add(hotbarOption);
        end

        return combo;
    end

    _original_MainOptions_addUIPanel(self);
    self.addCombo = _original_addCombo;
end