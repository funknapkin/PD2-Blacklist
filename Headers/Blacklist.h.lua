--[[
"Header" files for Blacklist. It's never actually loaded, it is only used as
a reference.
As a C++ dev, I find browsing a barebones file with only the function and
member names very helpful for programming.
--]]

Blacklist = {}

function Blacklist:init() end

--[[
Functions to manage the config files.
--]]
function Blacklist:load_config() end
function Blacklist:save_config() end
function Blacklist:load_user_list() end
function Blacklist:save_user_list() end

--[[
Functions to manage chat and its backlog.
--]]
function Blacklist:write_to_chat(message) end
function Blacklist:add_to_backlog(message) end
function Blacklist:clear_backlog() end

function Blacklist:manual_check() end

--[[
Functions called on events.
--]]
function Blacklist:on_peer_added(name, user_id) end
function Blacklist:on_chat_init() end

--[[
Debug functions
--]]
function Blacklist:debug_print(msg) end
function Blacklist:run_tests() end

--[[
Members
--]]
Blacklist.show_not_banned = bool
Blacklist.show_not_banned = bool
Blacklist.chat_name = string
Blacklist.chat_color = string
