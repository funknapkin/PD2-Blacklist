local oldassert = assert

--[[
Replace the built-in assert function to write a message in the log when an
error occurs.
--]]
function assert(condition, message)
  ok, errmsg = pcall(oldassert, condition, message)
  if not ok then
    log("[Blacklist] " .. errmsg)
    error(errmsg)
  end
end
