-- Includes
local import_success_input = pcall(dofile, ModPath .. "/GUITextInput.lua")
local import_success_popup = pcall(dofile, ModPath .. "/BlacklistPopupMenu.lua")
if not (import_success_input and import_success_popup) then
  -- Error importing file, log error and force exit
  Log("Importation error in Blacklist/BlacklistMenu.lua")
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

  -- Create menus and buttons
  self:_create_mod_options_menu()
  self:_create_popup_menu()
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
      self:_add_show_banned_toggle(menu_id)
      self:_add_show_not_banned_toggle(menu_id)
      self:_add_chat_name_button(menu_id)
      self:_add_chat_color_button(menu_id)
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

function BlacklistMenu:_create_popup_menu()
  Hooks:Add("MenuManagerPopulateCustomMenus", "BlacklistPopupMenu_Populate",
    function(menu_manager, nodes)
      MenuCallbackHandler.blacklist_popup_menu_callback = function(this, item)
        BlacklistPopupMenu:new(self.blacklist_ref)
      end
      MenuHelper:AddButton({
        id = "blacklist_button_popup_menu",
        title = "blacklist_button_popup_menu_title",
        desc = "blacklist_button_popup_menu_desc",
        callback = "blacklist_popup_menu_callback",
        menu_id = "blacklist_options_menu"
      })
    end)
end

--[[
Add a toggle button for the "Show banned users" option.
--]]
function BlacklistMenu:_add_show_banned_toggle(parent_menu_id)
  MenuCallbackHandler.blacklist_toggle_show_banned_callback = function(this, item)
    self.blacklist_ref:set_show_banned(not self.blacklist_ref:get_show_banned())
  end
  MenuHelper:AddToggle({
    id = "blacklist_toggle_show_banned",
    title = "blacklist_toggle_show_banned_title",
    desc = "blacklist_toggle_show_banned_desc",
    callback = "blacklist_toggle_show_banned_callback",
    value = self.blacklist_ref:get_show_banned(),
    menu_id = parent_menu_id
  })
end

--[[
Add a toggle button for the "Show not banned users" option.
--]]
function BlacklistMenu:_add_show_not_banned_toggle(parent_menu_id)
  MenuCallbackHandler.blacklist_toggle_show_not_banned_callback = function(this, item)
    self.blacklist_ref:set_show_not_banned(not self.blacklist_ref:get_show_not_banned())
  end
  MenuHelper:AddToggle({
    id = "blacklist_toggle_show_not_banned",
    title = "blacklist_toggle_show_not_banned_title",
    desc = "blacklist_toggle_show__notbanned_desc",
    callback = "blacklist_toggle_show_not_banned_callback",
    value = self.blacklist_ref:get_show_not_banned(),
    menu_id = parent_menu_id
  })
end

--[[
Add a button to change the "Chat name" option.
--]]
function BlacklistMenu:_add_chat_name_button(parent_menu_id)
  MenuCallbackHandler.blacklist_button_chat_name_callback = function(this, item)
    local input_complete_callback = function(text)
      self.blacklist_ref:set_chat_name(text)
    end
    local input_dialog = GUITextInput:new(input_complete_callback)
  end
  MenuHelper:AddButton({
    id = "blacklist_button_chat_name",
    title = "blacklist_button_chat_name_title",
    desc = "blacklist_button_chat_name_desc",
    callback = "blacklist_button_chat_name_callback",
    menu_id = parent_menu_id
  })
end

--[[
Add a button to change the "Chat color" option.
--]]
function BlacklistMenu:_add_chat_color_button(parent_menu_id)
  MenuCallbackHandler.blacklist_button_chat_color_callback = function(this, item)
    local input_complete_callback = function(text)
      self.blacklist_ref:set_chat_color(text)
    end
    local input_dialog = GUITextInput:new(input_complete_callback)
  end
  MenuHelper:AddButton({
    id = "blacklist_button_chat_color",
    title = "blacklist_button_chat_color_title",
    desc = "blacklist_button_chat_color_desc",
    callback = "blacklist_button_chat_color_callback",
    menu_id = parent_menu_id
  })
end
