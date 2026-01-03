local ParticleEffectsExtConfigFileHandler = {}

-- local bindings
local MathOperations_splitVelocity = MathOperations.splitVelocity
local ExtConfigCodeGenerator_getExtConfigKeyName = ExtConfigCodeGenerator.getExtConfigKeyName

local SectionPrefixes = ExtConfigDefinitions.SectionPrefixes
local ExtConfigKeyType = ExtConfigDefinitions.ExtConfigKeyType

--- Temporary vector for direction calculation
local outDirection = vec3(0, 0, 0)

local writers = {
    ---@param file ac.INIConfig
    ---@param fullSectionName string
    ---@param effect ac.Particles.Flame
    ---@param position vec3
    ---@param velocity vec3
    ---@param amount number
    [ParticleEffectsType.Flame] = function (file, fullSectionName, effect, position, velocity, amount)
        local speed, direction = MathOperations_splitVelocity(velocity, outDirection)
        local color = effect.color

        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Position), position)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Direction), direction)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Speed), speed)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Intensity), amount)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Color), color)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Size), effect.size)

        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.TemperatureMult), effect.temperatureMultiplier)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.FlameIntensity), effect.flameIntensity)

        -- ac.log(string.format("Wrote FLAME section %s", fullSectionName))
    end,
    ---@param file ac.INIConfig
    ---@param fullSectionName string
    ---@param effect ac.Particles.Sparks
    ---@param position vec3
    ---@param velocity vec3
    ---@param amount number
    [ParticleEffectsType.Sparks] = function (file, fullSectionName, effect, position, velocity, amount)
        local speed, direction = MathOperations_splitVelocity(velocity, outDirection)
        local color = effect.color

        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Position), position)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Direction), direction)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Speed), speed)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Intensity), amount)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Color), color)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Size), effect.size)

        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Life), effect.life)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.SpreadDir), effect.directionSpread)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.SpreadPos), effect.positionSpread)
        -- ac.log(string.format("Wrote SPARKS section %s", fullSectionName))
    end,
    ---@param file ac.INIConfig
    ---@param fullSectionName string
    ---@param effect ac.Particles.Smoke
    ---@param position vec3
    ---@param velocity vec3
    ---@param amount number
    [ParticleEffectsType.Smoke] = function (file, fullSectionName, effect, position, velocity, amount)
        local speed, direction = MathOperations_splitVelocity(velocity, outDirection)
        local color = effect.color

        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Position), position)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Direction), direction)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Speed), speed)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Intensity), amount)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Color), color)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Size), effect.size)

        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Life), effect.life)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.ColorConsistency), effect.colorConsistency)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Spread), effect.spreadK)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Grow), effect.growK)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.Thickness), effect.thickness)
        file:set(fullSectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.TargetYVelocity), effect.targetYVelocity)

        -- ac.log(string.format("Wrote SMOKE section %s", fullSectionName))
    end,
}

---@param extConfigFileType ExtConfigFileHandler.ExtConfigFileTypes
---@param particleEffectsType ParticleEffectsType
---@param effectInstance FlameEffectWrapper|SparksEffectWrapper|SmokeEffectWrapper
ParticleEffectsExtConfigFileHandler.writeToExtConfig = function(extConfigFileType, particleEffectsType, effectInstance)
    local sectionPrefix = SectionPrefixes[particleEffectsType]
    if not sectionPrefix then
        ac.log('Unknown particle effects type: ' .. tostring(particleEffectsType))
        return
    end

    -- ac.log(string.format("Writing particle effect of type %d to ext_config file type %d", particleEffectsType, extConfigFileType))

    ExtConfigFileHandler.writeNewSectionToExtConfigFile(
        extConfigFileType,
        sectionPrefix,
        function (file, fullSectionName)
            local effect = effectInstance.effect
            local position = effectInstance.position
            local positionOffset = effectInstance.positionOffset
            local velocity = effectInstance.velocity
            local amount = effectInstance.amount

            local finalPosition = position + positionOffset
            writers[particleEffectsType](file, fullSectionName, effect, finalPosition, velocity, amount)
        end
    )
end

return ParticleEffectsExtConfigFileHandler