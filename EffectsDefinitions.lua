---@class BaseEffectWrapper
---@field enabled boolean
---@field position vec3
---@field positionOffset vec3
---@field waitingForClickToSetPosition boolean
---@field getFinalPosition fun():vec3

---@class ParticleEffectWrapper : BaseEffectWrapper
---@field velocity vec3
---@field amount number

---@class FlameEffectWrapper : ParticleEffectWrapper
---@field effect ac.Particles.Flame

---@class SparksEffectWrapper : ParticleEffectWrapper
---@field effect ac.Particles.Sparks

---@class SmokeEffectWrapper : ParticleEffectWrapper
---@field effect ac.Particles.Smoke
---@field disableCollisions boolean
---@field fadeIn boolean

---@class FireworksWrapper : BaseEffectWrapper
---@field fireworksIndex number
---@field intensity number
---@field holidayType ac.HolidayType