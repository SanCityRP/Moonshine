RegisterNetEvent('moonshine:ui', function(data)
    SetNuiFocus(true, true)

    SendNUIMessage({
        type = "open",
        id = data.id,
        stage = data.stage
    })
end)

RegisterNetEvent('moonshine:updateUI', function(data)
    SendNUIMessage({
        type = "update",
        stage = data.stage,
        hint = data.hint,
        temp = data.temp,
        progress = data.progress
    })
end)

RegisterNUICallback('control', function(data, cb)
    TriggerServerEvent('moonshine:updateControl', data.id, data.type, data.value)
    cb({})
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)

    SendNUIMessage({
        type = "close"
    })

    TriggerServerEvent('moonshine:closeUI', data.id)

    cb({})
end)