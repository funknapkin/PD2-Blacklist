require( ModPath .. "/BlacklistMenu.lua" )

if not Blacklist then
  -- Note: this script seems to get reset everytime the game changes "state".
  -- i.e. lobby->planning->game

  Blacklist = {}

  --[[
  Constructor.
  Loads settings and the blacklist from files, or use default options if they
  don't exist.
  --]]
  function Blacklist:init()
    self:load_config()
    self:load_user_list()
    self.chat_backlog = {}

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
    -- Load the json file's content into the json object
    local directory = SavePath or ""
    local filepath = directory .. "blacklist_userlist.json"
    local json_string
    local file = io.open(filepath, "r")
    if file then
      json_string = file:read("*a")
      self.users = json.decode(json_string)
      file:close()
    else
      self.users = {}
    end
  end

  --[[
  Save the user list to a json file.
  Return:
    true if file was written, false if an error occured.
  --]]
  function Blacklist:save_user_list()
    -- Create json string and make it human-readable
    -- Some usernames might mess with the formatting. Should be rare.
    local json_string = json.encode(self.users)
    json_string = json_string:gsub("(\".-\":%[\".-\",\".-\"%])", "%1\n")
    --"(\".-\":%[.-%])"
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
    if type(message) ~= "string" or message == "" then
      return
    end

    local directory = SavePath or ""
    local filepath = directory .. "blacklist_backlog.json"
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
    local filepath = directory .. "blacklist_backlog.json"
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
  Function called when a new player connects to the game.
  Displays a chat message if the user is in the blacklist, or if the
  option to display all users is enabled.
  --]]
  function Blacklist:on_peer_added(name, user_id)
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
    if type(new_show_banned) == "boolean" then
      self.show_banned = new_show_banned
    end
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
    if type(new_show_not_banned) == "boolean" then
      self.show_not_banned = new_show_not_banned
    end
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
    if type(new_chat_name) == "string" then
      self.chat_name = new_chat_name
    end
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
    if type(new_chat_color) == "string" then
      -- Validate that the new string follows the format "aarrggbb"
      if #new_chat_color == 8 and new_chat_color:find("^[0-9a-f]+$") ~= nil then
        self.chat_color = new_chat_color
      end
    end
  end

  --[[
  Returns true if a user is in the blacklist, false otherwise
  --]]
  function Blacklist:is_user_in_blacklist(user_id)
    assert(type(self.users) == "table")
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
    assert(type(self.users) == "table")

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
    assert(type(self.users) == "table")
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
    assert(type(self.users) == "table")
    assert(type(user_id) == "string")
    assert(type(username) == "string")
    assert(type(reason) == "string")

    -- Add (or replace) the entry in the user list
    self.users[user_id] = {username, reason}
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
    self:save_user_list()
    self:load_user_list()
    self:save_user_list()
    self:load_user_list()
    self:save_user_list()
    self:load_user_list()
    self:write_to_chat("Tests finished")
  end

  Blacklist:init()
  Blacklist:debug_print("Blacklick initialized.")
end
