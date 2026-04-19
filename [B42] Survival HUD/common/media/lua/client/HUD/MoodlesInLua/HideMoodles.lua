require "MoodlesIn";
require "MF_ISMoodle";

local HIDDEN_MOODLES = {
	[MoodleType.HUNGRY] = true,
	[MoodleType.ENDURANCE] = true,
	[MoodleType.THIRST] = true,
	[MoodleType.SICK] = true,
	[MoodleType.INJURED] = true,
	[MoodleType.TIRED] = true,
	[MoodleType.HYPERTHERMIA] = true,
	[MoodleType.HYPOTHERMIA] = true,
	[MoodleType.FOOD_EATEN] = true,
};

if ISMoodlesInLua and ISMoodlesInLua.render then
	ISMoodlesInLua.render = function(self)
		if not self.active then
			return;
		end

		local player = getPlayer();

		if not player or not player:getMoodles() then
			return;
		end

		local moodles = player:getMoodles();
		local moodleSize = self:getMoodleSize();
		local x = getPlayerScreenLeft(self.playerNum) + getPlayerScreenWidth(self.playerNum) - 10 - moodleSize;
		local y = getPlayerScreenTop(self.playerNum) + 120;

		x = x + self.options.moodleOffsetX;
		y = y + self.options.moodleOffsetY;

		local moodlesValuesForType = Registries.MOODLE_TYPE:values();
		local numMoodles = moodlesValuesForType:size();

		for moodleId = 0, numMoodles - 1 do
			local moodleType = moodlesValuesForType:get(moodleId);
			local moodleTranslationName = moodleType:getTranslationName();

			if not HIDDEN_MOODLES[moodleType] then
				local moodleLevel = moodles:getMoodleLevel(moodleType);
				local goodBadNeutralId = moodles:getGoodBadNeutral(moodleType);

				if moodleLevel ~= 0 and moodleType ~= MoodleType.FOOD_EATEN or moodleLevel >= 3 then
					local deltaTime = UIManager.getMillisSinceLastUpdate() / 1000;

					local prevLevel = self.previousMoodleLevels[tostring(moodleType)] or 0;
					self.previousMoodleLevels[tostring(moodleType)] = moodleLevel;

					local baseY = y;

					if moodleLevel ~= prevLevel and moodleLevel >= 1 then
						self.moodleOscillations[tostring(moodleType)] = 1;
					end

					local oscillationOffset = 0;
					local oscillationDeltaTime = deltaTime * 33.3333;

					if not oscillationDeltaTime or oscillationDeltaTime <= 0 then
						oscillationDeltaTime = 1;
					end

					local moodleOscillation = self.moodleOscillations[tostring(moodleType)] or 0;

					if moodleOscillation > 0 then
						self.moodleOscillations[tostring(moodleType)] = moodleOscillation - moodleOscillation * (self.OscilatorDecelerator) / oscillationDeltaTime;

						if self.moodleOscillations[tostring(moodleType)] <= 0.015 then
							self.moodleOscillations[tostring(moodleType)] = 0;
						end

						if self.moodleOscillations[tostring(moodleType)] > 0 then
							local OscilatorStep = self.moodleOscillationsSteps[tostring(moodleType)] or 0;
							OscilatorStep = OscilatorStep + self.OscilatorRate / oscillationDeltaTime;
							self.moodleOscillationsSteps[tostring(moodleType)] = OscilatorStep;

							local Oscilator = math.sin(OscilatorStep);
							oscillationOffset = Oscilator * self.OscilatorScalar * self.moodleOscillations[tostring(moodleType)] * 2;
						end
					end

					if prevLevel == 0 and moodleLevel == 1 then
						self.moodleAnimations[tostring(moodleType)] = {
							progress = 0,
							startY = baseY,
							targetY = 10000
						};
					end

					local anim = self.moodleAnimations[tostring(moodleType)];

					if anim then
						anim.progress = math.min(anim.progress + (deltaTime * 0.5), 1);
						local t = 1 - (1 - anim.progress) ^ 3;
						local animY = anim.targetY + (anim.startY - anim.targetY) * t;

						if anim.progress >= 1 then
							self.moodleAnimations[tostring(moodleType)] = nil;
							y = baseY;
						else
							y = animY;
						end
					end

					local borderTexturePath = self:getBorderTexturePath(goodBadNeutralId, moodleLevel);
					local borderTexture = self:getTexture(borderTexturePath);

					local iconTexturePath = self:getIconTexturePath(moodleTranslationName);
					local iconTexture = self:getTexture(iconTexturePath);

					if borderTexture and iconTexture then
						local realBorderWidth = borderTexture:getWidth();
						local realBorderHeight = borderTexture:getHeight();
						local scaleFactor = moodleSize / 128;

						local scaledBorderWidth = realBorderWidth * scaleFactor;
						local scaledBorderHeight = realBorderHeight * scaleFactor;

						local iconOffsetX = math.floor(self.options.iconOffsetX * scaleFactor);
						local iconOffsetY = math.floor(self.options.iconOffsetY * scaleFactor);

						UIManager.DrawTexture(borderTexture, x + oscillationOffset, y, scaledBorderWidth, scaledBorderHeight, self.options.moodleAlpha);
						UIManager.DrawTexture(iconTexture, x + iconOffsetX + oscillationOffset, y + iconOffsetY, moodleSize, moodleSize, self.options.moodleAlpha);
					end

					local mouseX, mouseY = getMouseX(), getMouseY();

					if mouseX >= x and mouseX <= x + moodleSize and mouseY >= y and mouseY <= y + moodleSize then
						self:drawMoodleTooltip(moodles, moodleType, x, y);
					end

					y = baseY + self.options.moodlesDistance + moodleSize;
				end
			end
		end
	end
end

if MF and MF.ISMoodle then
	function MF.ISMoodle:getXYPosition()
		local size = MF.getSize();
		if size ~= self.width then
			self:setWidth(size);
			self:updateTextures(size);
		end

		local x = getPlayerScreenLeft(self.playerNum) + getPlayerScreenWidth(self.playerNum) - MF.xOffset - self:getWidth();
		local y = getPlayerScreenTop(self.playerNum) + MF.yOffset;
		local distY = 10 + MF.defaultWidth * MF.scale;

		if self.disable then
			return x, y;
		end

		if self:getLevel() ~= 0 then
			local moodlesValuesForType = Registries.MOODLE_TYPE:values();
			local numMoodles = moodlesValuesForType:size();

			for i = 0, numMoodles - 1 do
				local moodleType = moodlesValuesForType:get(i);

				if not HIDDEN_MOODLES[moodleType] then
					local moodleLevel = self.char:getMoodles():getMoodleLevel(moodleType);
					if moodleLevel ~= 0 and moodleType ~= MoodleType.FoodEaten or moodleLevel >= 3 then
						y = y + distY;
					end
				end
			end

			local aiteronMM = self.char:getModData().MoodleManager;
			if aiteronMM and aiteronMM.moodles then
				for _, moodleObj in pairs(aiteronMM.moodles) do
					if moodleObj.getLevel then
						local lvl = moodleObj:getLevel();
						if lvl > 0 then
							y = y + distY;
						end
					end
				end
			end

			for k, v in pairs(self.char:getModData().Moodles) do
				if k == self.name then
					break;
				else
					if v.Level ~= 0 then
						y = y + distY;
					end
				end
			end
		end

		return x, y;
	end
end