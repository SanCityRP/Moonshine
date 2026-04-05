Effects = {}

local active = {}

-- =========================
-- HEAT
-- =========================

function Effects.ApplyHeat(id, level)
    if not level then return end

    if level > 95 then
        SetTimecycleModifier("REDMIST_blend")
        SetTimecycleModifierStrength(0.7)
    elseif level > 80 then
        SetTimecycleModifier("hud_def_blur")
        SetTimecycleModifierStrength(0.4)
    elseif level > 65 then
        SetTimecycleModifier("hud_def_blur")
        SetTimecycleModifierStrength(0.2)
    else
        ClearTimecycleModifier()
    end

    active[id] = true
end

-- =========================
-- PRESSURE
-- =========================

function Effects.ApplyPressure(level)
    if not level then return end

    if level > 90 then
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.4)
    elseif level > 70 then
        ShakeGameplayCam("HAND_SHAKE", 0.15)
    elseif level > 50 then
        ShakeGameplayCam("HAND_SHAKE", 0.05)
    end
end

-- =========================
-- EXPLOSION
-- =========================

function Effects.Explode(coords)
    if not coords then return end
    AddExplosion(coords.x, coords.y, coords.z, 2, 1.0, true, false, 1.0)
end

-- =========================
-- CLEAR
-- =========================

function Effects.Clear(id)
    if active[id] then
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
        active[id] = nil
    end
end