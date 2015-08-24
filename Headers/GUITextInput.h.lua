--[[
Class to get text input from the user.
--]]

GUITextInput = class()

--[[
Object construction and initialization
--]]
function GUITextInput:new(title, description, complete_callback) end
function GUITextInput:init(title, description, complete_callback) end

--[[
Events
--]]
function GUITextInput:on_input_complete(canceled) end
function GUITextInput:on_enter_text(char) end
function GUITextInput:on_key_press(key) end
function GUITextInput:on_key_release(key) end

--[[
Members
--]]
GUITextInput.complete_callback = function(text) end
GUITextInput.title = string
GUITextInput.description = string
GUITextInput.text = string
GUITextInput.workspace = workspace
GUITextInput.panel = panel
