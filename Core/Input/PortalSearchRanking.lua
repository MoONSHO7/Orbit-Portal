local _, addon = ...
local ipairs = ipairs
local SCORE_EXACT_SHORT = 5

local Ranking = {}
addon.PortalSearchRanking = Ranking

local function ScoreMatch(data, needle)
	if not data then
		return 0
	end
	local short = data.searchShort
	local name = data.searchName
	local inst = data.searchInst
	local cat = data.searchCategory
	if short == needle then
		return SCORE_EXACT_SHORT
	end
	if short and short:sub(1, #needle) == needle then
		return 4
	end
	if
		(name and name:sub(1, #needle) == needle)
		or (inst and inst:sub(1, #needle) == needle)
		or (cat and cat:sub(1, #needle) == needle)
	then
		return 3
	end
	if short and short:find(needle, 1, true) then
		return 2
	end
	if
		(name and name:find(needle, 1, true))
		or (inst and inst:find(needle, 1, true))
		or (cat and cat:find(needle, 1, true))
	then
		return 1
	end
	return 0
end

function Ranking.Match(portalList, needle)
	if not needle or needle == "" then
		return {}
	end

	local buckets = {}
	for _, item in ipairs(portalList) do
		local score = ScoreMatch(item, needle)
		if score > 0 then
			local bucket = buckets[score]
			if not bucket then
				bucket = {}
				buckets[score] = bucket
			end
			bucket[#bucket + 1] = item
		end
	end

	local matches
	for score = SCORE_EXACT_SHORT, 1, -1 do
		local bucket = buckets[score]
		if bucket then
			if matches then
				for index = 1, #bucket do
					matches[#matches + 1] = bucket[index]
				end
			else
				matches = bucket
			end
		end
	end
	return matches or {}
end
