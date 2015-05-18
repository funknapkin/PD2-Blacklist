if not GUITextInput then
  GUITextInput = class()

  --[[
  Initialize a text input dialog.
  Args:
    complete_callback: function to call when text input is complete. Should accept
                       one argument, which will contain the text entered by the
                       user.
  --]]
  function GUITextInput:init(complete_callback)
    self.complete_callback = complete_callback
    self.text = ""
    -- Get hook to the keyboard input
    self.workspace = Overlay:gui():create_screen_workspace()
    local kb = Input:keyboard()
    self.workspace:connect_keyboard(kb)
    self.panel = self.workspace:panel({ name = "workspace_panel" })

    -- Set the callbacks on keyboard events
    self.panel:enter_text(function(that, char) self:on_enter_text(char) end)
    self.panel:key_press(function(that, key) self:on_key_press(key) end)

    -- TODO: show a panel that displays the text entered

    -- TODO: prevent key presses from affecting the rest of the interface
    --       (mostly esc/enter, but should block all inputs)
  end

  function GUITextInput:on_input_complete(canceled)
    -- Clean up members
    self.panel:enter_text(nil)
    self.panel:key_press(nil)
    self.workspace:disconnect_keyboard()
    Overlay:gui():destroy_workspace(self.workspace)
    -- Call the callback function if the user didn't cancel input by pressing
    -- escape
    if not canceled then
      self.complete_callback(self.text)
    end
    -- Destroy members
    self.complete_callback = nil
    self.text = nil
    self.workspace = nil
    self.panel = nil
  end

  function GUITextInput:on_enter_text(char)
    self.text = self.text .. char
  end

  function GUITextInput:on_key_press(key)
    if key == Idstring("backspace") then
      -- Remove the last character for the text entered
      self.text = self.text:sub(1, -2)
    elseif key == Idstring("enter") then
      -- User pressed the Enter key. Exit input mode.
      self:on_input_complete(false)
    elseif key == Idstring("esc") then
      -- User pressed the Escape key. Exit input mode.
      self:on_input_complete(true)
    end
  end

end
