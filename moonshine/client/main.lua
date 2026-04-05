local SpawnedProps = {}
local TargetedProps = {}

-- =========================
-- PLACE PROP
-- =========================

RegisterNetEvent('moonshine:placeProp', function(itemName)
	local prop = Config.Props[itemName]
	if not prop then return end

	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local forward = GetEntityForwardVector(ped)

	local spawnCoords = coords + (forward * 1.5)

	RequestModel(prop.model)
	while not HasModelLoaded(prop.model) do Wait(0) end

	local obj = CreateObject(prop.model, spawnCoords.x, spawnCoords.y, spawnCoords.z - 1.0, true, true, true)
	PlaceObjectOnGroundProperly(obj)

	NetworkRegisterEntityAsNetworked(obj)
	SetEntityAsMissionEntity(obj, true, true)

	local netId = NetworkGetNetworkIdFromEntity(obj)

	SpawnedProps[netId] = obj

	if not TargetedProps[netId] then
		TargetedProps[netId] = true

		exports.ox_target:addLocalEntity(obj, {
			{
				label = "Open Controls",
				onSelect = function()
					TriggerServerEvent('moonshine:openUI', netId)
				end
			},
			{
				label = "Open Container",
				onSelect = function()
					TriggerServerEvent('moonshine:openStash', netId)
				end
			},
			{
				label = "Transfer to Still",
				onSelect = function()
					TriggerEvent('moonshine:selectStill', netId)
				end
			},
			{
				label = "Clean",
				onSelect = function()
					TriggerServerEvent('moonshine:clean', netId)
				end
			},
			{
				label = "Pick Up",
				onSelect = function()
					TriggerServerEvent('moonshine:pickup', netId)
				end
			}
		})
	end

	TriggerServerEvent('moonshine:registerProp', netId, itemName, spawnCoords)
end)

-- =========================
-- REMOVE PROP
-- =========================

RegisterNetEvent('moonshine:removeProp', function(netId)
	local entity = SpawnedProps[netId]

	if not entity then
		entity = NetworkGetEntityFromNetworkId(netId)
	end

	if not entity or not DoesEntityExist(entity) then return end

	NetworkRequestControlOfEntity(entity)

	local timeout = 0
	while not NetworkHasControlOfEntity(entity) and timeout < 50 do
		Wait(10)
		timeout += 1
	end

	exports.ox_target:removeLocalEntity(entity)

	SetEntityAsMissionEntity(entity, true, true)
	DeleteEntity(entity)

	SpawnedProps[netId] = nil
	TargetedProps[netId] = nil
end)

-- =========================
-- SELECT STILL
-- =========================

RegisterNetEvent('moonshine:selectStill', function(fromNetId)
	local options = {}

	for netId, entity in pairs(SpawnedProps) do
		if DoesEntityExist(entity) then
			table.insert(options, {
				title = "Still " .. netId,
				onSelect = function()
					TriggerServerEvent('moonshine:transferToStill', fromNetId, netId)
				end
			})
		end
	end

	lib.registerContext({
		id = 'moonshine_still_select',
		title = 'Select Still',
		options = options
	})

	lib.showContext('moonshine_still_select')
end)