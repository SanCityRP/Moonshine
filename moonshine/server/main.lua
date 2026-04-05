local QBX = exports.qbx_core

Moonshine = {}
Moonshine.Batches = {}
Moonshine.Entities = {}

-- =========================
-- STASH
-- =========================

local function StashName(id)
	return "moonshine_" .. id
end

local function RegisterStash(id, prop)
	local label = Config.Props[prop] and Config.Props[prop].label or "Moonshine"

	exports.ox_inventory:RegisterStash(
		StashName(id),
		label,
		Config.StashSlots,
		Config.StashWeight
	)
end

-- =========================
-- LOAD
-- =========================

CreateThread(function()
	local results = MySQL.query.await('SELECT * FROM moonshine_batches')

	for _, row in pairs(results) do
		local data = json.decode(row.data)

		if data then
			data.control = type(data.control) == "table" and data.control or { heat = 0.0, flow = 0.0 }
			data.modifiers = data.modifiers or {}
			data.state = data.state or { temp = 20.0, pressure = 0.0, quality = 0.0 }
			data.timing = data.timing or {}
			data.timing.lastSave = data.timing.lastSave or os.time()
			data.flags = data.flags or { failed = false }
			data.viewers = data.viewers or {}

			Moonshine.Batches[row.id] = data
			Moonshine.Entities[data.entity] = row.id

			RegisterStash(row.id, data.prop)
		end
	end
end)

-- =========================
-- REGISTER PROP
-- =========================

RegisterNetEvent('moonshine:registerProp', function(netId, prop, coords)
	local src = source
	local player = QBX:GetPlayer(src)
	if not player then return end

	if Moonshine.Entities[netId] then return end

	local batch = {
		owner = player.PlayerData.citizenid,
		source = src,
		prop = prop,
		entity = netId,
		coords = coords,

		stage = "mash",
		phase = "idle",
		recipe = "basic_shine",

		state = { temp = 20.0, pressure = 0.0, quality = 0.0 },
		control = { heat = 0.0, flow = 0.0 },
		progress = 0,
		modifiers = {},
		viewers = {},

		timing = {
			started = os.time(),
			passiveUntil = 0,
			lastSave = os.time()
		},

		flags = { failed = false }
	}

	local id = Database.Create(batch)
	batch.id = id

	Moonshine.Batches[id] = batch
	Moonshine.Entities[netId] = id

	RegisterStash(id, prop)
end)

-- =========================
-- GET BATCH
-- =========================

local function GetBatchFromEntity(netId)
	local id = Moonshine.Entities[netId]
	if not id then return nil end
	return Moonshine.Batches[id], id
end

-- =========================
-- UI
-- =========================

RegisterNetEvent('moonshine:openUI', function(netId)
	local src = source
	local batch, id = GetBatchFromEntity(netId)
	if not batch then return end

	batch.viewers[src] = true

	TriggerClientEvent('moonshine:ui', src, {
		id = id,
		stage = batch.stage
	})
end)

RegisterNetEvent('moonshine:closeUI', function(id)
	local src = source
	local batch = Moonshine.Batches[id]
	if not batch then return end

	batch.viewers[src] = nil
end)

-- =========================
-- CONTROL
-- =========================

RegisterNetEvent('moonshine:updateControl', function(id, controlType, value)
	local batch = Moonshine.Batches[id]
	if not batch then return end

	batch.control[controlType] = value
end)

-- =========================
-- START
-- =========================

RegisterNetEvent('moonshine:startProcessById', function(id)
	local batch = Moonshine.Batches[id]
	if not batch then return end

	if batch.phase ~= "idle" then return end

	batch.phase = "active"
	batch.progress = 0
end)

-- =========================
-- OPEN STASH (LOCKED)
-- =========================

RegisterNetEvent('moonshine:openStash', function(netId)
	local src = source
	local batch, id = GetBatchFromEntity(netId)
	if not batch then return end

	if batch.phase == "active" then
		TriggerClientEvent('ox_lib:notify', src, {
			description = "Cannot access while processing",
			type = "error"
		})
		return
	end

	TriggerClientEvent('ox_inventory:openInventory', src, 'stash', StashName(id))
end)

-- =========================
-- CLEAN
-- =========================

RegisterNetEvent('moonshine:clean', function(netId)
	local src = source
	local batch, id = GetBatchFromEntity(netId)
	if not batch then return end

	local inv = exports.ox_inventory:Inventory(StashName(id))

	if inv and inv.items and next(inv.items) then
		TriggerClientEvent('ox_lib:notify', src, {
			description = "Empty first",
			type = "error"
		})
		return
	end

	batch.stage = "mash"
	batch.phase = "idle"
	batch.progress = 0
	batch.state = { temp = 20.0, pressure = 0.0, quality = 0.0 }
	batch.modifiers = {}
	batch.flags.failed = false

	Database.Update(id, batch)
end)

-- =========================
-- TRANSFER TO STILL
-- =========================

RegisterNetEvent('moonshine:transferToStill', function(fromNetId, toNetId)
	local mash, mashId = GetBatchFromEntity(fromNetId)
	local still, stillId = GetBatchFromEntity(toNetId)

	if not mash or not still then return end
	if mash.stage ~= "ready" then return end
	if still.prop ~= "still" then return end
	if still.stage ~= "mash" then return end

	still.stage = "distill"
	still.phase = "idle"
	still.progress = 0
	still.recipe = mash.recipe

	still.modifiers = {
		tempSweet = math.random(70, 85),
		flowSweet = math.random(30, 70) / 100
	}

	mash.stage = "done"

	Database.Update(stillId, still)
	Database.Update(mashId, mash)
end)

