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
Member setters and getters
--]]
function Blacklist:get_show_banned() end
function Blacklist:set_show_banned(new_show_banned) end
function Blacklist:get_show_not_banned() end
function Blacklist:set_show_not_banned(new_show_not_banned) end
function Blacklist:get_chat_name() end
function Blacklist:set_chat_name(new_chat_name) end
function Blacklist:get_chat_color() end
function Blacklist:set_chat_color(new_chat_color) end

function Blacklist:is_user_in_blacklist(user_id) end
function Blacklist:get_user_data(user_id) end
function Blacklist:ids_in_blacklist() end
function Blacklist:add_user_to_blacklist(user_id, username, reason) end
function Blacklist:remove_user_from_blacklist(user_id) end

--[[
Debug functions
--]]
function Blacklist:debug_print(msg) end
function Blacklist:run_tests() end

--[[
Members (private)
--]]
Blacklist.show_banned = bool
Blacklist.show_not_banned = bool
Blacklist.chat_name = string
Blacklist.chat_color = string
Blacklist.users = array
