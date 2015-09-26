--[[
Base class for the Blacklist mod. It keeps track of all the data necessary for
the mod, such as the user list, and offers utility functions.
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
Functions to keep track of the last users who joined the game.
--]]
function Blacklist:add_user_to_last_users_list(name, user_id) end
function Blacklist:get_last_users_list() end

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
Members (private)
--]]
Blacklist.show_banned = bool
Blacklist.show_not_banned = bool
Blacklist.chat_name = string
Blacklist.chat_color = string
Blacklist.users = array
