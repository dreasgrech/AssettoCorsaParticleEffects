local LuaParticleEffectsCodeGenerator = {}

-- local bindings
local MathOperations_splitVelocity = MathOperations.splitVelocity
local StringBuilder = StringBuilder
local StringBuilder_clear = StringBuilder.clear
local StringBuilder_append = StringBuilder.append
local StringBuilder_toString = StringBuilder.toString

local generators = {
    ---@param effect ac.Particles.Flame
    ---@param position vec3
    ---@param velocity vec3
    ---@param amount number
    [ParticleEffectsType.Flame] = function (effect, position, velocity, amount)
        StringBuilder_append(string.format("\ttemperatureMultiplier = %.2f", effect.temperatureMultiplier))
        StringBuilder_append(string.format("\tflameIntensity = %.2f", effect.flameIntensity))
    end,

    ---@param effect ac.Particles.Sparks
    ---@param position vec3
    ---@param velocity vec3
    ---@param amount number
    [ParticleEffectsType.Sparks] = function (effect, position, velocity, amount)
        StringBuilder_append(string.format("\tlife = %.2f", effect.life))
        StringBuilder_append(string.format("\tdirectionSpread = %.2f", effect.directionSpread))
        StringBuilder_append(string.format("\tpositionSpread = %.2f", effect.positionSpread))
    end,

    ---@param effect ac.Particles.Smoke
    ---@param position vec3
    ---@param velocity vec3
    ---@param amount number
    [ParticleEffectsType.Smoke] = function (effect, position, velocity, amount)
        StringBuilder_append(string.format("\tlife = %.2f", effect.life))
        StringBuilder_append(string.format("\tcolorConsistency = %.2f", effect.colorConsistency))
        StringBuilder_append(string.format("\tthickness = %.2f", effect.thickness))
        StringBuilder_append(string.format("\tspreadK = %.2f", effect.spreadK))
        StringBuilder_append(string.format("\tgrowK = %.2f", effect.growK))
        StringBuilder_append(string.format("\ttargetYVelocity = %.2f", effect.targetYVelocity))
    end,
}

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

--- Generate lua code for the given particle effect
---@param effectType ParticleEffectsType
---@param effect ac.Particles.Flame|ac.Particles.Smoke|ac.Particles.Sparks
---@param position vec3
---@param velocity vec3
---@param amount number
---@return string
LuaParticleEffectsCodeGenerator.generateCode = function(effectType, effect, position, velocity, amount)
    StringBuilder_clear()

    local variableInstanceName = variableInstanceNames[effectType]
    StringBuilder_append(string.format("-- Create the %s effect", variableInstanceName))
    StringBuilder_append(string.format("local %s = %s({", variableInstanceName, particleEffectLuaTypes[effectType]))
    StringBuilder_append(string.format("\tcolor = rgbm(%.3f, %.3f, %.3f, %.3f)", effect.color.r, effect.color.g, effect.color.b, effect.color.mult))
    StringBuilder_append(string.format("\tsize = %.2f", effect.size))

    -- add the effect-specific fields
    generators[effectType](effect, position, velocity, amount)

    StringBuilder_append("})")

    StringBuilder_append('')

    StringBuilder_append(string.format("-- Emit the %s effect in an update loop", variableInstanceName))
    StringBuilder_append('function script.update(dt)')
    StringBuilder_append('\t-- emit(position, velocity, amount)')
    StringBuilder_append(string.format("\t%s:emit(vec3(%.3f, %.3f, %.3f), vec3(%.3f, %.3f, %.3f), %.3f)", variableInstanceName, position.x, position.y, position.z, velocity.x, velocity.y, velocity.z, amount))
    StringBuilder_append('end')

    return StringBuilder_toString()
end

return LuaParticleEffectsCodeGenerator