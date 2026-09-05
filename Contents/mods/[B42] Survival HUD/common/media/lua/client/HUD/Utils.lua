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

function Utils.clamp100(x)
	return math.max(0, math.min(100, x));
end

return Utils