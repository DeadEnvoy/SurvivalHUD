# 1.3.1
**UI**
- The sidebar health icon has been restored.
    - The skills icon is now nested and only appears on hover.
    - Oscillation amplitude now scales with the icon size.

# 1.3.0
**UI**
- Added an audibility indicator.
    - There are four detection levels in total:
        1. From 1 to 4 tiles.
        2. From 5 to 8 tiles.
        3. From 9 to 12 tiles.
        4. From 13 tiles and up.
    - The indicator is affected by every sound-producing player action capable of attracting zombies.
        - Any mods that add sounds originating from the player or the tile they occupy are supported.
    - When driving a vehicle, its sounds (horn, engine volume, etc.) also affect the indicator.
- The sidebar has been redesigned.
    - Primary and secondary hand slots are now permanently hidden.
    - Added a "TUTORIAL" button to open the Survival Guide.
        - This is required to balance button placement after the hand slots were removed.
    - The health icon dynamically swapping to the skills icon has been replaced with a permanent one.
        - If you need quick access to the health panel, you can still do so by clicking the corresponding icon (bottom right).
    - The "Client", "Admin" & "War" buttons have been merged into a single expandable button.
- Player status tracking has been improved.
    - Need icons now blink when they reach the critical phase.
    - The health icon (its fill) now pulses when there is any open wound or dirty bandage.
- The hotbar has been extended and polished.
    - Added support for displaying all fluid types.
    - A powered device (flashlight, radio, etc.) held in hand now always shows its charge.
    - A jammed weapon now pulses its condition texture, while a broken one pulses its icon.
    - Equipped weapons now display the amount of ammo loaded in them.
- The Survival Guide window has been reworked.
    - Since a dedicated button now provides permanent access to it, the option to force it open at game start has been removed, along with the related logic.

**MP**
- Fatigue icon is now hidden when "Sleep Needed" is disabled ([#2](https://github.com/DeadEnvoy/SurvivalHUD/issues/2)).
    - The Intoxication icon will be shown in this case to keep the visual layout balanced.

**FIXES**
- Fixed the health panel not opening when clicking on its icon.
- Fixed the hotbar slot tooltip not appearing while an action is being performed.
- Fixed incorrect display of sprite-based items (without an icon) in the hotbar.
- Fixed error spam when [Moodle Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3396446795) is installed ([#3](https://github.com/DeadEnvoy/SurvivalHUD/issues/3)).


**TECHNICAL**
- The compatibility patch for [Mini Health Panel](https://steamcommunity.com/sharedfiles/filedetails/?id=2866258937) has been removed.
    - As a result, the incompatibility with [Mini Health Plus](https://steamcommunity.com/sharedfiles/filedetails/?id=3710913197) has been lifted.
- Added incompatibility with [Clean Hotbar](https://steamcommunity.com/sharedfiles/filedetails/?id=3461263912), [Mattnetic's Heart Health Meter](https://steamcommunity.com/sharedfiles/filedetails/?id=3805849470) and [Tien's Customizable Left Sidebar](https://steamcommunity.com/sharedfiles/filedetails/?id=3811213375).
- 42.18 - 42.19 support has been discontinued.

# 1.2.3
**TECHNICAL**
- The changelog format was updated to Markdown.
- Added incompatibility with [Mini Health Plus](https://steamcommunity.com/sharedfiles/filedetails/?id=3710913197).

# 1.2.2
TECHNICAL:
- Added compatibility with "Moodle Framework".

# 1.2.1
UI:
- Colors for the 3rd and 4th phases have been adjusted.

FIXES:
- Added handling for "NaN" temperature values.
- Fixed missing title coloring in the "FoodEaten" tooltip.

# 1.2.0
UI:
- Hotbar has been redesigned.
- Icon quality has been significantly improved.
- Moodles whose function is performed by the icons are now hidden.
- Added item drag-and-drop functionality between hotbar slots.
- Endurance bar base width has been increased, and percentage display has been removed.
- Clicking on the temperature icon now opens the body temperature panel.
- Clicking on the health icon now opens the character health panel.
- Added hotbar slot and icon base size adjustment option.

BALANCE:
- Renamed "Infection" to "Intoxication".
- Intoxication icon is now only affected by food poisoning and corpse sickness.
- Item condition bar in the hotbar is now only displayed when the item is equipped.

FIXES:
- Fixed text formatting in the "Mini Health Panel" tooltip.
- Minor fixes and improvements.

TECHNICAL:
- "Mini Health Panel" is now optional.
- Added "Mod Manager" & "Moodles In Lua" as a required dependency.
- B42.14 & B42.15 support has been discontinued.

# 1.1.0
- Fixed incorrect tooltip display.
- All localization files migrated to the new format.
- Mini Health Panel is now always shown when aiming with a melee weapon and having at least one muscle strain.
- Fixed Mini Health Panel incorrectly consuming mouse clicks.
- Added display of additional information for multiplayer.
- B41 support has been discontinued.

# 1.0.2
- Mini Health Panel now hides when the character has no injuries.
- Fixed an issue where the cheat status panel did not update after death.

# 1.0.1
- Fixed compatibility with Project Summer Car.

# 1.0.0
- The mod's logic and structure have been completely rewritten.
- All status checks and updates have been optimized.
- The UI is now more responsive and robust in various in-game situations.
- The infection icon now reflects the character's PERCEPTION of being infected (which can be affected by perks or corpse sickness).
- Icons are now moved above the Hotbar/Dashboard if they still overlap it at their minimum size.
- Mini Health Panel has been added as a dependency and integrated into the UI.
- The information displayed in the Mini Health Panel's tooltip has been changed.
- Hovering over the icons while aiming now hides them completely.
- The sidebar's health icon now changes to the skills icon when the player is not injured.
- Numerous other minor fixes and improvements.