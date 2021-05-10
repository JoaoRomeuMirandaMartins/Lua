-- Created 03/15/2021 04:19:36 

local machine_info = machine.get_machine_info()
local starting_block = machine_info.get_block_info(0)
local key_n = machine.new_key_emulator("n")
local key_m = machine.new_key_emulator("m")
local key_b = machine.new_key_emulator("b")
local key_f = machine.new_key_emulator("f")
local frontEngine = machine.get_refs_control("FrontEngine")
local backEngine = machine.get_refs_control("BackEngine")
local backRoll = machine.get_refs_control("BackRoll")
local frontRoll = machine.get_refs_control("FrontRoll")
local yawHover = machine.get_refs_control("YawHover")
local elevator = machine.get_refs_control("Elevator")
local rudder = machine.get_refs_control("Rudder")
local aleiron = machine.get_refs_control("Aleiron")
local rotationY = 0
local rotationX = 0
local altitude
local direction = 0
local oldRot = vector.new(0, 0, 0)
local vec = vector.new(0, 0, 0)

local hit
local crosshair = lines.new_line_renderer()
local dist = nil


local function newfixedTarget(Pos)
  local pos = Pos
  return {
    position = function ()
      return pos
    end,
    velocity = function ()
      return vector.new(0, 0, 0)
    end,
    is_simulating = function ()
      return true
    end,
  }
end
local function mousetracker()
  local clickFlag = true
  local pos = input.mouse_raycast_hit_point()
  local Hit
  return {
    player = false,
    velocity = function()
      return vector.new(0, 0, 0)
    end,
    position = function ()
      if (input.get_key("Mouse0") and clickFlag) or input.get_key("Mouse1") then
        Hit = input.mouse_raycast_hit_point()
        if (Hit.x ~= 0 and Hit.y ~= 0 and Hit.z ~= 0) then
          pos = Hit
        end
      else
        clickFlag = false
      end
      return pos
    end,
    is_simulating = function ()
      return true
    end
  }
end
local function myEntity(entity)
  local oldPos = entity.position()
  return {
    velocity = entity.     velocity,
    position = entity.position,
    health = entity.health,
    id = entity.id,
    name = entity.name,
    player = false,
    is_simulating = function ()
      return true
    end
  }
end
local colisionpoint = vector.new(0, 0, 0)

local FiveSeconds
local ActivePlayers = {}
local NActivePlayers = 0
local targets = {}
local Ntargets = 0
local selectedTarget = 0
local target
local Ctarget
local targetMachine
local targetStartingBlock
local targetBlock
local targetDist
local RelTarget = {}
local player
local LevelEntities = entities.get_all()
local NOfEntities = entities.count()


local clock = 0
local start = 0
local text = ""
local booleanDict = {}
booleanDict[true] = "True"
booleanDict[false] = "False"
local mouseHit
local cycles
local cont = 0
local contII = 0

local bombRoll
local bombElevator
local bomb
local BombKey = machine.new_key_emulator('Alpha0')
local BombCont = 0
local bombOnAir = 0
local NBOMBS = 6
local ActiveBombs = {}
local maneuver
local interceptionTime
local a
local b
local c
local delta


local launch
local debounce = 0


local JOY = "Joy0"
local JoyAxis0 = JOY.."Axis0"
local JoyAxis1 = JOY.."Axis1"
local JoyAxis2 = JOY.."Axis2"
local JoyAxis3 = JOY.."Axis3"
local JoyAxis4 = JOY.."Axis4"
local JoyAxis5 = JOY.."Axis5"
local JoyBtn0 = "JoystickButton0"
local JoyBtn1 = "JoystickButton1"
local JoyBtn2 = "JoystickButton2"
local JoyBtn3 = "JoystickButton3"
local JoyBtn4 = "JoystickButton4"
local JoyBtn5 = "JoystickButton5"
local JoyBtn6 = "JoystickButton6"
local JoyBtn7 = "JoystickButton7"
local JoyBtn8 = "JoystickButton8"
local JoyBtn9 = "JoystickButton9"
local JoyBtn10 = "JoystickButton10"
local JoyBtn11 = "JoystickButton11"
local JoyBtn12 = "JoystickButton12"
local btn2
local click
local clickHit


