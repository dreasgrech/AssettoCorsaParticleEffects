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
    ---@param effectInstance FlameEffectWrapper
    [ParticleEffectsType.Flame] = function (file, fullSectionName, effectInstance)
        local effect = effectInstance.effect
        local position = effectInstance.getFinalPosition()
        local velocity = effectInstance.velocity
        local amount = effectInstance.amount

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
    ---@param effectInstance SparksEffectWrapper
    [ParticleEffectsType.Sparks] = function (file, fullSectionName, effectInstance)
        local effect = effectInstance.effect
        local position = effectInstance.getFinalPosition()
        local velocity = effectInstance.velocity
        local amount = effectInstance.amount

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
    ---@param effectInstance SmokeEffectWrapper
    [ParticleEffectsType.Smoke] = function (file, fullSectionName, effectInstance)
        local effect = effectInstance.effect
        local position = effectInstance.getFinalPosition()
        local velocity = effectInstance.velocity
        local amount = effectInstance.amount

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
    ---@param file ac.INIConfig
    ---@param fullSectionName string
    ---@param effectInstance FireworksWrapper
    [ParticleEffectsType.Fireworks] = function (file, fullSectionName, effectInstance)
        -- Since the fireworks values write under the same [PARTICLES_FX] header, we shouldn't use the numbered header
        local sectionName = SectionPrefixes[ParticleEffectsType.Fireworks]
        sectionName = string_format('%s_...', sectionName)

        local position = effectInstance.getFinalPosition()

        file:set(sectionName, ExtConfigCodeGenerator_getExtConfigKeyName(ExtConfigKeyType.FireworksPosition), position)
    end
}

---@param extConfigFileType ExtConfigFileHandler.ExtConfigFileTypes
---@param particleEffectsType ParticleEffectsType
---@param effectInstance FlameEffectWrapper|SparksEffectWrapper|SmokeEffectWrapper|FireworksWrapper
ParticleEffectsExtConfigFileHandler.writeToExtConfig = function(extConfigFileType, particleEffectsType, effectInstance)
    local sectionPrefix = SectionPrefixes[particleEffectsType]
    if not sectionPrefix then
        ac.log('Unknown particle effects type: ' .. tostring(particleEffectsType))
        return
    end

    local writer = writers[particleEffectsType]
    if not writer then
        ac.log('No ext_config writer for particle effects type: ' .. tostring(particleEffectsType))
        return
    end

    -- ac.log(string.format("Writing particle effect of type %d to ext_config file type %d", particleEffectsType, extConfigFileType))

    ExtConfigFileHandler.writeNewSectionToExtConfigFile(
        extConfigFileType,
        sectionPrefix,
        function (file, fullSectionName)
            -- local position = effectInstance.position
            -- local positionOffset = effectInstance.positionOffset
            -- local effect = effectInstance.effect
            -- local velocity = effectInstance.velocity
            -- local amount = effectInstance.amount
            -- local finalPosition = position + positionOffset

            -- writer(file, fullSectionName, effect, finalPosition, velocity, amount)
            writer(file, fullSectionName, effectInstance)
        end
    )
end

return ParticleEffectsExtConfigFileHandler