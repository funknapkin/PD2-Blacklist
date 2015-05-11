BlacklistMenu = {}

--[[
Constructor for the Blacklist menu.
Args:
  blacklist_ref: Reference to the Blacklist object.
--]]
function BlacklistMenu:init(blacklist_ref)
  -- Save reference to the Blacklist object
  self.blacklist_ref = blacklist_ref

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
    end)

  -- Add hook to build the menu
  Hooks:Add("MenuManagerBuildCustomMenus", "BlacklistOptionsMenu_Build",
    function(menu_manager, nodes)
      -- Add this menu to the Mod Options menu
      nodes[menu_id] = MenuHelper:BuildMenu(menu_id)
      local mod_options_menu = MenuHelper:GetMenu("lua_mod_options_menu")
      MenuHelper:AddMenuItem(
        mod_options_menu,
        menu_id,
        "blacklist_options_menu_title",
        "blacklist_options_menu_desc")
    end)
end