-- =========================
-- TICK
-- =========================

CreateThread(function()
	while true do
		Wait(Config.TickRate)

		for id, batch in pairs(Moonshine.Batches) do
			local recipe = Config.Recipes[batch.recipe]
			if not recipe then goto continue end

			local heat = batch.control.heat or 0.0
			local flow = batch.control.flow or 0.0
			local hint = nil

			-- =========================
			-- MASH
			-- =========================

			if batch.stage == "mash" then
				if batch.phase ~= "active" then
					hint = "Idle..."
					goto send
				end

				local min = recipe.mash.minTemp or 60
				local max = recipe.mash.maxTemp or 75

				batch.state.temp = (batch.state.temp or 20.0) + (heat * 4.0)
				batch.state.temp = batch.state.temp - 0.5

				if batch.state.temp < 0 then batch.state.temp = 0 end
				if batch.state.temp > 120 then batch.state.temp = 120 end

				if batch.state.temp < min then
					hint = "Too cold..."
				elseif batch.state.temp > max then
					hint = "Too hot..."
				else
					hint = "Perfect"
					batch.progress = (batch.progress or 0) + 2
				end

				if batch.progress >= (recipe.mash.cookTime or 100) then
					batch.stage = "ferment"
					batch.progress = 0
					batch.timing.passiveUntil = os.time() + 600

					Database.Update(id, batch)
				end
			end

			-- =========================
			-- FERMENT
			-- =========================

			if batch.stage == "ferment" then
				if os.time() >= (batch.timing.passiveUntil or 0) then
					batch.stage = "ready"
					Database.Update(id, batch)
				else
					hint = "Fermenting..."
				end
			end

			-- =========================
			-- DISTILL (ONLY STILLS)
			-- =========================

			if batch.stage == "distill" and batch.prop == "still" then
				batch.state.temp = (batch.state.temp or 20.0) + (heat * 2.0)

				local sweetTemp = batch.modifiers.tempSweet or 80
				local sweetFlow = batch.modifiers.flowSweet or 0.5

				local tempDiff = math.abs(batch.state.temp - sweetTemp)
				local flowDiff = math.abs(flow - sweetFlow)

				if tempDiff < 5 and flowDiff < 0.1 then
					hint = "Perfect run"
					batch.progress = (batch.progress or 0) + 3
					batch.state.quality = (batch.state.quality or 0) + 2

				elseif tempDiff < 10 then
					hint = "Slightly off"
					batch.progress = (batch.progress or 0) + 1.5

				else
					hint = "Bad run"
					batch.progress = (batch.progress or 0) + 0.5
					batch.state.quality = (batch.state.quality or 0) - 1
				end

				if batch.progress >= 120 then
					if batch.flags and batch.flags.rewarded then
						goto send
					end

					batch.stage = "done"
					batch.flags = batch.flags or {}
					batch.flags.rewarded = true

					local player = QBX:GetPlayerByCitizenId(batch.owner)

					if player and player.PlayerData then
						local targetSrc = player.PlayerData.source

						if targetSrc and type(targetSrc) == "number" then
							local yield = recipe.output.baseYield or 1
							local baseQuality = recipe.output.baseQuality or 0
							local quality = math.floor(baseQuality + (batch.state.quality or 0))

							local success = exports.ox_inventory:AddItem(targetSrc, recipe.output.item, yield, {
								quality = quality,
								batch = id
							})

							if not success then
								print("[MOONSHINE] AddItem failed:", targetSrc)
							end
						else
							print("[MOONSHINE] Invalid source for:", batch.owner)
						end
					else
						print("[MOONSHINE] Player missing for:", batch.owner)
					end

					Database.Update(id, batch)
				end
			end

			-- =========================
			-- UI UPDATE
			-- =========================

			::send::

			for viewer, _ in pairs(batch.viewers or {}) do
				TriggerClientEvent('moonshine:updateUI', viewer, {
					id = id,
					stage = batch.stage,
					hint = hint,
					temp = math.floor(batch.state.temp or 0),
					progress = math.floor(batch.progress or 0)
				})
			end

			-- =========================
			-- SAVE
			-- =========================

			if os.time() - (batch.timing.lastSave or 0) >= 15 then
				batch.timing.lastSave = os.time()
				Database.Update(id, batch)
			end

			::continue::
		end
	end
end)


-- =========================
-- USABLE ITEMS
-- =========================

CreateThread(function()
	Wait(2000)

	for name, _ in pairs(Config.Props) do
		print("[MOONSHINE] Registering usable:", name)

		exports.qbx_core:CreateUseableItem(name, function(source, item)
			if not item or item.name ~= name then return end

			print("[MOONSHINE] Using item:", name, "from", source)

			local removed = exports.ox_inventory:RemoveItem(source, name, 1)

			if not removed then
				print("[MOONSHINE] Failed to remove item:", name)
				return
			end

			TriggerClientEvent('moonshine:placeProp', source, name)
		end)
	end
end)