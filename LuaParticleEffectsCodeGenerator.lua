local LuaParticleEffectsCodeGenerator = {}

-- local bindings
local StringBuilder = StringBuilder
local StringBuilder_clear = StringBuilder.clear
local StringBuilder_append = StringBuilder.append
local StringBuilder_toString = StringBuilder.toString

local variableInstanceNames = {
    [ParticleEffectsType.Flame] = "flame",
    [ParticleEffectsType.Sparks] = "sparks",
    [ParticleEffectsType.Smoke] = "smoke",
}

local particleEffectLuaTypes = {
    [ParticleEffectsType.Flame] = "ac.Particles.Flame",
    [ParticleEffectsType.Sparks] = "ac.Particles.Sparks",
    [ParticleEffectsType.Smoke] = "ac.Particles.Smoke",
}

local generators = {
    ---@param effect ac.Particles.Flame
    [ParticleEffectsType.Flame] = function (effect)
        StringBuilder_append(string.format("\ttemperatureMultiplier = %.2f,", effect.temperatureMultiplier))
        StringBuilder_append(string.format("\tflameIntensity = %.2f,", effect.flameIntensity))
    end,

    ---@param effect ac.Particles.Sparks
    [ParticleEffectsType.Sparks] = function (effect)
        StringBuilder_append(string.format("\tlife = %.2f,", effect.life))
        StringBuilder_append(string.format("\tdirectionSpread = %.2f,", effect.directionSpread))
        StringBuilder_append(string.format("\tpositionSpread = %.2f,", effect.positionSpread))
    end,

    ---@param effect ac.Particles.Smoke
    [ParticleEffectsType.Smoke] = function (effect)
        StringBuilder_append(string.format("\tlife = %.2f,", effect.life))
        StringBuilder_append(string.format("\tcolorConsistency = %.2f,", effect.colorConsistency))
        StringBuilder_append(string.format("\tthickness = %.2f,", effect.thickness))
        StringBuilder_append(string.format("\tspreadK = %.2f,", effect.spreadK))
        StringBuilder_append(string.format("\tgrowK = %.2f,", effect.growK))
        StringBuilder_append(string.format("\ttargetYVelocity = %.2f,", effect.targetYVelocity))
    end,
}

local generators_extraUnderInitialization = {
    ---@param effectWrapper SmokeEffectWrapper
    [ParticleEffectsType.Smoke] = function (effectWrapper)
        local variableInstanceName = variableInstanceNames[ParticleEffectsType.Smoke]

        if effectWrapper.disableCollisions then
            StringBuilder_append(string.format("%s.flags = bit.bor(%s.flags, ac.Particles.SmokeFlags.DisableCollisions)", variableInstanceName, variableInstanceName))
        end

        if effectWrapper.fadeIn then
            StringBuilder_append(string.format("%s.flags = bit.bor(%s.flags, ac.Particles.SmokeFlags.FadeIn)", variableInstanceName, variableInstanceName))
        end
    end,
}

--- Generate lua code for the given particle effect
---@param effectType ParticleEffectsType
---@param effectWrapper FlameEffectWrapper|SparksEffectWrapper|SmokeEffectWrapper
---@return string
LuaParticleEffectsCodeGenerator.generateCode = function(effectType, effectWrapper)
    local effect = effectWrapper.effect
    local position = effectWrapper.getFinalPosition()
    local velocity = effectWrapper.velocity
    local amount = effectWrapper.amount

    StringBuilder_clear()

    local variableInstanceName = variableInstanceNames[effectType]
    StringBuilder_append(string.format("-- Create the %s effect", variableInstanceName))
    StringBuilder_append(string.format("local %s = %s({", variableInstanceName, particleEffectLuaTypes[effectType]))
    StringBuilder_append(string.format("\tcolor = rgbm(%.3f, %.3f, %.3f, %.3f),", effect.color.r, effect.color.g, effect.color.b, effect.color.mult))
    StringBuilder_append(string.format("\tsize = %.2f,", effect.size))

    -- add the effect-specific fields
    generators[effectType](effect)

    StringBuilder_append("})")

    StringBuilder_append('')

    -- check if this effect type has extra code to add under initialization
    local extraCodeUnderInitializationGenerator = generators_extraUnderInitialization[effectType]
    if extraCodeUnderInitializationGenerator ~= nil then
        extraCodeUnderInitializationGenerator(effectWrapper)
        StringBuilder_append('')
    end

    StringBuilder_append(string.format("-- Emit the %s effect in an update loop", variableInstanceName))
    StringBuilder_append('function script.update(dt)')
    StringBuilder_append('\t-- emit(position, velocity, amount)')
    StringBuilder_append(string.format("\t%s:emit(vec3(%.3f, %.3f, %.3f), vec3(%.3f, %.3f, %.3f), %.3f)", variableInstanceName, position.x, position.y, position.z, velocity.x, velocity.y, velocity.z, amount))
    StringBuilder_append('end')

    return StringBuilder_toString()
end

return LuaParticleEffectsCodeGenerator