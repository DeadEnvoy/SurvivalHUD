local Utils = {};

Utils.CollisionSizes = { 80, 64, 48 };

Utils.SeparatorConfig = {
    [80] = 40,
    [64] = 32,
    [48] = 24,
};

function Utils.getNextSmallerSize(sizes, currentSize)
	local found = false;
	for _, size in ipairs(sizes) do
		if found then return size; end
		if size == currentSize then found = true; end
	end
	return nil;
end

function Utils.clamp100(x)
	return math.max(0, math.min(100, x));
end

function Utils.getPackTexture(path)
	return getTexture("SurvivalHUD_" .. path:gsub("^media/", ""):gsub("%.png$", ""):gsub("[/%s]", "_"));
end

return Utils;