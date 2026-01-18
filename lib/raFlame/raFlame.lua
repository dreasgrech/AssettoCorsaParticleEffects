-- Simplified per-instance procedural flames for trackscript (CSP 0.2.11)
-- Authored by Tsuka1427 / riseart inc.
--
-- Public API:
--   raFlame.placeFlame(position: vec3, size: vec2, opts?: table) -> ac.SceneReference
--   raFlame.updateFlames(dt?: number)
--   raFlame.disposeAllFlames()
--
-- opts (minimal):
--   power: number   (default 1.0) overall brightness: affects texture intensity, ksEmissive and light strength
--   style: number   (default 0.5) 0..1: calmer → more violent/turbulent (also affects sway amount)
--   speed: number   (default 1.0) animation speed multiplier (texture)
--   seed:  number   (optional) instance variation; if omitted, unique per flame
--   noLight: boolean (optional) if true, disables light source

---@class API
raFlame = {}

---------------------------------------------------------------------------
-- Fixed rendering choices (not exposed as options)
 local ALWAYS_TRANSPARENT = true -- MUST be true to avoid "drawn behind car" issues
 local ALWAYS_BILLBOARD   = true -- face camera (upright)
 local ALWAYS_CROSSPLANES = true -- 2 quads for better visibility from angles

---------------------------------------------------------------------------
-- Visual base tuning (internal)
local BASE_EMISSIVE      = 50.0              -- you found 50 works for visibility with ksPerPixel
local BASE_LIGHT_COLOR   = rgb(10.0, 6.0, 2.0) -- HDR-ish base
local BASE_LIGHT_SPEC    = 2.5
local BASE_LONG_SPEC     = 0.55

---------------------------------------------------------------------------
-- Wind/motion sway + bend tuning (internal)
local ENABLE_WIND_SWAY   = true

local TELEPORT_DISTANCE  = 6.0 -- if moved farther than this in one frame, treat as teleport (m)
local VELOCITY_RESPONSE  = 10.0 -- how quickly velocity estimate follows target (bigger = faster)
local WIND_RESPONSE      = 3.0 -- how quickly wind estimate follows target

local IDLE_WIND_MS       = 0.25 -- minimum turbulence (m/s) even when no wind/no movement

-- Sway oscillation model: adds along-wind and cross-wind components so direction always changes.
local SWAY_FREQ_BASE     = 1.1  -- base frequency multiplier
local SWAY_FREQ_PER_MS   = 0.22 -- + per (m/s) of relative wind

local SWAY_ALONG_BASE    = 0.12 -- m/s
local SWAY_ALONG_PER_MS  = 0.018 -- m/s per (m/s)
local SWAY_PERP_BASE     = 0.35 -- m/s
local SWAY_PERP_PER_MS   = 0.075 -- m/s per (m/s)

-- Bend: converts effective wind speed (m/s) into top vertex offset (m)
local BEND_PER_MS        = 0.030 -- m offset per (m/s)
local MAX_BEND_REL       = 0.65 -- clamp: top offset ≤ height * this
local BEND_RESPONSE      = 12.0 -- smoothing of bend vector
local BEND_CURVE_POW     = 1.35 -- >1: more curvature (needs mid-row vertices)

-- Light follows bend a bit (for more natural highlight/reflections)
local LIGHT_BEND_FOLLOW  = 0.65


local flames             = {}
local nextId             = 0

local _worldUp           = vec3(0, 1, 0)
local _tmpLook           = vec3()
local _tmpWind           = vec3()

local function clamp(x, a, b)
    x = tonumber(x) or a
    if x < a then return a end
    if x > b then return b end
    return x
end

local function expSmoothing(rate, dt)
    if dt <= 0 then return 1.0 end
    return 1.0 - math.exp(-rate * dt)
end

local function fract(x) return x - math.floor(x) end
local function hash1(x) return fract(math.sin(x) * 43758.5453123) end

local function seedToVec2(seed)
    seed = tonumber(seed) or 0
    return vec2(hash1(seed * 12.9898) * 100.0, hash1(seed * 78.233) * 100.0)
end

local function trySetProp(mesh, prop, value)
    pcall(function() mesh:setMaterialProperty(prop, value) end)
end

local function deriveStrength(style01)
    style01 = clamp(style01, 0.0, 1.0)
    return 1.0 + style01 * 2.0
end

