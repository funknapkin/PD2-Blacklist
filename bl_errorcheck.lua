local is_release_build = true

local function log_message_and_callstack(message)
  -- Build the string to log
  local strings_for_log = {"[Blacklist]", " "}
  if type(message) == "string" then
    table.insert(strings_for_log, message)
  else
    table.insert(strings_for_log, "Unknown error")
  end
  table.insert(strings_for_log, "\n")
  table.insert(strings_for_log, debug.traceback())
  -- Log the message
  log(table.concat(strings_for_log, ""))
end

--[[
Log the error and asserts if "condition" is false.
--]]
function bl_assert(condition, message)
  local ok, errmsg = pcall(assert, condition, message)
  if not ok then
    log_message_and_callstack(errmsg)
    if not is_release_build then
      error(errmsg)
    end
  end
end

--[[
Log an error and return false if "condition" is false
--]]
function bl_check(condition, message)
  if not condition then
    log_message_and_callstack(message)
    return false
  else
    return true
  end
end
