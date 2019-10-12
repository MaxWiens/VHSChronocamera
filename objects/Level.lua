local input = input
local state = system.state
local RECORD_TOTAL = require "Constants".RECORD_TOTAL

local print = print
module("objects.GameObjectTemplate")

return function(x, y, properties)
  local public = {}
	-- Object Body --
  local _map = properties.map
  local _player = properties.player
  local _height = properties.height
  local _width = properties.width

  local _objects = properties.objects
  local _stepCount = 0
  state.time = "normal"
  state.record = false
  state.timeSince = 0
  public.update = function(dt)
    local time = state.time
    local record = state.record
    if time == "normal" then
      if state.record then
        state.timeSince = state.timeSince + dt
        if state.timeSince >= RECORD_TOTAL then
          state.record = false
        end
      end
      if input.pressed "record" then
        if record then
          state.record = false
        else
          state.record = true
        end
      elseif input.pressed "rewind" then
        state.record = false
        state.time = "rewind"
      end

    end

    if time == "rewind" then
      if state.timeSince <= 0 then
        state.time = "normal"
        state.timeSince = 0
      else
        state.timeSince = state.timeSince - dt
      end
    elseif time == "play" then
    end
  end

  public.isSolid = function(x,y)
    if x <= _width and x >= 1 and y <= _height and y >= 1 then
      
      local obj = _objects[y][x] 
      if obj and obj.isSolid then
        return true
      end

      if _map[(y-1)*_width+x] > 0 then
        return true
      end
    end
    return false
  end

  public.objectAt = function(x,y)
    return _objects[y][x]
  end

	return public
end