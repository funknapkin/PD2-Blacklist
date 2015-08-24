-- Includes
local import_success_input = pcall(dofile, ModPath .. "/GUITextInput.lua")
local import_success_popup = pcall(dofile, ModPath .. "/BlacklistPopupMenu.lua")
if not (import_success_input and import_success_popup) then
  -- Error importing file, log error and force exit
  log("Importation error in Blacklist/BlacklistMenu.lua")
  os.exit()
end

BlacklistMenu = {}

--[[
Constructor for the Blacklist menu.
Args:
  blacklist_ref: Reference to the Blacklist object.
--]]
function BlacklistMenu:init(blacklist_ref)
  -- Save reference to the Blacklist object
  self.blacklist_ref = blacklist_ref

  self.userid_for_removal = ""

  -- Create menus and buttons
  self:_create_mod_options_menu()
end

--[[
Function called when the user exits the options menu.
--]]
function BlacklistMenu:back_button_callback()
  self.blacklist_ref:save_config()
  self.blacklist_ref:save_user_list()
end

--[[
Add a "Blacklist" menu to the BLT's Mod Options menu.
--]]
function BlacklistMenu:_create_mod_options_menu()
  -- Menu and button ids
  local menu_id = "blacklist_options_menu"

  -- Add hook to create options menu
  Hooks:Add("MenuManagerSetupCustomMenus", "BlacklistOptionsMenu_Setup",
    function(menu_manager, nodes)
      MenuHelper:NewMenu(menu_id)
    end)

  -- Add hook to populate the menu
  Hooks:Add("MenuManagerPopulateCustomMenus", "BlacklistOptionsMenu_Populate",
    function(menu_manager, nodes)
      self:_add_add_player_to_blacklist_button(menu_id, 8)
      self:_add_remove_player_from_blacklist_selector(menu_id, 7)
      self:_add_remove_player_from_blacklist_button(menu_id, 6)
      MenuHelper:AddDivider({id = "blacklist_opt_divider", size = 16,
        menu_id = menu_id, priority = 5})
      self:_add_chat_color_button(menu_id, 4)
      self:_add_chat_name_button(menu_id, 3)
      self:_add_show_banned_toggle(menu_id, 2)
      self:_add_show_not_banned_toggle(menu_id, 1)
    end)

  -- Add hook to build the menu
  Hooks:Add("MenuManagerBuildCustomMenus", "BlacklistOptionsMenu_Build",
    function(menu_manager, nodes)
      -- Add this menu to the Mod Options menu
      local menu_data = {back_callback = function() self:back_button_callback() end}
      nodes[menu_id] = MenuHelper:BuildMenu(menu_id, menu_data)
      local mod_options_menu = MenuHelper:GetMenu("lua_mod_options_menu")
      MenuHelper:AddMenuItem(
        mod_options_menu,
        menu_id,
        "blacklist_options_menu_title",
        "blacklist_options_menu_desc")
    end)
end

--[[
Add a button to add a player to the blacklist.
--]]
function BlacklistMenu:_add_add_player_to_blacklist_button(parent_menu_id, priority)
  MenuCallbackHandler.blacklist_popup_menu_callback = function(this, item)
    BlacklistPopupMenu:new(self.blacklist_ref)
  end
  MenuHelper:AddButton({
    id = "blacklist_button_popup_menu",
    title = "blacklist_button_popup_menu_title",
    desc = "blacklist_button_popup_menu_desc",
    callback = "blacklist_popup_menu_callback",
    priority = priority,
    menu_id = parent_menu_id
  })
end

--[[
Add a choice field to choose the player to remove from the blacklist.
--]]
function BlacklistMenu:_add_remove_player_from_blacklist_selector(parent_menu_id, priority)
  -- Build user list, sorted by user name
  local users = {} -- array with tuples of format {user_name, user_id}
  for user_id in self.blacklist_ref:ids_in_blacklist() do
    local user_name = self.blacklist_ref:get_user_data(user_id)
    table.insert(users, {user_name, user_id})
  end
  local sortTuplesByFirstElements = function (elem1, elem2)
    return elem1[1] < elem2[1]
  end
  table.sort(users, sortTuplesByFirstElements)

  -- If there are no users to remove, create a default entry to display the choice menu
  if #users < 1 then
    users = {{"", "dummy_steam_id"}}
  end

  -- Build an array of usernames to display and add them to BLT's localization
  -- data, because it's silly and won't take raw strings
  local user_names = {}
  local localized_strings = {}
  for _, user_data in ipairs(users) do
    -- The username has a prefix to avoid name clashes
    local user_name_with_prefix = "blacklist_user_" .. user_data[1]
    table.insert(user_names, user_name_with_prefix)
    localized_strings[user_name_with_prefix] = user_data[1]
  end
  LocalizationManager:add_localized_strings(localized_strings)

  -- Initialize the callback for the choice
  self.userid_for_removal = users[1][2]
  MenuCallbackHandler.blacklist_choice_remove_player_callback = function(this, item)
    local index_for_removal = item._current_index
    if #users >= index_for_removal then
      self.userid_for_removal = users[item._current_index][2]
    end
  end

  MenuHelper:AddMultipleChoice({
      id = "blacklist_choice_remove_player",
      title = "blacklist_choice_remove_player_title",
      desc = "blacklist_choice_remove_player_desc",
      callback = "blacklist_choice_remove_player_callback",
      items = user_names,
      value = 1,
      priority = priority,
      menu_id = parent_menu_id,
  })
