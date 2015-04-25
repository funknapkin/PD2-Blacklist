if not Blacklist then
  local filepath = 'debug.log'
  local file = io.open(filepath, 'a')
  if file then
    file:write('Blacklist init' .. '\r\n')
    file:close()
  end
  -- Note: this script seems to get reset everytime the game changes 'state'
  -- i.e. lobby->planning->game
  Blacklist = {}

  Blacklist.show_banned = true
  Blacklist.show_not_banned = false

  Blacklist.chat_name = 'Blacklist'
  Blacklist.chat_color = 'ffff0000' -- argb
  Blacklist.chat_backlog = {}

  function Blacklist:write_to_chat(message)
    --[[
    Display a text message in the chat box. If the chat box doesn't exist,
    add the message to a message backlog.
    --]]
    message = tostring(message)
    if managers
        and managers.chat
        and managers.chat._receivers
        and managers.chat._receivers[1]
    then
      if type(self.chat_color) == 'string' and Color then
        self.chat_color = Color(self.chat_color)
      end
      if Color then
        managers.chat:_receive_message(
          managers.chat.GAME, self.chat_name, message, self.chat_color)
      end
    else
      self.chat_backlog[#self.chat_backlog+1] = message
    end
  end

  function Blacklist:manual_check()
    --[[
    Check all connected players to see if they are in the blacklist.
    --]]
    for _, peer in pairs(managers.network:session():peers()) do
      local name = peer:name()
      local user_id = peer:user_id()
      self:on_peer_added(name, user_id)
    end
  end

  function Blacklist:clear_backlog()
    --[[
    Clear the chat messages backlog by showing these messages in chat. Should
    be called after chat is initialized, otherwise the backlog will remain.
    --]]
    self:debug_print('Clearing backlog, size ' .. #self.chat_backlog)
    local backlog = self.chat_backlog
    self.chat_backlog = {}
    for _,message in pairs(backlog) do
      self:write_to_chat(message)
    end
  end

  function Blacklist:on_peer_added(name, user_id)
    --[[
    Function called when a new player connects to the game.
    --]]
    if self.users and self.users[user_id] ~= nil and self.show_banned then
      self:write_to_chat(name .. ' is in the blacklist: ' .. self.users[user_id])
    elseif self.users and self.show_not_banned then
      self:write_to_chat(name .. ' is not in the blacklist')
    elseif not self.users then
      self:write_to_chat('ERROR: User list not initialized.')
    end
  end

  function Blacklist:on_chat_init()
    --[[
    Function called after the chat boxes are initialized.
    --]]
    self:clear_backlog()
    self:manual_check() -- TODO: remove if fix backlog bug
  end

  function Blacklist:debug_print(msg)
    --[[
      Function to write a message to a text file. Used for development and
      debug purposes.
    --]]
    local filepath = 'debug.log'
    local file = io.open(filepath, 'a')
    if file then
      file:write(tostring(msg) .. '\r\n')
      file:close()
      return true
    else
      return false
    end
  end

  function Blacklist:run_tests()
    self:write_to_chat('Running tests')
    for _, peer in pairs(managers.network:session():peers()) do
      local name = peer:name()
      local user_id = peer:user_id()
      self:write_to_chat(name .. ': ' .. type(user_id))
    end
  end

  -- Users in the blacklist. NOTE: Don't forget the ","
  Blacklist.users = {
    -- Assholes
    ['76561198049850034'] = 'Kicked me after checking my profile.',
    ['76561198063973881'] = 'Kicked me af the end of firestarter day 3.',
    ['76561197985488424'] = 'Kicked me because I didn\'t drop a medbag when noone was B&W.',
    ['76561198047457328'] = 'Kicked everyone on rats day 3, after a 5-bag cook.',
    ['76561198068854882'] = 'Kicked me after checking my profile.',
    ['76561198016074298'] = 'Kicked a bunch of people in the lobby to get his friends in.',
    ['76561198075771395'] = 'Left while hosting Hoxton Breakout Pro day 2.',
    ['76561197996765345'] = 'Kicked me to get his friend\'s bro in the game.',
    ['76561198045745973'] = 'Kicked everyone who was joining his game.',
    ['76561198119543828'] = 'Kicked me after checking my profile.',
    ['76561198059379175'] = 'Kicked me without saying anything.',
    ['76561198071434923'] = 'Kicked me because someone else was cheating. Blame the V-100.',
    ['76561198028935844'] = 'Kicked after checking my profile.',
    ['76561197971526879'] = 'Racist (anti-qc) and grade A asshole.',
    ['76561198045583249'] = 'Kicked me after he died.',
    ['76561198004355886'] = 'Kicked me when I loaded in his game.',
    ['76561198043335921'] = 'Rage quit from FF day 3 after he died.',
    ['76561198046443207'] = 'Kicked me at the end of firestarter day 3.',
    ['76561197978805710'] = 'Kicked me after checking my profile.',
    ['76561197983194427'] = 'Kicks people if they die in loud heists.',
    ['76561197964597483'] = 'Kicked me for no reason.',
    ['76561197963142438'] = 'Kicked random people to let his friends in.',
    ['76561198025518751'] = 'Kicked me after checking my profile.',
    ['76561198014113650'] = 'Kicked me a few seconds after I joined his game.',
    ['76561198061996231'] = 'Kicked me instantly when I joined his game.',
    ['76561198052164505'] = 'Kicked me after checking my profile.',
    ['76561198055355275'] = 'Kicked me when I joined his game.',
    ['76561197987029218'] = 'Kicked me on FS day 3, when he had time to check my profile.',
    ['76561198007994335'] = 'Joined game and threw 3 nades at me to cheat-check.',
    ['76561198024804492'] = 'Daily job bitch.',
    ['76561198119149037'] = 'Troll: threw his rockets and molotovs at me.',
    -- Cheaters
    ['76561198071642149'] = 'Spawned bags on FF day 1.',
    ['76561197967578586'] = 'Used all the cheats: godmode, ammo, etc.',
    ['76561198125100421'] = 'Skill points cheat.',
    ['76561198076261661'] = 'Used all cheats: godmode, nopagers, etc.',
    ['76561198115411583'] = 'Infinite ammo, deployable and flying.',
  	['76561198086125066'] = 'Skill points cheat.',
  	['76561198072448648'] = 'Godmode, infinite ammo, instant interact.',
    ['76561198053550514'] = 'Cheater: infinite ammo, possibly skill points.',
    ['76561198121493051'] = 'Cheater, don\'t remember what though.',
    ['76561198129990271'] = 'Cheater: level cheat, skill points, insta drill upgrade.',
    ['76561198142413499'] = 'Cheater: skills points, god mode, tried to spawn bags.'
  }

  Blacklist:debug_print('Blacklick initialized.')
end
