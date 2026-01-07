--- Contains some shared definitions related to the ext_config.ini files
local ExtConfigDefinitions = {}

ExtConfigDefinitions.SectionPrefixes = {
    [ParticleEffectsType.Flame] = 'FLAME',
    [ParticleEffectsType.Sparks] = 'SPARKS',
    [ParticleEffectsType.Smoke] = 'SMOKE',
    [ParticleEffectsType.Fireworks] = 'PARTICLES_FX',
}

---@enum ExtConfigDefinitions.ExtConfigKeyType 
ExtConfigDefinitions.ExtConfigKeyType = {
    Position = 0,
    Direction = 1,
    Speed = 2,
    Intensity = 3,
    Color = 4,

    Size = 5,
    TemperatureMult = 6,
    FlameIntensity = 7,

    Life = 8,
    SpreadDir = 9,
    SpreadPos = 10,

    ColorConsistency = 11,
    Spread = 12,
    Grow = 13,
    Thickness = 14,
    -- Life = 15,
    TargetYVelocity = 16,

    FireworksPosition = 17,
}

ExtConfigDefinitions.ExtConfigKeyNames = {
    -- Common
    [ExtConfigDefinitions.ExtConfigKeyType.Position] = "POSITION",
    [ExtConfigDefinitions.ExtConfigKeyType.Direction] = "DIRECTION",
    [ExtConfigDefinitions.ExtConfigKeyType.Speed] = "SPEED",
    [ExtConfigDefinitions.ExtConfigKeyType.Intensity] = "INTENSITY",
    [ExtConfigDefinitions.ExtConfigKeyType.Color] = "COLOR",
    [ExtConfigDefinitions.ExtConfigKeyType.Size] = "SIZE",

    -- Flames
    [ExtConfigDefinitions.ExtConfigKeyType.TemperatureMult] = "TEMPERATURE_MULT",
    [ExtConfigDefinitions.ExtConfigKeyType.FlameIntensity] = "FLAME_INTENSITY",

    -- Sparks (and common)
    [ExtConfigDefinitions.ExtConfigKeyType.Life] = "LIFE",
    [ExtConfigDefinitions.ExtConfigKeyType.SpreadDir] = "SPREAD_DIR",
    [ExtConfigDefinitions.ExtConfigKeyType.SpreadPos] = "SPREAD_POS",

    -- Smoke
    [ExtConfigDefinitions.ExtConfigKeyType.ColorConsistency] = "COLOR_CONSISTENCY",
    [ExtConfigDefinitions.ExtConfigKeyType.Spread] = "SPREAD",
    [ExtConfigDefinitions.ExtConfigKeyType.Grow] = "GROW",
    [ExtConfigDefinitions.ExtConfigKeyType.Thickness] = "THICKNESS",
    [ExtConfigDefinitions.ExtConfigKeyType.TargetYVelocity] = "TARGET_Y_VELOCITY",

    -- Fireworks
    [ExtConfigDefinitions.ExtConfigKeyType.FireworksPosition] = "FIREWORKS_POS",
}

return ExtConfigDefinitions