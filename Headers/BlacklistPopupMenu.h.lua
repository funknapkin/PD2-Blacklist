--[[
The actual pop-up menu that shows in-game, and lets the player select which
player to add to the Blacklist.
--]]

BlacklistPopupMenu = class()

--[[
Object construction and initialization
--]]
function BlacklistPopupMenu:new(blacklist_ref) end
function BlacklistPopupMenu:init(blacklist_ref) end

--[[
Events
--]]
function BlacklistPopupMenu:on_item_clicked(user_id) end

--[[
Members
--]]
BlacklistPopupMenu:blacklist_ref = Blacklist
