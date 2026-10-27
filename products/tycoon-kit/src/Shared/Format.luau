--!strict
-- Format: number formatting shared by the HUD, the plot signs and the effects.
-- Installed at: ReplicatedStorage.TycoonKit.Format

local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- 1234567 -> "1,234,567"
function Format.commas(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local sign, digits = s:match("^(-?)(%d+)$")
	if not digits then
		return s -- inf / nan: show as is
	end
	local out = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (sign or "") .. out
end

-- 950 -> "$950", 12500 -> "$12,500", 3400000 -> "$3.40M"
function Format.cash(n: number): string
	if math.abs(n) < 1e6 then
		return "$" .. Format.commas(n)
	end
	local i = math.min(math.floor(math.log10(math.abs(n)) / 3), #SUFFIXES)
	return string.format("$%.2f%s", n / 10 ^ (i * 3), SUFFIXES[i])
end

-- 2 -> "x2", 1.5 -> "x1.5", 2.25 -> "x2.25"
function Format.mult(n: number): string
	if n == math.floor(n) then
		return string.format("x%d", n)
	end
	local s = string.format("%.2f", n):gsub("0+$", "")
	return "x" .. s
end

return Format
