local TILES_QUEUE = {}
local MAP_CHUNKS = {}

function WholeMap(cb)
	local step = 0
	local tiles = {}
	for x=0,KAG.GetMapWidth() do
		for y=0,KAG.GetMapHeight() do
			table.insert(tiles, {x=x*8, y=y*8})
			step = step + 1
			if (step > 128) then
				table.insert(MAP_CHUNKS, {tiles=tiles, callback=cb})
				tiles = {}
				step = 0
			end
		end
	end
end

-- @ math.round(num, decimals)
-- @ returns a rounded version of the number <num> with a given number of <decimals>
function math.round(num, idp)
	idp = idp or 2
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

-- @ math.clamp(value, lower, upper)
-- @ returns a clamped version of the number <value> between <lower> and <upper> values
function math.clamp(v, l, u)
    if (l > u) then l, u = u, l end
    return math.max(l, math.min(u, v))
end

-- @ table.indexOf(table, value)
-- @ returns the index of <value> inside <table> or -1 if the value was not found
function table.indexOf(t, o)
	if "table" == type( t ) then
		for i = 1, #t do
			if o == t[i] then
				return i
			end
		end
		return -1
	else
		error("table.indexOf expects table for first argument, " .. type(t) .. " given")
	end
end

-- @ table.extend(
-- @ returns a new table based on the <source> table and extended by the <destination> table
function table.extend(destination, source)
	for k,v in pairs(source) do
		destination[k] = v
	end
	return destination
end

-- @ KAG.PushTile(x, y, tile)
-- @ adds a <tile> to the queue, at <x>:<y> position
function KAG.PushTile(x, y, tile)
	table.insert(TILES_QUEUE, { x = x, y = y, t = tile })
end

-- @ KAG.GetPlayerByPartialName(name)
-- @ returns the first player starting with a specific <name>
function KAG.GetPlayerByPartialName(s)
	if (string.len(s) == 0) then return nil end
	s = string.lower(s)
	for i=1,KAG.GetPlayersCount() do
		local p = KAG.GetPlayerByIndex(i)
		if (string.sub(string.lower(p:GetName()), 1, string.len(s)) == s) then
			return p
		end
	end
	return nil
end

-- @ KAG.GetPlayersByPartialName(name)
-- @ returns a table of players starting with a specific <name>
function KAG.GetPlayersByPartialName(s)
	local r = {}
	if (string.len(s) == 0) then return r end
	s = string.lower(s)
	for i=1,KAG.GetPlayersCount() do
		local p = KAG.GetPlayerByIndex(i)
		if (string.sub(string.lower(p:GetName()), 1, string.len(s)) == s) then
			table.insert(r, p)
		end
	end
	return r
end

-- @ KAG.GetPlayersByFeature(feature)
-- @ returns a table of players with a specific <feature>
function KAG.GetPlayersByFeature(s)
	local r = {}
	for i=1,KAG.GetPlayersCount() do
		local p = KAG.GetPlayerByIndex(i)
		if (p:HasFeature(s)) then
			table.insert(r, p)
		end
	end
	return r
end

-- @ Player.ForcePosition(x, y)
-- @ sets the <x>:<y> position of a player and makes sure that he was teleported on client side
function Player.ForcePosition(self, x, y)
	self:SetNumber("force_position_x", x)
	self:SetNumber("force_position_y", y)
	self:SetPosition(x, y)
end

-- @ Player.IsDead()
-- @ returns whether the player is dead or not, by checking his position and whether he is spectating or not
function Player.IsDead(self)
	return (self:GetTeam() == 200 or (self:GetX() == 0 and self:GetY() == 0))
end

function juxtappUtils_OnInit()
end

function juxtappUtils_OnPlayerInit(player)
	player:SetNumber("force_position_x", -1)
	player:SetNumber("force_position_y", -1)
end

function juxtappUtils_OnServerTick(ticks)
	local p, fpx, fpy
	for i=1,KAG.GetPlayersCount() do
		p = KAG.GetPlayerByIndex(i)
		if (not p:IsDead()) then
			fpx = p:GetNumber("force_position_x")
			fpy = p:GetNumber("force_position_y")
			if (fpx ~= -1 or fpy ~= -1) then
				if (p:GetX() ~= fpx or p:GetY() ~= fpy) then
					KAG.SendMessage("(" .. os.time() .. ") " .. p:GetName() .. "'s position was forced to " .. fpx .. ":" .. fpy)
					p:SetPosition(fpx, fpy)
				else
					p:SetNumber("force_position_x", -1)
					p:SetNumber("force_position_y", -1)
				end
			end
		end
	end
	if (#TILES_QUEUE > 0 and ticks % 1 == 0) then
		for i=1,8 do
			local tile = table.remove(TILES_QUEUE, 1)
			if (tile == nil) then break end
			KAG.SetTile(tile.x, tile.y, tile.t)
		end
		--print(#TILES_QUEUE)
	end
	if (#MAP_CHUNKS > 0 and ticks % 1 == 0) then
		local chunkData = table.remove(MAP_CHUNKS)
		chunkData.callback(chunkData.tiles)
		print(#MAP_CHUNKS .. " chunks left to process")
	end
end