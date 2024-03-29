local C = require"Constants"
local TILE_SIZE = C.TILE_SIZE
local REVERSE = C.REVERSE
local state = system.state
local newImage = love.graphics.newImage
local draw = love.graphics.draw
local input = input
local pi = math.pi
local pairs = pairs

local circle = love.graphics.circle
local print = print
module("objects.GameObjectTemplate")

local imageUp = newImage("assets/objects/mcB.png")
local imageDown = newImage("assets/objects/mcF.png")
local imageLeft = newImage("assets/objects/mcL.png")
local imageRight = newImage("assets/objects/mcR.png")


local MOVE_COOLDOWN = 0.13

return function(x, y, properties)
  local public = {}
  -- Object Body --
  public.x = x or 0
  public.y = y or 0
  public.isPlayer = true
  _level = properties.level
  public.looking = properties.looking or "down" -- "up" "down" "left" "right"
  local _moveCooldown = 0
  local _history = {}
  local _historyCount = 0
  local _playbackCount = 0
  public.disabled = false
  local _holding = false



  public.update = function(dt, x, y)
    local isDown = input.isDown
    
    if input.pressed "record" and not state.endrecord then
      _history = {}
      _historyCount = 0
      _playbackCount = 0
    end

    if input.pressed "action" then
      local looking = public.looking
      local objects = _level.objects
      if      looking == "up" then
        local obj = objects[public.y-1][public.x]
        if obj and obj.toggle then
          obj.toggle()
        end
      elseif  looking == "down" then
        local obj = objects[public.y+1][public.x]
        if obj and obj.toggle then
          obj.toggle()
        end
      elseif  looking == "left" then
        local obj = objects[public.y][public.x-1]
        if obj and obj.toggle then
          obj.toggle()
        end
      elseif  looking == "right" then
        local obj = objects[public.y][public.x+1]
        if obj and obj.toggle then
          obj.toggle()
        end
      end
    elseif input.held "action" then
      local looking = public.looking
      local objects = _level.objects
      local obj = nil
      if      looking == "up" then
        obj = objects[public.y-1][public.x]
      elseif  looking == "down" then
        obj = objects[public.y+1][public.x]
      elseif  looking == "left" then
        obj = objects[public.y][public.x-1]
      elseif  looking == "right" then
        obj = objects[public.y][public.x+1]
      end

      if obj and obj.move then
        _holding = true
      end
    else
      _holding = false
    end

    --print("time:",state.time, "record:",state.record, "timesince:", state.timeSince)
    if state.record then
      _playbackCount = 0  
    end

    if _moveCooldown > 0 then
      _moveCooldown = _moveCooldown - dt
      if _moveCooldown < 0 then
        _moveCooldown = 0
      end
    else
      local move = public.move
      local face = public.face
      local isSolid = _level.isSolid
      local curx = public.x
      local cury = public.y
      if isDown"up" then
        if not isSolid(curx, cury-1) then
          move("up")
        end
        --if not _holding or public.looking == "up" or public.looking == "down" then
          face("up")
        --end
      elseif isDown"down" then
        if not isSolid(curx, cury+1) then
          move("down")
        end
        --if not _holding or public.looking == "down" or public.looking == "up" then
          face("down")
        --end
      elseif isDown"left" then
        if not isSolid(curx-1, cury) then
          move("left")
        end
        --if not _holding or public.looking == "left" or public.looking == "right" then
          face("left")
        --end
      elseif isDown"right" then
        if not isSolid(curx+1, cury) then
          move("right")
        end
        --if not _holding or public.looking == "right" or public.looking == "left" then
          face("right")
        --end
      end
    end
    public.disabled = false
  end


  public.draw = function(x, y)
    local looking = public.looking
    local image = nil
    if      looking == "up" then
      image = imageUp
    elseif  looking == "left" then
      image = imageLeft
    elseif  looking == "right" then
      image = imageRight
    elseif looking == "down" then
      image = imageDown
    end
    draw(image, x+(public.x-1)*TILE_SIZE, y+(public.y-1)*TILE_SIZE)
  end

  public.kill = function()
    print("ouch!")
  end

  ----------
  -- TIME --
  ----------
  public.rewind = function()
    for i,v in pairs(_history) do
      print(i,v[1], v[2], v[3])
    end
    print()
  end

  -------------
  -- ACTIONS --
  -------------
  public.face = function(direction)
    if state.record then
      _historyCount = _historyCount + 1
      _history[_historyCount] = {state.timeSince, public.face, direction, public.looking}
    end
    public.looking = direction
  end

  public.move = function(direction)
    if public.disabled then return false end

    local isSolid = _level.isSolid
    local isPushed = isPushed or false
    if direction == "up" then
      local newy = public.y - 1
      if not isSolid(public.x, newy) then
        local obj = _level.objectAt(public.x, newy)
        if obj and obj.move then
          if not obj.move("up") then
            return false
          else
            obj.disabled = true
          end
        end
        _level.objects[public.y][public.x] = nil
        public.y = newy
        _moveCooldown = MOVE_COOLDOWN
        _level.objects[public.y][public.x] = public 
        if state.record then
          _historyCount = _historyCount + 1
          _history[_historyCount] = {state.timeSince, public.move, "up"}
        end
        return true
      end
    elseif direction == "down" then
      local newy = public.y + 1
      if not isSolid(public.x, newy) then
        local obj = _level.objectAt(public.x, newy)
        if obj and obj.move then
          if not obj.move("down") then
            return false
          else
            obj.disabled = true
          end
        end
        _level.objects[public.y][public.x] = nil
        public.y = newy
        _moveCooldown = MOVE_COOLDOWN
        _level.objects[public.y][public.x] = public
        if state.record then
          _historyCount = _historyCount + 1
          _history[_historyCount] = {state.timeSince, public.move, "down"}
        end 
        return true
      end
    elseif direction == "left" then
      local newx = public.x - 1
      if not isSolid(newx, public.y) then
        local obj = _level.objectAt(newx, public.y)
        if obj and obj.move then
          if not obj.move("left") then
            return false
          else
            obj.disabled = true
          end
        end
        _level.objects[public.y][public.x] = nil
        public.x = newx
        _moveCooldown = MOVE_COOLDOWN
        _level.objects[public.y][public.x] = public 
        if state.record then
          _historyCount = _historyCount + 1
          _history[_historyCount] = {state.timeSince, public.move, "left"}
        end
        return true
      end
    elseif direction == "right" then
      local newx = public.x + 1
      if not isSolid(newx, public.y) then
        local obj = _level.objectAt(newx, public.y)
        if obj and obj.move then
          if not obj.move("right") then
            return false
          else
            obj.disabled = true
          end
        end
        _level.objects[public.y][public.x] = nil
        public.x = newx
        _moveCooldown = MOVE_COOLDOWN
        _level.objects[public.y][public.x] = public 
        if state.record then
          _historyCount = _historyCount + 1
          _history[_historyCount] = {state.timeSince, public.move, "right"}
        end
        return true
      end
    end
  end


	return public
end