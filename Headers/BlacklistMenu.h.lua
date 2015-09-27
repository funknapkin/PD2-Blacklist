--[[
Class that handles the menu items for the Blacklist Mod. It adds options to
the Mod Option menu, as well as a button that shows in the in-game menu.
--]]

BlacklistMenu = {}

function BlacklistMenu:init(blacklist_ref) end

--[[
Button callbacks
--]]
function BlacklistMenu:back_button_callback() end

--[[
Functions to build the interface.
--]]
function BlacklistMenu:_create_mod_options_menu() end
function BlacklistMenu:_add_add_player_to_blacklist_button(parent_menu_id, priority) end
function BlacklistMenu:_add_remove_player_from_blacklist_selector(parent_menu_id, priority) end
function BlacklistMenu:_add_remove_player_from_blacklist_button(parent_menu_id, priority) end
function BlacklistMenu:_add_show_banned_toggle(parent_menu_id, priority) end
function BlacklistMenu:_add_show_not_banned_toggle(parent_menu_id, priority) end
function BlacklistMenu:_add_chat_name_button(parent_menu_id, priority) end
function BlacklistMenu:_add_chat_color_button(parent_menu_id, priority) end

--[[
Members.
--]]
BlacklistMenu.blacklist_ref = Blacklist
BlacklistMenu.userid_for_removal = string
