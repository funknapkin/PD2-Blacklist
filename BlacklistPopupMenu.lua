if not BlacklistPopupMenu then
  -- Includes
  local import_success = pcall(dofile, ModPath .. "/GUITextInput.lua")
  if not import_success then
    -- Error importing file, log error and force exit
    Log("Importation error in Blacklist/BlacklistMenu.lua")
    os.exit()
  end

  BlacklistPopupMenu = class()

  --[[
  Initialize the pop-up menu.
  Args:
    blacklist_ref: Reference to the Blacklist object.
  --]]
  function BlacklistPopupMenu:init(blacklist_ref)
    self.blacklist_ref = blacklist_ref

    -- Build the menu items
    local menu_items = {}
    for _, userdata in ipairs(self.blacklist_ref:get_last_users_list()) do
      local menu_item = {}
      menu_item.text = userdata[1]
      menu_item.callback = function() self:on_item_clicked(userdata[2], userdata[1]) end
      table.insert(menu_items, menu_item)
    end

    -- Add a cancel option to the menu
    table.insert(menu_items, {text="", is_cancel_button=true})
    table.insert(menu_items, {text="Cancel", is_cancel_button=true})

    -- Build the actual menu
    local menu_title = "Blacklist user"
    local menu_message = "Add a user to the Blacklist"
    QuickMenu:new(menu_title, menu_message, menu_items, true)
  end

  --[[
  Function called when a menu item is clicked.
  Args:
    user_id: Steam id of the user that was selected.
  --]]
  function BlacklistPopupMenu:on_item_clicked(user_id, name)
    local input_complete_callback = function(text)
      self.blacklist_ref:add_user_to_blacklist(user_id, name, text)
    end
    local input_dialog = GUITextInput:new(input_complete_callback)
  end
end
