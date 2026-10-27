--!strict
-- DataService: player profiles saved with DataStoreService, protected by a SESSION LOCK.
-- Installed at: ServerScriptService.TycoonKit.DataService
--
-- Why a session lock: when a player hops servers quickly, the old server may still be
-- saving while the new one loads. Without a lock the old save can overwrite newer data.
--
-- How it works
--   * load(): UpdateAsync on the player's key. Inside the transform we read profile.Lock.
--     If ANOTHER server (JobId) holds a lock younger than the timeout, we cancel the write
--     (return nil) and retry with a growing wait. Otherwise we write our own
--     { JobId, Time } lock and take the profile.
--   * save(): also UpdateAsync, and it REFUSES to write if the lock in the store is no
--     longer ours. We never overwrite data another server now owns.
--   * Autosave every Config.AutosaveSeconds (this also refreshes the lock time).
--   * release(): the final save on leave or shutdown clears the lock in the same write.
--   * game:BindToClose waits (bounded) for the final saves when a server shuts down.
--   * Every DataStore call is retried with exponential backoff (1, 2, 4, 8 s ...).
--
-- Studio: without "Enable Studio Access to API Services" (or in an unpublished place)
-- DataStores cannot be reached. With Config.StudioMemoryFallback the kit then uses
-- IN-MEMORY profiles, prints one clear warning and sets the player attribute
-- SaveMode = "Memory". It never reports a save that did not happen.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("TycoonKit"):WaitForChild("Config"))

export type Profile = {
	Cash: number,
	Rebirths: number,
	Droppers: number,
	Receipts: { string }, -- developer-product PurchaseIds already granted
	Version: number,
	Lock: { JobId: string, Time: number }?,
}

local DataService = {}

local profiles: { [Player]: Profile } = {}
local store: GlobalDataStore? = nil
local mode = "DataStore" -- "DataStore" | "Memory"
local jobId = if game.JobId ~= "" then game.JobId else ("studio-" .. tostring(math.random(1e6, 9e6)))
local lockTimeout = math.max(Config.SessionLockTimeout, Config.AutosaveSeconds * 3)

local function newProfile(): Profile
	return {
		Cash = Config.StartCash,
		Rebirths = 0,
		Droppers = 1,
		Receipts = {},
		Version = 1,
		Lock = nil,
	}
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

-- Repairs a loaded profile: fills fields added in later versions and fixes bad types,
-- so a hand-edited or old entry can never break the game.
local function sanitize(raw: any): Profile
	local p = newProfile()
	if type(raw) ~= "table" then
		return p
	end
	if type(raw.Cash) == "number" and raw.Cash == raw.Cash then
		p.Cash = math.max(0, raw.Cash)
	end
	if type(raw.Rebirths) == "number" then
		p.Rebirths = math.max(0, math.floor(raw.Rebirths))
	end
	if type(raw.Droppers) == "number" then
		p.Droppers = math.clamp(math.floor(raw.Droppers), 1, Config.MaxDroppers)
	end
	if type(raw.Receipts) == "table" then
		for _, id in ipairs(raw.Receipts) do
			if type(id) == "string" then
				table.insert(p.Receipts, id)
			end
		end
	end
	local lock = raw.Lock
	if type(lock) == "table" and type(lock.JobId) == "string" and type(lock.Time) == "number" then
		p.Lock = { JobId = lock.JobId, Time = lock.Time }
	end
	return p
end

-- Runs fn with retries and exponential backoff. Returns ok, result.
local function withRetries<T>(label: string, attempts: number, fn: () -> T): (boolean, T?)
	local delay = 1
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(string.format("[TycoonKit] %s failed (try %d/%d): %s", label, attempt, attempts, tostring(result)))
		if attempt < attempts then
			task.wait(delay)
			delay = math.min(delay * 2, 16)
		end
	end
	return false, nil
end

-- Decides once whether DataStores are reachable.
local function initStore()
	local ok, result = pcall(function()
		local ds = DataStoreService:GetDataStore(Config.DataStoreName)
		if RunService:IsStudio() then
			ds:GetAsync("__probe") -- throws in Studio when API access is off
		end
		return ds
	end)
	if ok then
		store = result
		mode = "DataStore"
		return
	end
	if RunService:IsStudio() and Config.StudioMemoryFallback then
		store = nil
		mode = "Memory"
		warn(
			"[TycoonKit] DataStores are not available in this Studio session ("
				.. tostring(result)
				.. "). Using IN-MEMORY profiles: progress is NOT saved. To test saving: publish the place, then "
				.. "Game Settings > Security > Enable Studio Access to API Services."
		)
	else
		-- Live server: GetDataStore practically never fails; keep DataStore mode so every
		-- load is retried and a player is asked to rejoin rather than playing unsaved.
		warn("[TycoonKit] GetDataStore failed: " .. tostring(result))
		store = nil
		mode = "DataStore"
	end
