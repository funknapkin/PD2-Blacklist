local import_success = pcall(dofile, ModPath .. "/Blacklist.lua")

if not import_success then
  log("Importation error in Blacklist/Events.lua")
else
  if RequiredScript == 'lib/network/base/networkpeer' then
    local old_network_init = NetworkPeer.init
    function NetworkPeer:init(name, rpc, id, loading, synced, in_lobby, character, user_id)
      local retval = old_network_init(self, name, rpc, id, loading, synced, in_lobby, character, user_id)
      if type(name) == "string" and type(id) == "number" and type(user_id) == "string" then
        -- Don't send the message to the Blacklist if the "peer" is the player
        if id ~= 0 then
          Blacklist:on_peer_added(name, user_id)
        end
      end
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
