if not GUITextInput then
  GUITextInput = class()

  --[[
  Initialize a text input dialog.
  Args:
    title:             Title for the window
    description:       Description of what the user should enter in the text input
    complete_callback: function to call when text input is complete. Should accept
                       one argument, which will contain the text entered by the
                       user.
  --]]
  function GUITextInput:init(title, description, complete_callback)
    -- Verify inputs
    if type(title) ~= "string" or
      type(description) ~= "string" or
      type(complete_callback) ~= "function"
    then
      return
    end

    self.title = title
    self.description = description
    self.complete_callback = complete_callback
    self.text = ""
    self.state = "input"
    -- Get hook to the keyboard input
    self.workspace = Overlay:gui():create_screen_workspace()
    local kb = Input:keyboard()
    self.workspace:connect_keyboard(kb)
    self.panel = self.workspace:panel({ name = "blacklist_panel" })
    self.gui_items = {}

    -- Set the callbacks on keyboard events
    self.panel:enter_text(function(that, char) self:on_enter_text(char) end)
    self.panel:key_press(function(that, key) self:on_key_press(key) end)
    self.panel:key_release(function(that, key) self:on_key_release(key) end)

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
    self.state = "leaving"
    -- Call the callback function if the user didn't cancel input by pressing
    -- escape
    if not canceled then
      self.complete_callback(self.text)
    end
  end

  function GUITextInput:on_enter_text(char)
    self.text = self.text .. char
    self:_draw_ui()
  end

  function GUITextInput:on_key_press(key)
    if key == Idstring("backspace") then
      -- Remove the last character for the text entered
      self.text = self.text:sub(1, -2)
      self:_draw_ui()
    elseif key == Idstring("enter") then
      -- User pressed the Enter key. Exit input mode.
      self:on_input_complete(false)
    elseif key == Idstring("esc") then
      -- User pressed the Escape key. Exit input mode.
      self:on_input_complete(true)
    end
  end

  function GUITextInput:on_key_release(key)
    if self.state == "leaving" and
       key == Idstring("enter") or key == Idstring("esc")
    then
      -- User left input mode, cleanup hooks.
      -- This has to be done after the key has been released, to prevent keypresses
      -- from trigerring on the underlying menu

      -- Remove the hooks that hijack code to prevent key presses from processing
      self:_remove_hooks()

      -- Clean up members
      self.panel:enter_text(nil)
      self.panel:key_press(nil)
      self.workspace:disconnect_keyboard()
      Overlay:gui():destroy_workspace(self.workspace)

      -- Destroy members
      self.complete_callback = nil
      self.text = nil
      self.workspace = nil
      self.panel = nil
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
    -- Define constants
    local FIRST_LAYER = 10000 -- Draw on top of everything
    local BOX_WIDTH = 600
    local BOX_HEIGHT = 400
    local BOX_ORIGIN_X = (RenderSettings.resolution.x - BOX_WIDTH) / 2
    local BOX_ORIGIN_Y = (RenderSettings.resolution.y - BOX_HEIGHT) / 2
    local BORDER_WIDTH = 3
    local TEXT_HORIZONTAL_PADDING = 10

    -- Draw the box that contains the text input UI
    self.gui_items.background = self.gui_items.background or self.panel:rect({
      name = "bg",
      x = BOX_ORIGIN_X,
      y = BOX_ORIGIN_Y,
      w = BOX_WIDTH,
      h = BOX_HEIGHT,
      blend_mode = "normal",
      color = Color.black,
      layer = FIRST_LAYER })
    self.gui_items.left_border = self.gui_items.left_border or self.panel:rect({
      name = "left_border",
      x = BOX_ORIGIN_X,
      y = BOX_ORIGIN_Y,
      w = BORDER_WIDTH,
      h = BOX_HEIGHT,
      blend_mode = "normal",
      color = Color.white,
      layer = FIRST_LAYER })
    self.gui_items.right_border = self.gui_items.right_border or self.panel:rect({
      name = "right_border",
      x = BOX_ORIGIN_X + BOX_WIDTH - BORDER_WIDTH,
      y = BOX_ORIGIN_Y,
      w = BORDER_WIDTH,
      h = BOX_HEIGHT,
      blend_mode = "normal",
      color = Color.white,
      layer = FIRST_LAYER })
    self.gui_items.top_border = self.gui_items.top_border or self.panel:rect({
      name = "top_border",
      x = BOX_ORIGIN_X,
      y = BOX_ORIGIN_Y,
      w = BOX_WIDTH,
      h = BORDER_WIDTH,
      blend_mode = "normal",
      color = Color.white,
      layer = FIRST_LAYER })
    self.gui_items.bottom_border = self.gui_items.bottom_border or self.panel:rect({
      name = "bottom_border",
      x = BOX_ORIGIN_X,
      y = BOX_ORIGIN_Y + BOX_HEIGHT - BORDER_WIDTH,
      w = BOX_WIDTH,
      h = BORDER_WIDTH,
      blend_mode = "normal",
      color = Color.white,
      layer = FIRST_LAYER })

    -- Draw the title
    self.gui_items.header = self.gui_items.header or self.panel:text({
      name = "header",
      x = 0,
      y = BOX_ORIGIN_Y + 10,
      align = "center",
      vertical = "top",
      color = Color.white,
      layer = FIRST_LAYER + 1,
      font = tweak_data.menu.pd2_small_font,
      font_size = tweak_data.menu.pd2_small_font_size * 1.25 })
    self.gui_items.header:set_text(self.title)

    -- Draw the description
    self.gui_items.description = self.gui_items.description or self.panel:text({
      name = "description",
      x = BOX_ORIGIN_X + TEXT_HORIZONTAL_PADDING,
      y = math.floor(BOX_ORIGIN_Y + (BOX_HEIGHT / 3)),
      w = BOX_WIDTH - ( 2 * TEXT_HORIZONTAL_PADDING ),
      align = "left",
      vertical = "top",
      color = Color.white,
      layer = FIRST_LAYER + 1,
      font = tweak_data.menu.pd2_small_font,
      font_size = tweak_data.menu.pd2_small_font_size })
    self.gui_items.description:set_text(wrap_text(self.description, 85))

    -- Draw the input text
    self.gui_items.text_input = self.gui_items.text_input or self.panel:text({
      name = "text input",
      x = BOX_ORIGIN_X + TEXT_HORIZONTAL_PADDING,
      y = math.floor(BOX_ORIGIN_Y + (BOX_HEIGHT * 2 / 3)),
      w = BOX_WIDTH - ( 2 * TEXT_HORIZONTAL_PADDING ),
      align = "left",
      vertical = "top",
      color = Color.white,
      layer = FIRST_LAYER + 1,
      font = tweak_data.menu.pd2_small_font,
      font_size = tweak_data.menu.pd2_small_font_size })
    self.gui_items.text_input:set_text(wrap_text(self.text, 85))

    -- Known issues
    -- TODO move these in the mod description / git ticket
    --  - If title is too large, it will go out of the box
    --  - If the description is too large, it can go over the text input already
    --  - If the text input is too long, it can go outside of the box
  end

  --[[
  Wrap the text of a string so that each line has at most `length` characters.
  This function will also remove empty lines

  Args:
    input: the input string
    length: number of character per line the output string should have

  Returns:
    The wrapped string
  --]]
  function wrap_text(input, length)
    local output = ""
    -- Verify arguments
    if type(input) ~= "string" or type(length) ~= "number" or length <= 0 then
      log("[ERROR] Invalid arguments for function wrap_text in GUITextInput.lua")
      return output
    end

    -- The first line has no newline character
    local first_line = true
    for line in input:gmatch("[^\r\n]+") do
      -- Add newline character if necessary
      if first_line == true then
        first_line = false
      else
        output = output .. "\n"
      end
      -- Split the line
      local lines_to_add = math.ceil(#line / length)
      for new_line_index = 1,lines_to_add do
        if new_line_index ~= 1 then
          output = output .. "\n"
        end
        local first_char_index = (new_line_index - 1) * length + 1
        local last_char_index = first_char_index + length
        output = output .. line:sub(first_char_index, last_char_index)
      end
    end

    return output
  end

end