end

function DataService.getMode(): string
	return mode
end

function DataService.get(player: Player): Profile?
	return profiles[player]
end

-- Loads and locks the profile. Returns nil when the player was kicked or left.
function DataService.load(player: Player): Profile?
	if mode == "Memory" then
		local p = newProfile()
		profiles[player] = p
		player:SetAttribute("SaveMode", "Memory")
		player:SetAttribute("SaveStatus", "Studio test: not saved")
		return p
	end

	if not store then
		pcall(function()
			store = DataStoreService:GetDataStore(Config.DataStoreName)
		end)
	end
	local ds = store
	local key = keyFor(player)
	local loaded: Profile? = nil

	if ds then
		for attempt = 1, Config.LoadRetries do
			local lockedElsewhere = false
			local ok, result = withRetries("Load " .. key, 3, function()
				return ds:UpdateAsync(key, function(old: any)
					local p = sanitize(old)
					local lock = p.Lock
					if lock and lock.JobId ~= jobId and os.time() - (lock.Time or 0) < lockTimeout then
						lockedElsewhere = true
						return nil -- cancel: another server still owns this session
					end
					lockedElsewhere = false
					p.Lock = { JobId = jobId, Time = os.time() }
					return p
				end)
			end)
			if not player.Parent then
				return nil -- left while loading (the lock, if taken, times out on its own)
			end
			if ok and result and not lockedElsewhere then
				loaded = sanitize(result)
				break
			end
			-- Usually the other server releases the lock within seconds (a quick rejoin).
			task.wait(2 * attempt)
		end
	end

	if not loaded then
		player:Kick("Your saved data could not be opened right now. Please rejoin in a minute.")
		return nil
	end

	profiles[player] = loaded
	player:SetAttribute("SaveMode", "DataStore")
	player:SetAttribute("SaveStatus", "Loaded")
	return loaded
end

-- Writes profile p of player, only while we still own the lock. release = true clears
-- the lock. Returns true only when the data really reached the DataStore.
local function writeProfile(player: Player, p: Profile, release: boolean?): boolean
	if mode == "Memory" or not store then
		return false
	end
	local ds = store :: GlobalDataStore
	local lostLock = false
	local ok = withRetries("Save " .. keyFor(player), 3, function()
		ds:UpdateAsync(keyFor(player), function(old: any)
			if type(old) == "table" and type(old.Lock) == "table" and old.Lock.JobId ~= jobId then
				lostLock = true
				return nil -- another server owns it now: never overwrite its newer data
			end
			lostLock = false
			local out = table.clone(p)
			out.Lock = if release then nil else { JobId = jobId, Time = os.time() }
			return out
		end)
	end)
	if lostLock then
		warn("[TycoonKit] Session lock for " .. player.Name .. " is held by another server; save skipped.")
		return false
	end
	if ok and player.Parent then
		player:SetAttribute("SaveStatus", "Saved " .. os.date("!%H:%M") .. " UTC")
	end
	return ok
end

-- Saves the loaded profile of a player who is still in the game (autosave, purchases).
function DataService.save(player: Player): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	return writeProfile(player, p, false)
end

-- Final save + unlock, then forget the profile. Called on PlayerRemoving and on
-- shutdown; the profile is taken out first so the two can never both save it.
function DataService.release(player: Player)
	local p = profiles[player]
	if not p then
		return
	end
	profiles[player] = nil
	writeProfile(player, p, true)
end

function DataService.start()
	initStore()

	-- Autosave loop (also refreshes the lock time so other servers see it is alive)
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for player in pairs(profiles) do
				task.spawn(DataService.save, player)
			end
		end
	end)

	-- Server shutdown: save everyone, wait at most ~25 s (Roblox allows 30).
	game:BindToClose(function()
		if mode == "Memory" then
			return
		end
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				DataService.release(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + (if RunService:IsStudio() then 5 else 25)
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
