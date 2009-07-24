--[[ Copyright (c) 2009 Peter "Corsix" Cawley

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]

local TH = require "TH"

class "UIBuildRoom" (Window)

function UIBuildRoom:UIBuildRoom(ui)
  self:Window()
  
  local app = ui.app
  self.ui = ui
  self.x = (app.config.width - 300) / 2
  self.y = (app.config.height - 300) / 2
  self.panel_sprites = app.gfx:loadSpriteTable("QData", "Req09V", true)
  self.white_font = app.gfx:loadFont(app.gfx:loadSpriteTable("QData", "Font01V"))
  self.blue_font = app.gfx:loadFont(app.gfx:loadSpriteTable("QData", "Font02V"))
  self.category_index = 0
  self.list_hover_index = 0
  self.preview_anim = false
  
  local function cat(n)
    return function(self) return self:setCategory(n) end
  end
  local room_n = 1
  local function rm()
    local n = room_n
    room_n = room_n + 1
    return function(self) return self:buildRoom(n) end
  end
  
  self:addPanel(210,   0,   0):makeButton(9, 9, 129, 32, 211, cat(1)) -- Diagnosis
  self:addPanel(212,   0,  41):makeButton(9, 0, 129, 31, 213, cat(2)) -- Treatment
  -- Clinics should really be at y=73, but TH skips a pixel here
  -- so that the left and right columns are the same height
  self:addPanel(214,   0,  72):makeButton(9, 0, 129, 32, 215, cat(3)) -- Clinics
  self:addPanel(216,   0, 104):makeButton(9, 0, 129, 32, 217, cat(4)) -- Facilities
  self:addPanel(218,   0, 146) -- Grid top
  for y = 179, 249, 10 do
    self:addPanel(219,   0,   y) -- Grid body
  end
  self:addPanel(220,   0, 259) -- Grid bottom
  self:addPanel(221, 146,   0) -- List top
  for y = 34, 205, 19 do
    self:addPanel(222, 146,   y):makeButton(12, 0, 126, 19, 223, rm()) -- List body
      .enabled = false
  end
  
  -- The close button has no sprite for when pressed, so it has to be custom drawn
  local build_room_dialog_close = app.gfx:loadBitmap"build_room_dialog_close"
  self:addPanel(224, 146, 224):makeButton(8, 34, 134, 27, 224, self.close)
  .panel_for_sprite.custom_draw = function(panel, canvas, x, y)
    x = x + panel.x
    y = y + panel.y
    panel.window.panel_sprites:draw(canvas, panel.sprite_index, x, y)
    local btn = panel.window.active_button
    if btn and btn.panel_for_sprite == panel and btn.active then
      build_room_dialog_close:draw(canvas, x + 8, y + 34)
    end
  end
  
  self.list_title = _S(16, 2) -- Pick Department
  self.cost_box = _S(16, 5) .. "0"
  self.list = {}
  self.category_titles = {
    _S(19, 4), -- Diagnosis
    _S(19, 5), -- Treatment
    _S(19, 6), -- Clinics
    _S(19, 7), -- Facilities
  }
  self.category_rooms = {
  }
  for i, category in ipairs{"diagnosis", "treatment", "clinics", "facilities"} do
    local rooms = {}
    self.category_rooms[i] = rooms
    for _, room in ipairs(app.rooms) do
      if room.categories[category] then
        rooms[#rooms + 1] = room
      end
    end
    table.sort(rooms, function(r1, r2) return r1.categories[category] < r2.categories[category] end)
  end
end

local cat_label_y = {21, 53, 84, 116}

function UIBuildRoom:draw(canvas)
  Window.draw(self, canvas)
  
  local x, y = self.x, self.y
  self.white_font:draw(canvas, self.list_title, x + 163, y + 18)
  for i = 1, 4 do
    (i == self.category_index and self.blue_font or self.white_font)
      :draw(canvas, self.category_titles[i], x + 19, y + cat_label_y[i])
  end
  
  for i, room in ipairs(self.list) do
    (i == self.list_hover_index and self.blue_font or self.white_font)
      :draw(canvas, room.name, x + 163, y + 21 + i * 19)
  end
  
  self.white_font:draw(canvas, self.cost_box, x + 163, y + 232)
  
  if self.preview_anim then
    self.preview_anim:draw(canvas, x + 70, y + 200)
  end
end

function UIBuildRoom:setCategory(index)
  self.category_index = index
  self.list_title = _S(16, 3) -- Pick Room Type
  self.list = self.category_rooms[index]
  
  local last = #self.list + 5
  for i = 5, 14 do
    self.buttons[i].enabled = i < last
  end
end

function UIBuildRoom:buildRoom(index)
  self:close()
  local edit_dlg = UIEditRoom(self.ui, self.list[index])
  self.ui:addWindow(edit_dlg)
end

function UIBuildRoom:onMouseMove(x, y, dx, dy)
  local repaint = Window.onMouseMove(self, x, y, dx, dy)
  
  local hover_idx = 0
  if 156 <= x and x < 287 and 31 <= y and y < 226 then
    for i = 5, 14 do
      local btn = self.buttons[i]
      if btn.enabled and btn.x <= x and x < btn.r and btn.y <= y and y < btn.b then
        hover_idx = i - 4
        break
      end
    end
  end
  
  if hover_idx ~= self.list_hover_index then
    if hover_idx == 0 then
      self.cost_box = _S(16, 5) .. "0"
      self.preview_anim = false
    else
      self.cost_box = _S(16, 5) .. self.list[hover_idx].build_cost
      self.preview_anim = TH.animation()
      self.preview_anim:setAnimation(self.ui.app.anims, self.list[hover_idx].build_preview_animation)
    end
    self.list_hover_index = hover_idx
    repaint = true
  end
  
  return repaint
end