local bombDict = {}
bombDict[1] = "Alpha1"
-- bombDict[1] = "Keypad1"
bombDict[2] = "Alpha2"
bombDict[3] = "Alpha3"
bombDict[4] = "Alpha4"
bombDict[5] = "Alpha5"
bombDict[6] = "Alpha6"
bombDict[7] = "Alpha7"
bombDict[8] = "Alpha8"
bombDict[9] = "Alpha9"
bombDict[10] = "Alpha0"

local axisX
local axisY
local axisR
local axisS
local mode = true
local BombMode = false
local BombModeDebounce = 0
local window_rect-- gui window rectangle (see unity scripting api about gui)

local function contains(array, value)
  for i, v in pairs(array) do
    if v == value then
      return true
    end
  end
  return false
end

local function remove(Table, key)
  local Ntable = {}
  for k, value in pairs(Table) do
    if k ~= key then
      Ntable[k] = value
    end
  end
  return Ntable
end

local function OrderedRemove(table, key)
  local Ntable = {}
  for k, value in pairs(table) do
    if k < key then
      Ntable[k] = value
    else
      if k > key then
        Ntable[k - 1] = value
      end
    end
  end
  return Ntable
end

local function aim(target)
  local ratio
  local quadr
  local targetRelPos = vector.new(bomb.position().x - target.x,  bomb.position().y - target.y - 1, bomb.position().z - target.z)
  if targetRelPos.x < 0 then
    quadr = 3.14159265359
  else
    if targetRelPos.z < 0 then
      quadr = 6.28318530718
    else
      quadr = 0
    end
  end
  local resultX = bomb.rotation().y+(math.atan(targetRelPos.z/targetRelPos.x) + quadr) * 57.2957795131 - 270
  resultX = resultX - math.floor(resultX/360)*360
  if resultX > 180 then
    resultX = resultX - 360
  end
  local resultY = - bomb.rotation().x
  if resultY < -180 then
    resultY = resultY + 360
  end
  if targetRelPos.y < 0 then
    resultY = resultY + 90
  end
  ratio = (targetRelPos.x^2 + targetRelPos.z^2)^0.5/targetRelPos.y
  if ratio > 0 then
    resultY = resultY + 90 - math.atan(ratio) * 57.2957795131
  else
    resultY = resultY - 180 + math.atan(-ratio) * 57.2957795131
  end
  return vector.new(15-30/(1 + 1.125^(-resultX)), 25-50/(1 + 1.125^(-resultY)))
end
local function targetPrediction(target, Bomb)
  RelTarget.position = vector.subtract(target.position(), Bomb.position())
  RelTarget.velocity = target.velocity()
  a = (RelTarget.velocity.x^2 + RelTarget.velocity.y^2 + RelTarget.velocity.z^2 - vector.magnitude(Bomb.velocity())^2)
  b = 2 * (RelTarget.position.x * RelTarget.velocity.x + RelTarget.position.y * RelTarget.velocity.y + RelTarget.position.z * RelTarget.velocity.z)
  c = RelTarget.position.x^2 + RelTarget.position.y^2 + RelTarget.position.z^2
  delta = b^2 - 4 * c * a
  if delta > 0 then
    delta = delta^0.5
    interceptionTime = 0
    if (-b - delta)/a > 0 then
      interceptionTime = (-b - delta)/(2 * a)
    else
      if (-b + delta)/a > 0 then
        interceptionTime = (-b + delta)/(2 * a)
      end
    end
  else
    interceptionTime = 0
  end
  return interceptionTime
end

local function play()
  FiveSeconds = time.time()
  start = time.time()
  key_f.click()
  cont = 1
  contII = 1
  while cont <= NOfEntities do
    if contains({4019, 4004, 4005, 4006, 4008, 4011, 4013, 4012, 4014, 4015, 4017, 4018, 4020, 4021, 66}, LevelEntities[cont].id()) then
      targets[contII] = myEntity(LevelEntities[cont])
      contII = contII + 1
    end
    cont = cont + 1
  end
  Ntargets = contII
  crosshair.set_points(vector.new(0, -1, 0), vector.new(0, -0.5, 0))
  -- called on simulation start
