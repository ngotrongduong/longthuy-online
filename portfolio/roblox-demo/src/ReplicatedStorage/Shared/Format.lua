--!strict
-- Number formatting shared by HUD, signs and billboards.
local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

function Format.commas(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local sign, int = s:match("^(-?)(%d+)$")
	if not int then
		return s
	end
	int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if int:sub(1, 1) == "," then
		int = int:sub(2)
	end
	return (sign or "") .. int
end

function Format.cash(n: number): string
	if math.abs(n) < 1e6 then
		return "$" .. Format.commas(n)
	end
	local i = math.min(math.floor(math.log10(math.abs(n)) / 3), #SUFFIXES)
	return string.format("$%.2f%s", n / 10 ^ (i * 3), SUFFIXES[i])
end

function Format.mult(n: number): string
	if n == math.floor(n) then
		return string.format("x%d", n)
	end
	return string.format("x%.2g", n)
end

return Format
