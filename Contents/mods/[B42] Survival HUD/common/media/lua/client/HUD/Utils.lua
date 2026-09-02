local Utils = {};

Utils.CollisionSizes = { 80, 64, 48 };

Utils.SeparatorConfig = {
    [48] = { texSize = 32, renderSize = 24 },
    [64] = { texSize = 32, renderSize = 32 },
    [80] = { texSize = 48, renderSize = 40 },
};

function Utils.getNextSmallerSize(sizes, currentSize)
	local found = false;
	for _, size in ipairs(sizes) do
		if found then return size; end
		if size == currentSize then found = true; end
	end
	return nil;
end

function Utils.layoutHotbar(hotbar)
	local count = math.max(#hotbar.availableSlot, 1);
	local w = HotbarReskin.calcTotalWidth(count);
	local h = HotbarReskin.getHeight();
	hotbar:setWidth(w);
	hotbar:setHeight(h);
	local screenW = getCore():getScreenWidth();
	local screenH = getCore():getScreenHeight();
	hotbar:setX(math.floor((screenW - w) / 2));
	hotbar:setY(screenH - h - 15);
end

function Utils.clamp100(x)
	return math.max(0, math.min(100, x));
end

return Utils