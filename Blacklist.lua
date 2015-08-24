if not Blacklist then
  -- Note: this script seems to get reset everytime the game changes "state".
  -- i.e. lobby->planning->game

  -- Import scripts needed for the Blacklist mod
  local import_success_assert = pcall(dofile, ModPath .. "/assert.lua")
  local import_success_menu = pcall(dofile, ModPath .. "/BlacklistMenu.lua")
  if not (import_success_assert and import_success_menu) then
    -- Error importing file, log error and force exit
    log("Importation error in Blacklist/Blacklist.lua")
    os.exit()
  end

  -- Overwrite the assert function for this script only. Necessary to do this
  -- here since BLT doesn't seem to support the "require" function...
  local assert = bl_assert

  Blacklist = {}

  --[[
  Constructor.
  Loads settings and the blacklist from files, or use default options if they
  don't exist.
  --]]
  function Blacklist:init()
    self:load_config()
    self:load_user_list()

    LocalizationManager:load_localization_file(ModPath .. "/localization_data.json")
    BlacklistMenu:init(self)
  end

  --[[
  Load the config file. If it doesn't exists or some options are missing,
  default values are used.
  --]]
  function Blacklist:load_config()
    -- Define default values
    self.show_banned = true
    self.show_not_banned = false
    self.chat_name = "Blacklist"
    self.chat_color = "ffff0000" -- argb
    -- Load the json file's content into the json object
    local directory = SavePath or ""
    local filepath = directory .. "blacklist_config.json"
    local json_string
    local json_object
    local file = io.open(filepath, "r")
    if file then
      json_string = file:read("*a")
      json_object = json.decode(json_string)
      file:close()
    else
      json_object = {}
    end
    -- Assign values from the config to this object
    if json_object["show_banned"] ~= nil then
      self:set_show_banned(json_object["show_banned"])
    end
    if json_object["show_not_banned"] ~= nil then
      self:set_show_not_banned(json_object["show_not_banned"])
    end
    if json_object["chat_name"] ~= nil then
      self:set_chat_name(json_object["chat_name"])
    end
    if json_object["chat_color"] ~= nil then
      self:set_chat_color(json_object["chat_color"])
    end
  end

  --[[
  Save all current options to the config file.
  Return:
    true if file was written, false if an error occured.
  --]]
  function Blacklist:save_config()
    local json_object = {}
    json_object["config_version"] = 1
    -- Options to save
    json_object["show_banned"] = self:get_show_banned()
    json_object["show_not_banned"] = self:get_show_not_banned()
    json_object["chat_name"] = self:get_chat_name()
    json_object["chat_color"] = self:get_chat_color()
    -- Create json string and make it human-readable
    local json_string = json.encode(json_object)
    json_string = json_string:gsub(",(\".-\":)", ",\n %1")
    -- Save json string to file
    local directory = SavePath or ""
    local filepath = directory .. "blacklist_config.json"
    local file = io.open(filepath, "w")
    if file then
      file:write(json_string)
      file:close()
      return true
    else
      return false
    end
  end

  --[[
  Load the user list. If an error occurs or the file doesn't exist, initialize
  the blacklist with an empty list.
  --]]
  function Blacklist:load_user_list()
    -- Fallback value in case loading fails
    self.users = {}
    -- Load the json file's content into the json object
    local directory = SavePath or ""
    local filepath = directory .. "blacklist_userlist.json"
    local json_string
    local file = io.open(filepath, "r")
    if file then
      json_string = file:read("*a")
      file:close()
      -- Workaround for a bug: pcall doesn't catch the errors thrown by json.decode
      -- We avoid trying to decode en empty array
      if json_string ~= "[]" then
        local decode_success, users = pcall(json.decode, json_string)
        if decode_success then
          self.users = users
        end
      end
    end
  end

  --[[
  Save the user list to a json file.
  Return:
    true if file was written, false if an error occured.
  --]]
  function Blacklist:save_user_list()
    if #self.users > 0 then
      -- Create json string
      local json_string = json.encode(self.users)
      -- Save json string to file
      local directory = SavePath or ""
      local filepath = directory .. "blacklist_userlist.json"
      local file = io.open(filepath, "w")
      if file then
        file:write(json_string)
        file:close()
        return true
      else
        return false
      end
    end
  end

  --[[
  Display a text message in the chat box. If the chat box doesn't exist,
  add the message to a message backlog.
  --]]
  function Blacklist:write_to_chat(message)
    message = tostring(message)
    if managers
        and managers.chat
        and managers.chat._receivers
        and managers.chat._receivers[1]
    then
      -- Chat is initialized, write message to chat.
      if Color then
        managers.chat:_receive_message(
          managers.chat.GAME, self:get_chat_name(), message, Color(self:get_chat_color()))
      end
    else
      -- Chat not initialized, add message to the backlog.
      self:add_to_backlog(message)
    end
  end

  --[[
  Add a message to the backlog.
  Since the script gets reset when the game changes state and there seems
  to be no way to make a truly persistent variable, the backlog is
  written to a file.
  --]]
  function Blacklist:add_to_backlog(message)
    assert(type(message) == "string", "Wrong argument type in add_to_backlog")
    if message == "" then
      return
    end

    local directory = SavePath or ""
    local filepath = directory .. "blacklist_backlog.txt"
    local file = io.open(filepath, "a")
    if file then
      file:write(message .. "\n")
      file:close()
    end
  end

  --[[
  Clear the chat messages backlog by showing these messages in chat. Should
  be called after chat is initialized, otherwise the backlog will remain.
  --]]
  function Blacklist:clear_backlog()
    -- Check if chat is initialized.
    if not (managers and
            managers.chat and
            managers.chat._receivers and
            managers.chat._receivers[1] )
    then
      return
    end
    -- Load the backlog from the file into a variable
    local directory = SavePath or ""
    local filepath = directory .. "blacklist_backlog.txt"
    local backlog = {}
    local file = io.open(filepath, "r")
    if file then
      for line in file:lines() do
        backlog[#backlog + 1] = line
      end
      file:close()
    else
      return
    end
    -- Delete the backlog file
    os.remove(filepath)
    -- Write the backlog to chat
    for _,message in pairs(backlog) do
      self:write_to_chat(message)
    end
  end

  --[[
  Check all connected players to see if they are in the blacklist.
  Displays a message for each user in the blacklist.
  --]]
  function Blacklist:manual_check()
    for _, peer in pairs(managers.network:session():peers()) do
      local name = peer:name()
      local user_id = peer:user_id()
      self:on_peer_added(name, user_id)
    end
  end

  --[[
  Add a user to the last users list.
  Args:
    name: Name of the user to add (string)
    user_id: Steam ID of the user to add (string)
  Returns:
    true if the user was added successfully, false otherwise
  --]]
  function Blacklist:add_user_to_last_users_list(name, user_id)
    assert(type(name) == "string", "Wrong argument type in add_user_to_last_users_list")
    assert(type(user_id) == "string", "Wrong argument type in add_user_to_last_users_list")

    local last_users_list = self:get_last_users_list()

    -- Remove the user from the list if he already exists
    local user_exists_in_list = false
    local user_index_in_list = 0
    for index, userdata in ipairs(last_users_list) do
      if user_id == userdata[2] then
        user_exists_in_list = true
        user_index_in_list = index
        break
      end
    end
    if user_exists_in_list then
      table.remove(last_users_list, user_index_in_list)
    end

    -- Add user to the last users list
    table.insert(last_users_list, 1, {name, user_id})

    -- Crop list to the last 10 users
    last_users_list[11] = nil

    -- Save last users list to a json file
    local json_string = json.encode(last_users_list)
    local directory = SavePath or ""
    local filepath = directory .. "blacklist_last_users.json"
    local file = io.open(filepath, "w")
    if file then
      file:write(json_string)
      file:close()
      return true
    else
      return false
    end
  end

  --[[
  Get the last users who connected to the game. The list is ordered to return
  the most recent users first.
  Returns:
    An array with the last connected users. Format is as follows:
    {{name1, user_id1}, {name2, user_id2}, ...}
  --]]
  function Blacklist:get_last_users_list()
    -- Load the json file's content into the json object
    local directory = SavePath or ""
    local filepath = directory .. "blacklist_last_users.json"
    local json_string
    local file = io.open(filepath, "r")
    local last_users_list = {}
    if file then
      json_string = file:read("*a")
      last_users_list = json.decode(json_string)
      file:close()
    end
    return last_users_list
  end

  --[[
  Function called when a new player connects to the game.
  Displays a chat message if the user is in the blacklist, or if the
  option to display all users is enabled.
  --]]
  function Blacklist:on_peer_added(name, user_id)
    assert(type(name) == "string", "Wrong argument type in on_peer_added")
    assert(type(user_id) == "string", "Wrong argument type in on_peer_added")

    -- Log user
    self:add_user_to_last_users_list(name, user_id)

    -- Display chat notifications
    local user_is_in_blacklist = self:is_user_in_blacklist(user_id)
    if user_is_in_blacklist and self:get_show_banned() then
      local _, ban_reason = self:get_user_data(user_id)
      self:write_to_chat(name .. " is in the blacklist: " .. ban_reason)
    elseif (not user_is_in_blacklist) and self:get_show_not_banned() then
      self:write_to_chat(name .. " is not in the blacklist")
    end
  end

  --[[
  Function called after the chat boxes are initialized.
  Clears the backlog that was accumulated while chat was unavailable.
  --]]
  function Blacklist:on_chat_init()
    self:clear_backlog()
  end

  --[[
  Get the option to display a message when users in the blacklist join the
  game.
  --]]
  function Blacklist:get_show_banned()
    return self.show_banned
  end

  --[[
  Set the option to display a message when users in the blacklist join the
  game.
  --]]
  function Blacklist:set_show_banned(new_show_banned)
    assert(type(new_show_banned) == "boolean", "Wrong argument type in set_show_banned")
    self.show_banned = new_show_banned
  end

  --[[ Get the option to display a message when users who are not in the
  blacklist join the game
  --]]
  function Blacklist:get_show_not_banned()
    return self.show_not_banned
  end

  --[[
  Set the option to display a message when users who are not in the
  blacklist join the game
  --]]
  function Blacklist:set_show_not_banned(new_show_not_banned)
    assert(type(new_show_not_banned) == "boolean", "Wrong argument type in set_show_not_banned")
    self.show_not_banned = new_show_not_banned
  end

  --[[
  Get the username used by the blacklist when showing chat messages
  --]]
  function Blacklist:get_chat_name()
    return self.chat_name
  end

  --[[
  Set the username used by the blacklist when showing chat messages
  --]]
  function Blacklist:set_chat_name(new_chat_name)
    assert(type(new_chat_name) == "string", "Wrong argument type in new_chat_name")
    self.chat_name = new_chat_name
  end

  --[[
  Get the color used by the blacklist when showing chat messages. This color
  is used for the username of the message sender.
  ]]
  function Blacklist:get_chat_color()
    return self.chat_color
  end

  --[[
  Set the color used by the blacklist when showing chat messages. This color
  is used for the username of the message sender.
  --]]
  function Blacklist:set_chat_color(new_chat_color)
    assert(type(new_chat_color) == "string", "Wrong argument type in set_chat_color")
    -- Validate that the new string represents an hexadecimal value
    local new_chat_color = new_chat_color:lower()
    if new_chat_color:find("^[0-9a-f]+$") ~= nil then
      if #new_chat_color == 8 then
        -- String follows the format "aarrggbb"
        self.chat_color = new_chat_color
      elseif #new_chat_color == 6 then
        -- String follow the format "rrggbb", use default alpha value
        self.chat_color = "ff" .. new_chat_color
      end
    end
  end

  --[[
  Returns true if a user is in the blacklist, false otherwise
  --]]
  function Blacklist:is_user_in_blacklist(user_id)
    assert(type(self.users) == "table", "Userlist corrupted/uninitialized in is_user_in_blacklist")
    -- If there is an entry in the table for that user, he's in the blacklist
    return self.users[user_id] ~= nil
  end

  --[[
  Get the data associatied with a user id.
  Returns:
    A tuple with the following values, in the following order:
      - Name of the user when he was added to the list
      - Reason the user was added to the list
    Returns nil if the user is not in the blacklist
  --]]
  function Blacklist:get_user_data(user_id)
    assert(type(self.users) == "table", "Userlist corrupted/uninitialized in get_user_data")

    local userdata = self.users[user_id]
    if type(userdata) == "table" then
      return unpack(userdata)
    else
      return nil
    end
  end

  --[[
  Returns an iterator to go through all ids in the blacklist.
  Each iteration returns a string with the user id.
  --]]
  function Blacklist:ids_in_blacklist()
    assert(type(self.users) == "table", "Userlist corrupted/uninitialized in ids_in_blacklist")
    -- Fill a list with all user ids
    local user_ids = {}
    for user_id, _ in pairs(self.users) do
      user_ids[#user_ids + 1] = user_id
    end
    -- Return an iterator
    local iter_i = 0
    return function()
        iter_i = iter_i + 1
        if iter_i > #user_ids then
          -- End of iteration
          return nil
        else
          -- Return the current user id
          return user_ids[iter_i]
        end
      end
  end

  --[[
  Add a user to the blacklist.
  Args:
    user_id (string): User id.
    username (string): Display name of the user (steam name).
    reason (string): Text that explains why a user is added to the blacklist.
  --]]
  function Blacklist:add_user_to_blacklist(user_id, username, reason)
    assert(type(self.users) == "table", "Userlist corrupted/uninitialized in add_user_to_blacklist")
    assert(type(user_id) == "string", "Wrong argument type in add_user_to_blacklist")
    assert(type(username) == "string", "Wrong argument type in add_user_to_blacklist")
    assert(type(reason) == "string", "Wrong argument type in add_user_to_blacklist")

    -- Add (or replace) the entry in the user list
    self.users[user_id] = {username, reason}
  end

  --[[
  Remove a user from the blacklist, if he exists.
  --]]
  function Blacklist:remove_user_from_blacklist(user_id)
    assert(type(self.users) == "table", "Userlist corrupted/uninitialized in remove_user_from_blacklist")
    assert(type(user_id) == "string", "Wrong argument type in remove_user_from_blacklist")
    self.users[user_id] = nil
  end

  --[[
    Function to write a message to a text file. Used for development and
    debug purposes.
  --]]
  function Blacklist:debug_print(msg)
    local directory = LogsPath or ""
    local filepath = directory .. "blacklist.log"
    local file = io.open(filepath, "a")
    if file then
      file:write(tostring(msg) .. "\r\n")
      file:close()
      return true
    else
      return false
    end
  end

  --[[
  Function to help development by running a few tests.
  --]]
  function Blacklist:run_tests()
    self:write_to_chat("Running tests")
    local import_success_input = pcall(dofile, ModPath .. "/GUITextInput.lua")
    if not import_success_input then
      return
    end
    local test = GUITextInput:new(
      "This is a test box with an unusually large title, so long in fact that it will go out of the box if there is no text wrapping",
      [[This is a test description
in a long string
over multiple lines
here's some garbage to test text wrapping: aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeffffffffffgggggggggghhhhhhhhhh]],
      function(...) return end
    )
    self:write_to_chat("Tests finished")
  end

  Blacklist:init()
end
