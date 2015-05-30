--[[
Class that handles the menu items for the Blacklist Mod. It adds options to
the Mod Option menu, as well as a button that shows in the in-game menu.
--]]

BlacklistMenu = {}

function BlacklistMenu:init(blacklist_ref) end

--[[
Button ballbacks
--]]
function BlacklistMenu:back_button_callback() end

--[[
Functions to build the interface.
--]]
function BlacklistMenu:_create_mod_options_menu() end
function BlacklistMenu:_create_popup_menu() end
function BlacklistMenu:_add_show_banned_toggle(parent_menu_id) end
function BlacklistMenu:_add_show_not_banned_toggle(parent_menu_id) end
function BlacklistMenu:_add_chat_name_button(parent_menu_id) end
function BlacklistMenu:_add_chat_color_button(parent_menu_id) end

--[[
Members.
--]]
BlacklistMenu.blacklist_ref = Blacklist