end

local function update()
  if 90 > oldRot.x and starting_block.rotation().x > 270 then
    oldRot.x = oldRot.x + 360
  else
    if 270 < oldRot.x and starting_block.rotation().x < 90 then
      oldRot.x = oldRot.x -360
    end
  end
  if 90 > oldRot.y and starting_block.rotation().y > 270 then
    oldRot.y = oldRot.y + 360
  else
    if 270 < oldRot.y and starting_block.rotation().y < 90 then
      oldRot.y = oldRot.y -360
    end
  end
  if 90 > oldRot.z and starting_block.rotation().z > 270 then
    oldRot.z = oldRot.z + 360
  else
    if 270 < oldRot.z and starting_block.rotation().z < 90 then
      oldRot.z = oldRot.z -360
    end
  end
  starting_block.rotationalSpeed = vector.multiply(vector.subtract(starting_block.rotation(), oldRot), 1/time.delta_time())
  oldRot = starting_block.rotation()
  hit = physics.raycast(vector.add(vector.multiply(starting_block.forward(), -10), starting_block.position()), vector.multiply(starting_block.forward(), -11))
  axisX = input.get_axis(JoyAxis0) * 10;
  axisY = input.get_axis(JoyAxis1) * 10;
  axisR = input.get_axis(JoyAxis2) * 10;
  axisS = 0.5 -  input.get_axis(JoyAxis3) * 5;
  if debounce < time.time() then
    debounce = time.time() + 0.15
    if input.get_axis(JoyAxis5) * 10 > 0.5 then
      if selectedTarget < Ntargets - 1 then
        selectedTarget = selectedTarget + 1
      else
        selectedTarget = 1
      end
      target = targets[selectedTarget]
    else
      if input.get_axis(JoyAxis5) * 10 < -0.5 then
        if selectedTarget > 1 then
          selectedTarget = selectedTarget - 1
        else
          selectedTarget = Ntargets - 1
        end
        target = targets[selectedTarget]
      end
    end
  end
  if input.get_key_down(JoyBtn6)  and not BombMode then
    mode = false == mode
    if mode == false then
      key_n.start()
      key_m.stop()
    else
      key_m.start()
      key_n.stop()
    end
  end
  
  
  if not BombMode then
    if mode then
      frontEngine.set_slider("speed", 1.5 * axisS + 0.5 * axisY)
      backEngine.set_slider("speed", 1.5 * axisS - 0.5 * axisY)
      backRoll.set_slider("speed", -2 * axisX)
      frontRoll.set_slider("speed", 2 * axisX)
      yawHover.set_steering(axisR * 20)
      if input.get_key_down(JoyBtn7) then
        altitude = starting_block.position().y + 5
        direction = starting_block.rotation().y
        BombModeDebounce = time.time() + 1
        BombMode = BombMode == false
        key_b.start()
      end
      if BombModeDebounce < time.time() then
        key_f.stop()
      end
    else
      frontEngine.set_slider("speed", 2 * axisS)
      backEngine.set_slider("speed", 2 * axisS)
      backRoll.set_slider("speed", 2 * axisS)
      frontRoll.set_slider("speed", 2 * axisS)
      elevator.set_steering(-15 - axisY * 40)
      rudder.set_steering(axisR * 30)
      aleiron.set_steering(axisX * 30)
      -- test
    end
  else
    if input.get_key_down(JoyBtn7) then
      BombMode = BombMode == false
      BombModeDebounce = time.time() + 1
      key_f.start()
    end
    if BombModeDebounce < time.time() then
      key_b.stop()
    end
    if starting_block.rotation().x < 180 then
      rotationY = starting_block.rotation().x
    else
      rotationY = starting_block.rotation().x - 360
    end
    if starting_block.rotation().z < 180 then
      rotationX = starting_block.rotation().z
    else
      rotationX = starting_block.rotation().z - 360
    end
    if direction + 180 < starting_block.rotation().y  then
      yawHover.set_steering(0.05 * (direction + 360 - starting_block.rotation().y + starting_block.rotationalSpeed.y))
    else
      if direction - 180 > starting_block.rotation().y  then
        yawHover.set_steering(0.05 * (direction - 360 - starting_block.rotation().y + 0.1 * starting_block.rotationalSpeed.y))
      else 
        yawHover.set_steering(0.05 * (direction - starting_block.rotation().y + 0.1 * starting_block.rotationalSpeed.y))
      end
    end
    frontEngine.set_slider("speed",  -0.005 * rotationY + 0.05 * (altitude - starting_block.position().y))
    backEngine.set_slider("speed",  0.005 * rotationY + 0.05 * (altitude - starting_block.position().y))
    frontRoll.set_slider("speed", -(0.05 + 0.05 * (NBOMBS - BombCont)) * (rotationX + starting_block.rotationalSpeed.z))
    backRoll.set_slider("speed", (0.05 + 0.05 * (NBOMBS - BombCont)) * (rotationX + starting_block.rotationalSpeed.z))
  end
  if target ~= nil then
    dist = vector.magnitude(vector.subtract(target.position(), starting_block.position()))
    crosshair.set_color(vector.new(0, 1, 0))
    crosshair.set_points(target.position(), vector.add(target.position(), vector.new(0, 0.1 * dist, 0)))
    crosshair.set_width(0, 0.01 * dist)
  end
  if BombCont > 0 then
    bombOnAir = 0
    for bombCont, bombInfo in pairs(ActiveBombs) do
      bomb = bombInfo.b
      bombElevator = bombInfo.e
      bombRoll = bombInfo.r
      BombKey = bombInfo.k
      launch = bombInfo.l
      Ctarget = bombInfo.t
      if not bomb.burning() then
        bombOnAir = bombOnAir + 1
        if Ctarget.is_simulating() then
          colisionpoint = vector.add(Ctarget.position(), vector.multiply(Ctarget.velocity(), targetPrediction(Ctarget, bomb)))
        else
          colisionpoint = vector.add(bomb.position() ,vector.new(0.1, -1, 0.1))
        end
        dist = vector.magnitude(vector.subtract(colisionpoint, starting_block.position()))
        bombInfo.line.set_points(colisionpoint, vector.add(colisionpoint, vector.new(0, 0.1 * dist, 0)))
        bombInfo.line.set_width(0, 0.01 * dist)
        bombInfo.line.set_color(vector.new(1, 0, 0))
        if time.time() > launch + 0.02 then
          if time.time() > launch + 0.75 then
            BombKey.start()
            maneuver = aim(colisionpoint)
            bombElevator.set_steering(maneuver.y)
            bombRoll.set_steering(maneuver.x + 0.25 * (bomb.rotation().z - 180))
          else
            bombElevator.set_steering(-15)
            BombKey.stop()
          end
        end
      else
        bombInfo.line.set_points(vector.new(0, -1, 0), vector.new(0, -0.5, 0))
        ActiveBombs = remove(ActiveBombs, bombCont)
        BombKey.stop()
      end
    end
  end
  btn2 = input.get_key_down(JoyBtn2)
  click = input.get_key_down("Mouse0")
  clickHit = input.mouse_raycast_hit_point()
  if ((input.get_key_down(JoyBtn1) and target ~= nil) or (btn2 and hit) or (BombMode and click and (clickHit.x ~= 0 and clickHit.y ~= 0 and clickHit.z ~= 0))) and BombCont < NBOMBS then
    BombCont = BombCont + 1
    ActiveBombs[BombCont] = {}
    ActiveBombs[BombCont].b = machine_info.get_block_info("Bomb"..BombCont)
    ActiveBombs[BombCont].e = machine.get_refs_control("BombElevator"..BombCont)
    ActiveBombs[BombCont].r = machine.get_refs_control("BombRoll"..BombCont)
    ActiveBombs[BombCont].k = machine.new_key_emulator(bombDict[BombCont])
    ActiveBombs[BombCont].k.start()
    ActiveBombs[BombCont].l = time.time()
    ActiveBombs[BombCont].line = lines.new_line_renderer()
    if click then
      ActiveBombs[BombCont].t = mousetracker()
    else
      if btn2 then
        ActiveBombs[BombCont].t = newfixedTarget(hit.point)
      else
        ActiveBombs[BombCont].t = target
      end
    end
  end
  if FiveSeconds < time.time() then
    FiveSeconds = time.time() + 2
    ActivePlayers = {}
    NActivePlayers = 0
    cont = 1
    cycles = 0
    while cont < Ntargets do
      cycles = cycles + 1
      if not targets[cont].player then
        if targets[cont].health() <= 0 then
          targets = OrderedRemove(targets, cont)
          Ntargets = Ntargets - 1
          if cont < selectedTarget then
            selectedTarget = selectedTarget - 1
          end
        else
          cont = cont + 1
        end
      else
        if not targets[cont].is_simulating() then

          targets = OrderedRemove(targets, cont)
          Ntargets = Ntargets - 1
          if cont < selectedTarget then
            selectedTarget = selectedTarget - 1
          end
        else
          ActivePlayers[NActivePlayers] = targets[cont].id()
          NActivePlayers = NActivePlayers + 1
          cont = cont + 1
        end
      end
    end
    -- 46 40 60 2 13
    cont = 0
    while cont < players.count() do
      player = players.get(cont)
      if not contains(ActivePlayers, player.id()) then
        if player.is_simulating() then
          targets[Ntargets] = player
          targets[Ntargets].player = true
          targetMachine = player.get_machine_info()
          targetStartingBlock = targetMachine.get_block_info(0)
          targets[Ntargets].position = targetMachine.position
          targets[Ntargets].velocity = targetMachine.velocity
          contII = 1
          dist = nil
          while contII < targetMachine.block_count() do
            targetBlock = targetMachine.get_block_info(contII)
            if contains({2, 14, 34, 40, 43, 46, 60}, targetBlock.id()) then
              targetDist = vector.magnitude(vector.subtract(targetStartingBlock.position(), targetBlock.position()))
              if dist == nil then
                dist = targetDist
                targets[Ntargets].position = targetBlock.position
                targets[Ntargets].velocity = targetBlock.velocity
              else
                if dist > targetDist then
                  dist = targetDist
                  targets[Ntargets].position = targetBlock.position
                  targets[Ntargets].velocity = targetBlock.velocity
                end
              end
            end
            contII = contII + 1
          end
          Ntargets = Ntargets + 1
        end
      end
      cont = cont + 1
    end
    target = targets[selectedTarget]
  end
  -- called every frame
end

local function late_update()
  -- called every frame after update
end

local function fixed_update()
  clock = clock + 1
  -- frame-rate independent update (called 100 times per second)
end


local function dataWindow()
  gui.label(rect.new(30, 50, 360, 30), "Missiles: "..(NBOMBS - BombCont).."/"..NBOMBS)
  gui.label(rect.new(30, 65, 360, 30), bombOnAir.." missiles on air")
  if target ~= nil then
    gui.label(rect.new(30, 80, 360, 30), "Target "..selectedTarget.." of "..(Ntargets - 1))
    gui.label(rect.new(30, 95, 360, 30), target.name())
  else
    text = "No Target Selected"
    if Ntargets > 0 then
      text = text.." ("..(Ntargets - 1).." Avaliable)"
    end
    gui.label(rect.new(30, 80, 360, 30), text)
  end
  gui.drag_window()
end
local function on_gui()
  if not BombMode then
    if mode then
      text = "Hover"
    else
      text = "Plane"
    end
  else
    text = "Bomber"
  end
  gui.window(1000, rect.new(75, 250, 250, 175), text, dataWindow) -- draw unity gui window
end

return {
  play = play,
  update = update,
  late_update = late_update,
  fixed_update = fixed_update,
  on_gui = on_gui,
}
