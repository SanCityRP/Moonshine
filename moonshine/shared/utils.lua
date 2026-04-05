Utils = {}

function Utils.Debug(...)
    if Config.Debug then
        print('[MOONSHINE]', ...)
    end
end

function Utils.Clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end