local ParticleEffectsManager = {}

---@class BaseEffectWrapper
---@field enabled boolean
---@field position vec3
---@field positionOffset vec3
---@field velocity vec3
---@field amount number
---@field waitingForClickToSetPosition boolean
---@field getFinalPosition fun():vec3

---@class FlameEffectWrapper : BaseEffectWrapper
---@field effect ac.Particles.Flame

---@class SparksEffectWrapper : BaseEffectWrapper
---@field effect ac.Particles.Sparks

---@class SmokeEffectWrapper : BaseEffectWrapper
---@field effect ac.Particles.Smoke
---@field disableCollisions boolean
---@field fadeIn boolean

local generateWrapper = function(effect)
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
            
            local obj = generateWrapper(flame)
            return obj;
        end)()
        
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

            local obj = generateWrapper(sparks)
            return obj;
        end)()

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

            local obj = generateWrapper(smoke)
            obj.disableCollisions = false
            obj.fadeIn = false
            return obj;
        end)()

        return instance
    end
}

-- ---@return BaseEffectWrapper
-- ---@overload fun(effectType: ParticleEffectsType.Flame): FlameEffectWrapper
-- ---@overload fun(effectType: ParticleEffectsType.Sparks): SparksEffectWrapper
-- ---@overload fun(effectType: ParticleEffectsType.Smoke): SmokeEffectWrapper

---@param effectType ParticleEffectsType
---@return FlameEffectWrapper|SmokeEffectWrapper|SparksEffectWrapper
ParticleEffectsManager.generateParticleEffect = function(effectType)
    return generators[effectType]()
end

return ParticleEffectsManager