local function createCrossPlaneMesh(node, size, canvas, id)
    local hw  = size.x * 0.5
    local h   = size.y
    local hm  = h * 0.5

    local v   = {}
    local idx = {}

    local function addPlaneXZ(isPlaneA)
        local base = #v
        local n = isPlaneA and vec3(0, 0, 1) or vec3(1, 0, 0)

        if isPlaneA then
            v[#v + 1] = ac.MeshVertex(vec3(-hw, 0, 0), n, vec2(0, 0))
            v[#v + 1] = ac.MeshVertex(vec3(hw, 0, 0), n, vec2(1, 0))
            v[#v + 1] = ac.MeshVertex(vec3(-hw, hm, 0), n, vec2(0, 0.5))
            v[#v + 1] = ac.MeshVertex(vec3(hw, hm, 0), n, vec2(1, 0.5))
            v[#v + 1] = ac.MeshVertex(vec3(-hw, h, 0), n, vec2(0, 1))
            v[#v + 1] = ac.MeshVertex(vec3(hw, h, 0), n, vec2(1, 1))
        else
            v[#v + 1] = ac.MeshVertex(vec3(0, 0, -hw), n, vec2(0, 0))
            v[#v + 1] = ac.MeshVertex(vec3(0, 0, hw), n, vec2(1, 0))
            v[#v + 1] = ac.MeshVertex(vec3(0, hm, -hw), n, vec2(0, 0.5))
            v[#v + 1] = ac.MeshVertex(vec3(0, hm, hw), n, vec2(1, 0.5))
            v[#v + 1] = ac.MeshVertex(vec3(0, h, -hw), n, vec2(0, 1))
            v[#v + 1] = ac.MeshVertex(vec3(0, h, hw), n, vec2(1, 1))
        end

        local i0 = base + 0
        local i1 = base + 1
        local i2 = base + 2
        local i3 = base + 3
        local i4 = base + 4
        local i5 = base + 5

        idx[#idx + 1] = i0; idx[#idx + 1] = i1; idx[#idx + 1] = i3
        idx[#idx + 1] = i0; idx[#idx + 1] = i3; idx[#idx + 1] = i2

        idx[#idx + 1] = i2; idx[#idx + 1] = i3; idx[#idx + 1] = i5
        idx[#idx + 1] = i2; idx[#idx + 1] = i5; idx[#idx + 1] = i4
    end

    if ALWAYS_CROSSPLANES then
        addPlaneXZ(true)
        addPlaneXZ(false)
    else
        local n = vec3(0, 0, 1)
        local base = #v
        v[#v + 1] = ac.MeshVertex(vec3(-hw, 0, 0), n, vec2(0, 0))
        v[#v + 1] = ac.MeshVertex(vec3(hw, 0, 0), n, vec2(1, 0))
        v[#v + 1] = ac.MeshVertex(vec3(-hw, hm, 0), n, vec2(0, 0.5))
        v[#v + 1] = ac.MeshVertex(vec3(hw, hm, 0), n, vec2(1, 0.5))
        v[#v + 1] = ac.MeshVertex(vec3(-hw, h, 0), n, vec2(0, 1))
        v[#v + 1] = ac.MeshVertex(vec3(hw, h, 0), n, vec2(1, 1))

        local i0 = base + 0
        local i1 = base + 1
        local i2 = base + 2
        local i3 = base + 3
        local i4 = base + 4
        local i5 = base + 5

        idx[#idx + 1] = i0; idx[#idx + 1] = i1; idx[#idx + 1] = i3
        idx[#idx + 1] = i0; idx[#idx + 1] = i3; idx[#idx + 1] = i2
        idx[#idx + 1] = i2; idx[#idx + 1] = i3; idx[#idx + 1] = i5
        idx[#idx + 1] = i2; idx[#idx + 1] = i5; idx[#idx + 1] = i4
    end

    local vertices = ac.VertexBuffer(v)
    local indices  = ac.IndicesBuffer(idx)

    local mesh     = node:createMesh('ts_flame_mesh_' .. id, nil, vertices, indices, false, false)
    if not mesh then return nil end

    mesh:ensureUniqueMaterials()
    mesh:setCullMode(render.CullMode.None)
    mesh:setTransparent(ALWAYS_TRANSPARENT)
    --mesh:setBlendMode(render.BlendMode.BlendAdd)
    mesh:setBlendMode(render.BlendMode.AlphaTest)
    mesh:setDepthMode(render.DepthMode.ReadOnlyLessEqual)
    mesh:setShadows(false)

    mesh:setMaterialTexture('txDiffuse', canvas)

    trySetProp(mesh, 'ksDiffuse', rgb(1, 1, 1))
    --trySetProp(mesh, 'ksDiffuse', rgb(0, 0, 0))
    trySetProp(mesh, 'ksSpecular', rgb(0, 0, 0))

    --mesh:excludeFromCubemap(true)
    --mesh:excludeFromSecondary(false)

    local basePos = {}
    for i = 1, #v do
        basePos[i] = v[i].pos:clone()
    end

    return mesh, vertices, basePos, h
end

local function createDerivedLight(node, size, power, strength, seed)
    if power <= 0 then return nil end

    local useLine = true
    local light = ac.LightSource(useLine and ac.LightType.Line or ac.LightType.Regular)
    light:linkTo(node)

    local baseY                = size.y * 0.35
    local lineH                = size.y * 1.55

    light.position             = vec3(0, baseY, 0)
    light.linePos              = vec3(0, baseY + lineH, 0)

    local p                    = clamp(power, 0.0, 2.0)
    local s                    = clamp((strength - 1.0) / 2.0, 0.0, 1.0)

    local colorScale           = (1.35 + 0.55 * p) * (0.85 + 0.15 * s)
    light.color                = BASE_LIGHT_COLOR * colorScale
    light.lineColor            = light.color * 0.65

    light.range                = size.y * (4.2 + 2.0 * s) * (0.65 + 0.55 * p)

    light.affectsCars          = true
    light.showInReflections    = true

    light.specularMultiplier   = BASE_LIGHT_SPEC + 0.9 * s + 1.2 * p
    light.longSpecular         = BASE_LONG_SPEC + 0.10 * s
    light.diffuseConcentration = 0.85

    light.skipLightMap         = true

    local fl                   = {
        baseColor = light.color:clone(),
        baseRange = light.range,
        amp = 0.22 + 0.10 * s,
        speed = 9.0 + 6.0 * s,
        phase = seed * 0.37 + hash1(seed * 5.123) * 100.0,
        baseY = baseY,
        lineH = lineH
    }

    return light, fl
end


function raFlame.placeFlame(position, size, opts)
    opts = opts or {}

    nextId = nextId + 1
    local id = nextId

    local power = clamp(opts.power or 1.0, 0.0, 5.0)
    local strength = deriveStrength(opts.style or 0.5)
    local speed = clamp(opts.speed or 1.0, 0.1, 10.0)
    local seed = tonumber(opts.seed) or id

    local root = ac.findNodes('trackRoot:yes')
    local node = root:createNode('ts_flame_node', false)
    if not node then return nil end
    node:setPosition(position)

    local canvas = ui.ExtraCanvas(256, 1, render.TextureFormat.R16G16B16A16.Float)
    canvas:setName('TS_FlameCanvas_' .. id)
    canvas:clear(rgbm(0, 0, 0, 1))

    local mesh, vertices, basePos, h = createCrossPlaneMesh(node, size, canvas, id)
    if not mesh then
        canvas:dispose()
        node:dispose()
        return nil
    end

    local emissiveScale = BASE_EMISSIVE * clamp(power, 0.0, 2.0)
    trySetProp(mesh, 'ksEmissive', rgb(emissiveScale, emissiveScale, emissiveScale))

    local shaderParams = {
        async = false,
        --shader = 'raFlame.fx',
        shader = 'lib/raFlame/raFlame.fx',
        values = {
            gTime = 0,
            gStrength = strength,
            gSeed = seedToVec2(seed),
            gIntensity = power
        }
    }

    local light, flicker = nil, nil
    if not opts.noLight then
        light, flicker = createDerivedLight(node, size, power, strength, seed)
    end

    local pos0 = node:getPosition()
    local style01 = clamp((strength - 1.0) / 2.0, 0.0, 1.0)

    flames[#flames + 1] = {
        id = id,
        node = node,
        mesh = mesh,
        vertices = vertices,
        basePos = basePos,
        h = h,
        size = size,

        power = power,
        strength = strength,
        style01 = style01,
        speed = speed,
        seed = seed,

        canvas = canvas,
        shaderParams = shaderParams,

        light = light,
        flicker = flicker,

        prevPos = pos0:clone(),
        vel = vec3(0, 0, 0),
        wind = vec3(0, 0, 0),
        dirX = 1.0,
        dirZ = 0.0,
        bend = vec3(0, 0, 0),
        ph1 = hash1(seed * 1.11) * 100.0,
        ph2 = hash1(seed * 2.22) * 100.0,
        ph3 = hash1(seed * 3.33) * 100.0,
        ph4 = hash1(seed * 4.44) * 100.0,
        ph5 = hash1(seed * 5.55) * 100.0,
        ph6 = hash1(seed * 6.66) * 100.0,
        fq1 = 0.85 + hash1(seed * 7.01) * 0.55,
        fq2 = 1.35 + hash1(seed * 7.02) * 0.55,
        fq3 = 2.05 + hash1(seed * 7.03) * 0.55,
        fq4 = 3.10 + hash1(seed * 7.04) * 0.55,
    }

    return node
end

local function updateBillboardAndGetBasis(node, pos, camPos)
    local lx = camPos.x - pos.x
    local lz = camPos.z - pos.z
    local ll = math.sqrt(lx * lx + lz * lz)
    if ll < 1e-6 then
        lx, lz = 0.0, 1.0
        ll = 1.0
    end
    lx = lx / ll
    lz = lz / ll

    if ALWAYS_BILLBOARD then
        _tmpLook:set(lx, 0, lz)
        node:setOrientation(_tmpLook, _worldUp)
    end

    return lx, lz, lz, -lx
end

local function updateWindAndBend(f, sim, dt)
    if not ENABLE_WIND_SWAY then
        f.bend:set(0, 0, 0)
        return 0.0
    end

    dt = dt or sim.dt
    if dt == nil or dt <= 0 then dt = 0.016 end

    local pos = f.node:getPosition()

    local dx = pos.x - f.prevPos.x
    local dy = pos.y - f.prevPos.y
    local dz = pos.z - f.prevPos.z
    f.prevPos:set(pos)

    local dist2 = dx * dx + dy * dy + dz * dz
    local tele = dist2 > (TELEPORT_DISTANCE * TELEPORT_DISTANCE)

    local rawVx, rawVy, rawVz = 0.0, 0.0, 0.0
    if not tele then
        rawVx, rawVy, rawVz = dx / dt, dy / dt, dz / dt
    else
        pcall(function() f.node:clearMotion() end)
    end

    local aVel = expSmoothing(VELOCITY_RESPONSE, dt)
    f.vel.x = f.vel.x + (rawVx - f.vel.x) * aVel
    f.vel.y = f.vel.y + (rawVy - f.vel.y) * aVel
    f.vel.z = f.vel.z + (rawVz - f.vel.z) * aVel

    ac.getWindVelocityTo(_tmpWind)
    local wx, wz = _tmpWind.x, _tmpWind.z

    local aWind = expSmoothing(WIND_RESPONSE, dt)
    f.wind.x = f.wind.x + (wx - f.wind.x) * aWind
    f.wind.z = f.wind.z + (wz - f.wind.z) * aWind

    local relX = f.wind.x - f.vel.x
    local relZ = f.wind.z - f.vel.z

    local baseMag = math.sqrt(relX * relX + relZ * relZ)
    local dirX, dirZ = f.dirX, f.dirZ
    if baseMag > 1e-4 then
        dirX, dirZ = relX / baseMag, relZ / baseMag
        f.dirX, f.dirZ = dirX, dirZ
    end

    local perpX, perpZ = -dirZ, dirX

    local freq         = SWAY_FREQ_BASE + math.min(baseMag, 40.0) * SWAY_FREQ_PER_MS
    local t            = sim.gameTime

    local a1           = math.sin(t * freq * f.fq1 + f.ph1)
    local a2           = math.sin(t * freq * f.fq2 + f.ph2)
    local a3           = math.sin(t * freq * f.fq3 + f.ph3)
    local a4           = math.sin(t * freq * f.fq4 + f.ph4)

    local styleScale   = 0.35 + 0.65 * f.style01

    local ampAlong     = (SWAY_ALONG_BASE + SWAY_ALONG_PER_MS * baseMag) * styleScale
    local ampPerp      = (SWAY_PERP_BASE + SWAY_PERP_PER_MS * baseMag) * styleScale

    local modMag       = baseMag + (a1 * 0.65 + a2 * 0.35) * ampAlong
    if modMag < 0.0 then modMag = 0.0 end
    local side     = (a3 * 0.70 + a4 * 0.30) * ampPerp

    local effX     = dirX * modMag + perpX * side
    local effZ     = dirZ * modMag + perpZ * side

    local idle     = IDLE_WIND_MS * styleScale
    effX           = effX + math.sin(t * 0.8 + f.ph5) * idle
    effZ           = effZ + math.cos(t * 0.9 + f.ph6) * idle

    local effMag   = math.sqrt(effX * effX + effZ * effZ)

    local bendDist = effMag * BEND_PER_MS * (0.65 + 0.55 * f.style01)
    local maxBend  = f.h * MAX_BEND_REL
    if bendDist > maxBend then bendDist = maxBend end

    local tgtBx, tgtBz = 0.0, 0.0
    if effMag > 1e-4 then
        local inv = 1.0 / effMag
        tgtBx = effX * inv * bendDist
        tgtBz = effZ * inv * bendDist
    end

    local aB = expSmoothing(BEND_RESPONSE, dt)
    f.bend.x = f.bend.x + (tgtBx - f.bend.x) * aB
    f.bend.z = f.bend.z + (tgtBz - f.bend.z) * aB

    return effMag
end

local function applyBendToVertices(f, lookX, lookZ, rightX, rightZ)
    local bx, bz = f.bend.x, f.bend.z
    local localX = bx * rightX + bz * rightZ
    local localZ = bx * lookX + bz * lookZ

    local h = f.h
    if h <= 1e-6 then return localX, localZ end

    local vb = f.vertices
    local base = f.basePos

    for i = 1, #base do
        local bp = base[i]
        local k = bp.y / h
        if k < 0.0 then k = 0.0 elseif k > 1.0 then k = 1.0 end
        k = k ^ BEND_CURVE_POW

        local vtx = vb:get(i)
        vtx.pos:set(
            bp.x + localX * k,
            bp.y,
            bp.z + localZ * k
        )
    end

    f.mesh:alterVertices(vb)

    return localX, localZ
end

function raFlame.updateFlames(dt)
    if #flames == 0 then return end

    local sim = ac.getSim()
    local t = sim.gameTime
    local cam = sim.cameraPosition

    render.backupRenderTarget()

    for i = 1, #flames do
        local f = flames[i]
        local pos = f.node:getPosition()
        local lookX, lookZ, rightX, rightZ = updateBillboardAndGetBasis(f.node, pos, cam)
        local effMag = updateWindAndBend(f, sim, dt)

        local localBx, localBz = 0.0, 0.0
        if f.vertices and f.basePos then
            localBx, localBz = applyBendToVertices(f, lookX, lookZ, rightX, rightZ)
        end

        local wind01 = clamp(effMag / 25.0, 0.0, 1.0)
        local v = f.shaderParams.values
        v.gTime = t * f.speed
        v.gStrength = f.strength
        v.gIntensity = f.power * (1.0 + 0.18 * wind01)
        f.canvas:updateWithShader(f.shaderParams)

        if f.light and f.flicker then
            local fl = f.flicker

            local k =
                1.0
                + fl.amp * (
                    math.sin(t * fl.speed + fl.phase) * 0.65
                    + math.sin(t * fl.speed * 2.7 + fl.phase * 0.3) * 0.35
                )
            if k < 0.0 then k = 0.0 end

            f.light.color    = fl.baseColor * k
            f.light.range    = fl.baseRange * (0.92 + 0.08 * k)

            local follow     = LIGHT_BEND_FOLLOW * (0.35 + 0.65 * f.style01)
            local baseY      = fl.baseY
            local lineH      = fl.lineH
            local bx         = localBx * follow
            local bz         = localBz * follow

            f.light.position = vec3(bx * 0.20, baseY, bz * 0.20)
            f.light.linePos  = vec3(bx * 0.90, baseY + lineH, bz * 0.90)
        end
    end

    render.restoreRenderTarget()
end

function raFlame.disposeAllFlames()
    for i = #flames, 1, -1 do
        local f = flames[i]
        if f.light then f.light:dispose() end
        if f.canvas then f.canvas:dispose() end
        if f.node then f.node:dispose() end
        table.remove(flames, i)
    end
end

