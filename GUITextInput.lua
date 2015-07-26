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
    self.gui_items = {}

    -- Set the callbacks on keyboard events
    self.panel:enter_text(function(that, char) self:on_enter_text(char) end)
    self.panel:key_press(function(that, key) self:on_key_press(key) end)

    -- Inject code in the Payday 2 managers to prevent key presses from processing
    self:_inject_hooks()

    -- Show the text input UI
    self:_draw_ui()
  end

  function GUITextInput:delete()
  	for _, child in ipairs(self.panel:children()) do
  		self.panel:remove(child)
  	end
  	self.panel:parent():remove(self._panel)
  end

  function GUITextInput:on_input_complete(canceled)
    -- Remove the hooks that hijack code to prevent key presses from processing
    self:_remove_hooks()

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

  function GUITextInput:_inject_hooks()
    --[[
      There has to be a better way to do this. Perhaps it's possible to register
      an active menu, and let the menu manager handle the logic???
    --]]
    self.orig_update = managers.menu.update
    managers.menu.update = function(...) end
  end

  function GUITextInput:_remove_hooks()
    managers.menu.update = self.orig_update
  end

  function GUITextInput:_draw_ui()
  -- Show a rectangle with some default text on it, to test the display functions
  -- Known issue: everything is drawn under the Payday menu
  -- TODO: use "const" variables to define size, position, etc.
  -- TODO: get the game's resolution and adjust display
  self.gui_items.background = self.gui_items.background or self.panel:rect({
    name = "bg",
    x = 660,
    y = 340,
    w = 600,
    h = 400,
    blend_mode = "normal",
    color = Color.black,
    layer = 100 })
  self.gui_items.left_border = self.gui_items.left_border or self.panel:rect({
    name = "left_border",
    x = 660,
    y = 340,
    w = 3,
    h = 400,
    blend_mode = "normal",
    color = Color.white,
    layer = 100 })
  self.gui_items.right_border = self.gui_items.right_border or self.panel:rect({
    name = "right_border",
    x = 1260 - 3,
    y = 340,
    w = 3,
    h = 400,
    blend_mode = "normal",
    color = Color.white,
    layer = 100 })
  self.gui_items.top_border = self.gui_items.top_border or self.panel:rect({
    name = "top_border",
    x = 660,
    y = 340,
    w = 600,
    h = 3,
    blend_mode = "normal",
    color = Color.white,
    layer = 100 })
  self.gui_items.bottom_border = self.gui_items.bottom_border or self.panel:rect({
    name = "bottom_border",
    x = 660,
    y = 740 - 3,
    w = 600,
    h = 3,
    blend_mode = "normal",
    color = Color.white,
    layer = 100 })
  self.gui_items.header = self.gui_items.header or self.panel:text({
    name = "header",
    x = 0,
    y = 340 + 10,
    h = tweak_data.menu.pd2_small_font_size * 1.5,
    align = "center",
    vertical = "center",
    color = Color.white,
    layer = 101,
    font = tweak_data.menu.pd2_small_font,
    font_size = tweak_data.menu.pd2_small_font_size * 1.25 })
  self.gui_items.header:set_text("Test header")

  -- TODO: show a panel that displays the text entered
  -- Should have 3 text areas: the header, the prompt, the input area
  -- Note: verify that text wrapping works for the input area
  end

end
