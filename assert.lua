--[[
Replace the built-in assert function to write a message in the log when an
error occurs.
--]]
function bl_assert(condition, message)
  local ok, errmsg = pcall(assert, condition, message)
  if type(errmsg) ~= "string" then
    errmsg = "Unknown Error"
  end
  if not ok then
    log("[Blacklist] " .. errmsg)
    error(errmsg)
  end
end