end

--[[
Add a button to remove a player from the blacklist.
--]]
function BlacklistMenu:_add_remove_player_from_blacklist_button(parent_menu_id, priority)
  MenuCallbackHandler.blacklist_button_remove_player_callback = function(this, item)
    self.blacklist_ref:remove_user_from_blacklist(self.userid_for_removal)
  end
  MenuHelper:AddButton({
    id = "blacklist_button_remove_player",
    title = "blacklist_button_remove_player_title",
    desc = "blacklist_button_remove_player_desc",
    callback = "blacklist_button_remove_player_callback",
    priority = priority,
    menu_id = parent_menu_id
  })
end

--[[
Add a toggle button for the "Show banned users" option.
--]]
function BlacklistMenu:_add_show_banned_toggle(parent_menu_id, priority)
  MenuCallbackHandler.blacklist_toggle_show_banned_callback = function(this, item)
    self.blacklist_ref:set_show_banned(not self.blacklist_ref:get_show_banned())
  end
  MenuHelper:AddToggle({
    id = "blacklist_toggle_show_banned",
    title = "blacklist_toggle_show_banned_title",
    desc = "blacklist_toggle_show_banned_desc",
    callback = "blacklist_toggle_show_banned_callback",
    value = self.blacklist_ref:get_show_banned(),
    priority = priority,
    menu_id = parent_menu_id
  })
end

--[[
Add a toggle button for the "Show not banned users" option.
--]]
function BlacklistMenu:_add_show_not_banned_toggle(parent_menu_id, priority)
  MenuCallbackHandler.blacklist_toggle_show_not_banned_callback = function(this, item)
    self.blacklist_ref:set_show_not_banned(not self.blacklist_ref:get_show_not_banned())
  end
  MenuHelper:AddToggle({
    id = "blacklist_toggle_show_not_banned",
    title = "blacklist_toggle_show_not_banned_title",
    desc = "blacklist_toggle_show__notbanned_desc",
    callback = "blacklist_toggle_show_not_banned_callback",
    value = self.blacklist_ref:get_show_not_banned(),
    priority = priority,
    menu_id = parent_menu_id
  })
end

--[[
Add a toggle button for the "Show not banned users" option.
--]]
function BlacklistMenu:_add_show_not_banned_toggle(parent_menu_id, priority)
  MenuCallbackHandler.blacklist_toggle_show_not_banned_callback = function(this, item)
    self.blacklist_ref:set_show_not_banned(not self.blacklist_ref:get_show_not_banned())
  end
  MenuHelper:AddToggle({
    id = "blacklist_toggle_show_not_banned",
    title = "blacklist_toggle_show_not_banned_title",
    desc = "blacklist_toggle_show__notbanned_desc",
    callback = "blacklist_toggle_show_not_banned_callback",
    value = self.blacklist_ref:get_show_not_banned(),
    priority = priority,
    menu_id = parent_menu_id
  })
end

--[[
Add a button to change the "Chat name" option.
--]]
function BlacklistMenu:_add_chat_name_button(parent_menu_id, priority)
  MenuCallbackHandler.blacklist_button_chat_name_callback = function(this, item)
    local input_complete_callback = function(text)
      self.blacklist_ref:set_chat_name(text)
    end
    local input_dialog = GUITextInput:new(
      "Chat name",
      "Enter a new chat name, used to display notifications in chat",
      input_complete_callback)
  end
  MenuHelper:AddButton({
    id = "blacklist_button_chat_name",
    title = "blacklist_button_chat_name_title",
    desc = "blacklist_button_chat_name_desc",
    callback = "blacklist_button_chat_name_callback",
    priority = priority,
    menu_id = parent_menu_id
  })
end

--[[
Add a button to change the "Chat color" option.
--]]
function BlacklistMenu:_add_chat_color_button(parent_menu_id, priority)
  MenuCallbackHandler.blacklist_button_chat_color_callback = function(this, item)
    local input_complete_callback = function(text)
      self.blacklist_ref:set_chat_color(text)
    end
    local input_dialog = GUITextInput:new(
      "Chat color",
      "Enter a new chat color, used to display notifications in chat",
      input_complete_callback)
  end
  MenuHelper:AddButton({
    id = "blacklist_button_chat_color",
    title = "blacklist_button_chat_color_title",
    desc = "blacklist_button_chat_color_desc",
    callback = "blacklist_button_chat_color_callback",
    priority = priority,
    menu_id = parent_menu_id
  })
end
