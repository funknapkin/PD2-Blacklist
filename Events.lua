local import_success = pcall(dofile, ModPath .. "/Blacklist.lua")

if not import_success then
  Log("Importation error in Blacklist/Events.lua")
else
  if RequiredScript == 'lib/network/networkgame' then
    local old_peer_added = NetworkGame.on_peer_added
    function NetworkGame:on_peer_added(peer, peer_id)
      local retval = old_peer_added(self, peer, peer_id)
      local name = peer:name()
      local user_id = peer:user_id()
      Blacklist:on_peer_added(name, user_id)
      return retval
    end
  end

  if RequiredScript == 'lib/managers/hud/hudchat' then
    local old_func = HUDChat.init
    function HUDChat:init(...)
      -- Note: seems to get called twice when entering the game.
      local retval = old_func(self, ...)
      setup:add_end_frame_callback(
        function() Blacklist:on_chat_init() end
      )
      return retval
    end
  end

  if RequiredScript == 'lib/managers/chatmanager' then
    local old_func = ChatGui.init
    function ChatGui:init(...)
      local retval = old_func(self, ...)
      setup:add_end_frame_callback(
        function() Blacklist:on_chat_init() end
      )
      return retval
    end
  end
end
