local ExtConfigCodeGenerator = {}

-- local bindings
local MathOperations_splitVelocity = MathOperations.splitVelocity
local StringBuilder = StringBuilder
local StringBuilder_clear = StringBuilder.clear
local StringBuilder_append = StringBuilder.append
local StringBuilder_toString = StringBuilder.toString

local ExtConfigKeyType = ExtConfigDefinitions.ExtConfigKeyType
local ExtConfigKeyNames = ExtConfigDefinitions.ExtConfigKeyNames

-- ---@param effect ac.Particles.Flame|ac.Particles.Smoke|ac.Particles.Sparks
-- ExtConfigCodeGenerator.generateCode = function(effect)
--     effect.
-- end

--[=====[

-- https://github.com/ac-custom-shaders-patch/acc-extension-config/blob/master/config/tracks/common/particles_track.ini

[TEMPLATE: _Particles_Bonfire_Fire]
@OUTPUT = FLAME_...
POSITION = $Position
DIRECTION = $Direction
INTENSITY = $_Condition
SIZE = 1
SPEED = 0.5
TEMPERATURE_MULT = 1
FLAME_INTENSITY = 1.1
COLOR = 1, 1, 1, 1

[TEMPLATE: _Particles_Bonfire_Sparks]
@OUTPUT = SPARKS_...
POSITION = $Position
DIRECTION = $Direction
SPEED = 2
LIFE = 0.2
COLOR = '#FE9806'
SPREAD_DIR = 1
SPREAD_POS = 0.2
INTENSITY = 0.05 * $_Condition

[TEMPLATE: _Particles_Bonfire_Smoke]
@OUTPUT = SMOKE_...
POSITION = $Position
DIRECTION = $Direction
SPEED = 2
SIZE = 0.2
COLOR = 0.4, 0.5, 0.6, 0.5
COLOR_CONSISTENCY = 0.3
SPREAD = 0.1
GROW = 0.5
INTENSITY = 0.1 * $_Condition
THICKNESS = 1
LIFE = 30
TARGET_Y_VELOCITY = 0.5

--]=====]

--- Temporary vector for direction calculation
local outDirection = vec3(0, 0, 0)

---@param effectInstance FlameEffectWrapper|SparksEffectWrapper|SmokeEffectWrapper
---@param header string
local generateParticleEffectCommon = function(effectInstance, header)
    local effect = effectInstance.effect
    local position = effectInstance.getFinalPosition()
    local velocity = effectInstance.velocity
    local amount = effectInstance.amount

    local speed, direction = MathOperations_splitVelocity(velocity, outDirection)
    local color = effect.color
    
    StringBuilder_append(string.format("[%s_...]", header))
    StringBuilder_append(string.format("%s = %.2f, %.2f, %.2f", ExtConfigKeyNames[ExtConfigKeyType.Position], position.x, position.y, position.z))
    StringBuilder_append(string.format("%s = %.2f, %.2f, %.2f", ExtConfigKeyNames[ExtConfigKeyType.Direction], direction.x, direction.y, direction.z))
    StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.Speed], speed))
    StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.Intensity], amount))
    StringBuilder_append(string.format("%s = %.2f, %.2f, %.2f, %.2f", ExtConfigKeyNames[ExtConfigKeyType.Color], color.r, color.g, color.b, color.mult))
    StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.Size], effect.size))
end

local generators = {
    ---@param effectInstance FlameEffectWrapper
    [ParticleEffectsType.Flame] = function (effectInstance)
        StringBuilder_clear()

        local effect = effectInstance.effect

        generateParticleEffectCommon(effectInstance, "FLAME")

        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.TemperatureMult], effect.temperatureMultiplier))
        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.FlameIntensity], effect.flameIntensity))

        return StringBuilder_toString()
    end,
    ---@param effectInstance SparksEffectWrapper
    [ParticleEffectsType.Sparks] = function (effectInstance)
        StringBuilder_clear()

        local effect = effectInstance.effect

        generateParticleEffectCommon(effectInstance, "SPARKS")

        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.Life], effect.life))
        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.SpreadDir], effect.directionSpread))
        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.SpreadPos], effect.positionSpread))

        return StringBuilder_toString()
    end,
    ---@param effectInstance SmokeEffectWrapper
    [ParticleEffectsType.Smoke] = function (effectInstance)
        StringBuilder_clear()

        local effect = effectInstance.effect

        generateParticleEffectCommon(effectInstance, "SMOKE")

        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.Life], effect.life))
        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.ColorConsistency], effect.colorConsistency))
        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.Spread], effect.spreadK))
        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.Grow], effect.growK))
        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.Thickness], effect.thickness))
        StringBuilder_append(string.format("%s = %.2f", ExtConfigKeyNames[ExtConfigKeyType.TargetYVelocity], effect.targetYVelocity))

        return StringBuilder_toString()
    end,
    ---@param effectInstance FireworksWrapper
    [ParticleEffectsType.Fireworks] = function (effectInstance)
        StringBuilder_clear()

        local position = effectInstance.getFinalPosition()

        StringBuilder_append(string.format("[%s]", ExtConfigDefinitions.SectionPrefixes[ParticleEffectsType.Fireworks]))
        StringBuilder_append(string.format("%s = %.2f, %.2f, %.2f", ExtConfigKeyNames[ExtConfigKeyType.FireworksPosition], position.x, position.y, position.z))

        return StringBuilder_toString()
    end
}

--- Generate ext_config format for the given particle effect
---@param effectType ParticleEffectsType
---@param effectInstance FlameEffectWrapper|SparksEffectWrapper|SmokeEffectWrapper|FireworksWrapper
---@return string
ExtConfigCodeGenerator.generateCode = function(effectType, effectInstance)
    return generators[effectType](effectInstance)
end

---@param extConfigKeyType ExtConfigDefinitions.ExtConfigKeyType
---@return string
ExtConfigCodeGenerator.getExtConfigKeyName = function(extConfigKeyType)
    return ExtConfigKeyNames[extConfigKeyType]
end

return ExtConfigCodeGenerator