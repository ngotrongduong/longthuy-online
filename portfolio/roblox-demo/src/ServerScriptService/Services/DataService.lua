--!strict
-- DataService: player profiles with a SESSION LOCK, retries and autosave.
--
-- How the session lock works
--   * Load uses UpdateAsync. Inside the transform we look at profile.Lock.
--     If another server (JobId) holds a lock that is younger than SessionLockTimeout,
--     the transform returns nil (= cancel the write) and we retry with backoff.
--     Otherwise we write our own {JobId, Time} lock and take the profile.
--   * Every save is also an UpdateAsync that REFUSES to write if the lock in the store
--     is no longer ours (another server stole a stale lock): we never overwrite newer data.
--   * On leave / shutdown the final save clears the lock in the same write.
--
-- Studio without API access (or an unpublished place) cannot reach DataStores.
-- Then the service falls back to IN-MEMORY profiles. It says so in the output and in the
-- player attribute SaveMode = "Memory"; it never reports a save that did not happen.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

export type Profile = {
	Cash: number,
	Rebirths: number,
	Droppers: number,
	Receipts: { string }, -- PurchaseIds already granted (ProcessReceipt dedupe)
	Version: number,
	Lock: { JobId: string, Time: number }?,
}

local DataService = {}

local profiles: { [Player]: Profile } = {}
local store: GlobalDataStore? = nil
local mode = "Memory" -- "DataStore" | "Memory"
local jobId = (game.JobId ~= "" and game.JobId) or ("studio-" .. tostring(math.random(1e6, 9e6)))

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

-- Retries a DataStore call with exponential backoff. Returns ok, result.
local function withRetries<T>(label: string, attempts: number, fn: () -> T): (boolean, T?)
	local delay = 1
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(string.format("[DataService] %s failed (attempt %d/%d): %s", label, attempt, attempts, tostring(result)))
		if attempt < attempts then
			task.wait(delay)
			delay = math.min(delay * 2, 16)
		end
	end
	return false, nil
end

-- Decide once whether DataStores are reachable.
local function initStore()
	local ok, result = pcall(function()
		local ds = DataStoreService:GetDataStore(Config.DataStoreName)
		ds:GetAsync("__probe") -- throws in Studio when API access is off / place unpublished
		return ds
	end)
	if ok then
		store = result
		mode = "DataStore"
	else
		store = nil
		mode = "Memory"
		warn(
			"[DataService] DataStores unavailable ("
				.. tostring(result)
				.. "). Using IN-MEMORY profiles: progress is NOT saved in this session."
		)
	end
end

function DataService.getMode(): string
	return mode
end

function DataService.get(player: Player): Profile?
	return profiles[player]
end

-- Loads (and locks) a profile. Returns nil if the player must be kicked.
function DataService.load(player: Player): Profile?
	if mode == "Memory" or not store then
		local p = newProfile()
		profiles[player] = p
		player:SetAttribute("SaveMode", "Memory")
		player:SetAttribute("SaveStatus", "Studio: DataStore offline, in-memory fallback")
		return p
	end

	local ds = store :: GlobalDataStore
	local key = keyFor(player)
	local loaded: Profile? = nil

	for attempt = 1, Config.LoadRetries do
		local lockedElsewhere = false
		local ok = withRetries("Load " .. key, 3, function()
			loaded = ds:UpdateAsync(key, function(old: Profile?)
				local p = old or newProfile()
				local lock = p.Lock
				if lock and lock.JobId ~= jobId and os.time() - lock.Time < Config.SessionLockTimeout then
					lockedElsewhere = true
					return nil -- cancel: another server still owns this session
				end
				lockedElsewhere = false
				p.Lock = { JobId = jobId, Time = os.time() }
				return p
			end)
		end)
		if not player.Parent then
			return nil -- left while loading
		end
		if ok and loaded and not lockedElsewhere then
			break
		end
		loaded = nil
		-- The other server usually releases the lock within a few seconds (player rejoining).
		task.wait(2 * attempt)
	end

	if not loaded then
		player:Kick("Your data is still open on another server. Please rejoin in a minute.")
		return nil
	end

	local p = loaded :: Profile
	-- Fill fields added in later versions
	local defaults = newProfile()
	for k, v in pairs(defaults) do
		if (p :: any)[k] == nil then
			(p :: any)[k] = v
		end
	end
	profiles[player] = p
	player:SetAttribute("SaveMode", "DataStore")
	player:SetAttribute("SaveStatus", "Loaded, session locked")
	return p
end

-- Writes the profile only if we still own the lock. release = true clears the lock.
function DataService.save(player: Player, release: boolean?): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	if mode == "Memory" or not store then
		return false -- nothing was written; the caller must not report success
	end
	local ds = store :: GlobalDataStore
	local lostLock = false
	local ok = withRetries("Save " .. keyFor(player), 3, function()
		ds:UpdateAsync(keyFor(player), function(old: Profile?)
			if old and old.Lock and old.Lock.JobId ~= jobId then
				lostLock = true
				return nil -- someone else owns it now: never overwrite their newer data
			end
			local out = table.clone(p)
			out.Lock = if release then nil else { JobId = jobId, Time = os.time() }
			return out
		end)
	end)
	if lostLock then
		warn("[DataService] Lost the session lock for " .. player.Name .. "; save skipped.")
		return false
	end
	if ok and player.Parent then
		player:SetAttribute("SaveStatus", "Saved " .. os.date("!%H:%M:%S") .. " UTC")
	end
	return ok
end

function DataService.release(player: Player)
	if profiles[player] then
		DataService.save(player, true)
		profiles[player] = nil
	end
end

function DataService.start()
	initStore()

	-- Autosave loop (also refreshes the lock timestamp)
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for player in pairs(profiles) do
				task.spawn(DataService.save, player, false)
			end
		end
	end)

	Players.PlayerRemoving:Connect(DataService.release)

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
