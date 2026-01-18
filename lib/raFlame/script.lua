require('raFlame')

local car = ac.getCar(0)

local flamePos = car.position + car.side * 3
raFlame.placeFlame(flamePos, vec2(1, 2), {
  power = 0.5,
  style = 0.0,
  speed = 1.0
})

flamePos = flamePos + car.look * 2
raFlame.placeFlame(flamePos, vec2(1, 2), {
  power = 1.0,
  style = 0.25,
  speed = 2.0
})

flamePos = flamePos + car.look * 2
raFlame.placeFlame(flamePos, vec2(1, 2), {
  power = 5.0,
  style = 0.5,
  speed = 1.5
})

flamePos = flamePos + car.look * 2
raFlame.placeFlame(flamePos, vec2(1, 2), {
  power = 1.0,
  style = 0.75,
  speed = 1.5
})

flamePos = flamePos + car.look * 2
raFlame.placeFlame(flamePos, vec2(1, 2), {
  power = 1.0,
  style = 1.0,
  speed = 1.2
})

local moveFlame = raFlame.placeFlame(vec3(6.8, -0.8, -17.5), vec2(1, 2), {
  power = 1.0,
  style = 0.8,
  speed = 0.9
})

function script.update(dt)
  raFlame.updateFlames(dt)
  moveFlame:setPosition(car.position + car.look * 3)
end
