local ParticleEffectsManager = {}

---@param effect ac.Particles.Flame|ac.Particles.Sparks|ac.Particles.Smoke
---@return ParticleEffectWrapper
local generateParticleEffectWrapper = function(effect)
    local wrapper = {
        enabled = false,
        
        position = vec3(0, 0, 0),
        positionOffset = vec3(0, 0, 0),
        velocity = vec3(0, 0, 0),
        amount = 0,
        
        waitingForClickToSetPosition = false,
        
        effect = effect
    }

    wrapper.getFinalPosition = function()
        return wrapper.position + wrapper.positionOffset
    end

    ---@cast wrapper ParticleEffectWrapper
    return wrapper
end

---@param fireworksIndex number
---@return FireworksWrapper
local generateFireworksWrapper = function(fireworksIndex)
    local wrapper = {
        enabled = false,

        position = vec3(0, 0, 0),
        positionOffset = vec3(0, 0, 0),

        waitingForClickToSetPosition = false,

        fireworksIndex = fireworksIndex,
    }

    wrapper.getFinalPosition = function()
        return wrapper.position + wrapper.positionOffset
    end

    ---@cast wrapper FireworksWrapper
    return wrapper
end

local generators = {
    ---@return FlameEffectWrapper
    [ParticleEffectsType.Flame] = function()
        local instance = (function()
            local flame = ac.Particles.Flame( {
                color = rgbm(1, 1, 1, 1),
                size = 0,
                
                temperatureMultiplier = 0,
                flameIntensity = 0
            })
            
            local obj = generateParticleEffectWrapper(flame)
            return obj;
        end)()
        
        ---@cast instance FlameEffectWrapper
        return instance
    end,
    ---@return SparksEffectWrapper
    [ParticleEffectsType.Sparks] = function()
        local instance = (function()
            local sparks = ac.Particles.Sparks({
                color = rgbm(0, 0, 0, 0),
                size = 0,
                
                life = 0,
                directionSpread = 0,
                positionSpread = 0
            })

            local obj = generateParticleEffectWrapper(sparks)
            return obj;
        end)()

        ---@cast instance SparksEffectWrapper
        return instance
    end,
    ---@return SmokeEffectWrapper
    [ParticleEffectsType.Smoke] = function()
        local instance = (function()
            local smoke = ac.Particles.Smoke({
                color = rgbm(0, 0, 0, 0),
                size = 0,

                life = 0,
                colorConsistency = 0,
                thickness = 0,
                spreadK = 0,
                growK = 0,
                targetYVelocity = 0,
            })

            local obj = generateParticleEffectWrapper(smoke)
            ---@cast obj SmokeEffectWrapper
            obj.disableCollisions = false
            obj.fadeIn = false
            return obj;
        end)()

        ---@cast instance SmokeEffectWrapper
        return instance
    end,
    ---@return FireworksWrapper
    [ParticleEffectsType.Fireworks] = function()
        local fireworksIndex = FireworksManager.startFireworks(vec3(0,0,0), 0, ac.HolidayType.Generic)
        local instance = generateFireworksWrapper(fireworksIndex)

        ---@cast instance FireworksWrapper
        return instance
    end
}

-- ---@return BaseEffectWrapper
-- ---@overload fun(effectType: ParticleEffectsType.Flame): FlameEffectWrapper
-- ---@overload fun(effectType: ParticleEffectsType.Sparks): SparksEffectWrapper
-- ---@overload fun(effectType: ParticleEffectsType.Smoke): SmokeEffectWrapper

---@param effectType ParticleEffectsType
---@return FlameEffectWrapper|SmokeEffectWrapper|SparksEffectWrapper|FireworksWrapper
ParticleEffectsManager.generateParticleEffect = function(effectType)
    return generators[effectType]()
end

return ParticleEffectsManager