local LuaParticleEffectsCodeGenerator = {}

-- local bindings
local StringBuilder = StringBuilder
local StringBuilder_clear = StringBuilder.clear
local StringBuilder_append = StringBuilder.append
local StringBuilder_toString = StringBuilder.toString

local particleEffectsLuaVariableInstanceNames = {
    [ParticleEffectsType.Flame] = "flame",
    [ParticleEffectsType.Sparks] = "sparks",
    [ParticleEffectsType.Smoke] = "smoke",
}

local particleEffectLuaTypes = {
    [ParticleEffectsType.Flame] = "ac.Particles.Flame",
    [ParticleEffectsType.Sparks] = "ac.Particles.Sparks",
    [ParticleEffectsType.Smoke] = "ac.Particles.Smoke",
}

local generators_extraUnderInitialization = {
    ---@param effectInstance SmokeEffectWrapper
    [ParticleEffectsType.Smoke] = function (effectInstance)
        local variableInstanceName = particleEffectsLuaVariableInstanceNames[ParticleEffectsType.Smoke]

        local flagsWritten = false
        if effectInstance.disableCollisions then
            StringBuilder_append(string.format("%s.flags = bit.bor(%s.flags, ac.Particles.SmokeFlags.DisableCollisions)", variableInstanceName, variableInstanceName))
            flagsWritten = true
        end

        if effectInstance.fadeIn then
            StringBuilder_append(string.format("%s.flags = bit.bor(%s.flags, ac.Particles.SmokeFlags.FadeIn)", variableInstanceName, variableInstanceName))
            flagsWritten = true
        end

        if flagsWritten then
            StringBuilder_append('')
        end
    end,
}

local generateParticleEffectsLua = function(effectType, effectInstance, effectFieldsCallback)
    local effect = effectInstance.effect

    local variableInstanceName = particleEffectsLuaVariableInstanceNames[effectType]
    StringBuilder_append(string.format("-- Create the %s effect", variableInstanceName))
    StringBuilder_append(string.format("local %s = %s({", variableInstanceName, particleEffectLuaTypes[effectType]))
    StringBuilder_append(string.format("\tcolor = rgbm(%.3f, %.3f, %.3f, %.3f),", effect.color.r, effect.color.g, effect.color.b, effect.color.mult))
    StringBuilder_append(string.format("\tsize = %.2f,", effect.size))

    -- call the callback to add effect-specific fields
    effectFieldsCallback()

    StringBuilder_append("})")

    StringBuilder_append('')

    -- check if this effect type has extra code to add under initialization
    local extraCodeUnderInitializationGenerator = generators_extraUnderInitialization[effectType]
    if extraCodeUnderInitializationGenerator ~= nil then
        extraCodeUnderInitializationGenerator(effectInstance)
    end

    local position = effectInstance.getFinalPosition()
    local velocity = effectInstance.velocity
    local amount = effectInstance.amount

    StringBuilder_append(string.format("-- Emit the %s effect in an update loop", variableInstanceName))
    StringBuilder_append('function script.update()')
    StringBuilder_append('\t-- emit(position, velocity, amount)')
    StringBuilder_append(string.format("\t%s:emit(vec3(%.3f, %.3f, %.3f), vec3(%.3f, %.3f, %.3f), %.3f)", variableInstanceName, position.x, position.y, position.z, velocity.x, velocity.y, velocity.z, amount))
    StringBuilder_append('end')
end

local generators = {
    ---@param effectInstance FlameEffectWrapper
    [ParticleEffectsType.Flame] = function (effectInstance)
        generateParticleEffectsLua(ParticleEffectsType.Flame, effectInstance, function()
            local effect = effectInstance.effect
            StringBuilder_append(string.format("\ttemperatureMultiplier = %.2f,", effect.temperatureMultiplier))
            StringBuilder_append(string.format("\tflameIntensity = %.2f,", effect.flameIntensity))
        end)
    end,
    ---@param effectInstance SparksEffectWrapper
    [ParticleEffectsType.Sparks] = function (effectInstance)
        generateParticleEffectsLua(ParticleEffectsType.Sparks, effectInstance, function()
            local effect = effectInstance.effect
            StringBuilder_append(string.format("\tlife = %.2f,", effect.life))
            StringBuilder_append(string.format("\tdirectionSpread = %.2f,", effect.directionSpread))
            StringBuilder_append(string.format("\tpositionSpread = %.2f,", effect.positionSpread))
        end)
    end,
    ---@param effectInstance SmokeEffectWrapper
    [ParticleEffectsType.Smoke] = function (effectInstance)
        generateParticleEffectsLua(ParticleEffectsType.Smoke, effectInstance, function()
            local effect = effectInstance.effect
            StringBuilder_append(string.format("\tlife = %.2f,", effect.life))
            StringBuilder_append(string.format("\tcolorConsistency = %.2f,", effect.colorConsistency))
            StringBuilder_append(string.format("\tthickness = %.2f,", effect.thickness))
            StringBuilder_append(string.format("\tspreadK = %.2f,", effect.spreadK))
            StringBuilder_append(string.format("\tgrowK = %.2f,", effect.growK))
            StringBuilder_append(string.format("\ttargetYVelocity = %.2f,", effect.targetYVelocity))
        end)
    end,
    ---@param effectInstance FireworksWrapper
    [ParticleEffectsType.Fireworks] = function (effectInstance)
            local position = effectInstance.getFinalPosition()
            local intensity = effectInstance.intensity
            local holidayType = effectInstance.holidayType

            StringBuilder_append("-- import the fireworks api: \\assettocorsa\\extension\\internal\\lua-shared\\sim\\fireworks.lua")
            StringBuilder_append("local fireworks = require('shared/sim/fireworks')")
            StringBuilder_append("")
            StringBuilder_append("-- start the fireworks")
            StringBuilder_append(string.format("local fireworksEmitter = fireworks.Emitter(vec3(%.3f, %.3f, %.3f), %.3f, %d)", position.x, position.y, position.z, intensity, holidayType))
            StringBuilder_append("")
            StringBuilder_append("-- stop the fireworks")
            StringBuilder_append("fireworksEmitter:dispose()")
    end
}

--- Generate lua code for the given particle effect
---@param effectType ParticleEffectsType
---@param effectInstance FlameEffectWrapper|SparksEffectWrapper|SmokeEffectWrapper|FireworksWrapper
---@return string
LuaParticleEffectsCodeGenerator.generateCode = function(effectType, effectInstance)
    StringBuilder_clear()

    -- fill up the StringBuilder with the lua code text
    generators[effectType](effectInstance)

    return StringBuilder_toString()
end

return LuaParticleEffectsCodeGenerator