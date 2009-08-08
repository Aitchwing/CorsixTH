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
local ipairs, math_floor
    = ipairs, math.floor
    
local ATTACH_BLUEPRINT_TO_TILE = true

class "UIPlaceObjects" (Window)

function UIPlaceObjects:UIPlaceObjects(ui, object_list)
  self:Window()
  
  local app = ui.app
  self.modal_class = "main"
  self.ui = ui
  self.map = app.map
  self.anims = app.anims
  self.width = 186
  self.x = app.config.width - self.width - 20
  self.y = 20
  self.panel_sprites = app.gfx:loadSpriteTable("QData", "Req05V", true)
  self.white_font = app.gfx:loadFont(app.gfx:loadSpriteTable("QData", "Font01V"))
  self.blue_font = app.gfx:loadFont(app.gfx:loadSpriteTable("QData", "Font02V"))
  self.title_text = _S(14, 29) -- Corridor Objects
  self.desc_text = _S(3, 17) -- Place the objects down in a corridor
  
  self:addPanel(112, 0, 0) -- Dialog header
  for y = 48, 83, 7 do
    self:addPanel(113, 0, y) -- Desc text box
  end
  self:addPanel(114,   0, 90) -- Dialog mid-piece
  self:addPanel(115,   0, 100):makeButton(9, 8, 41, 42, 116, self.cancel)
  self:addPanel(127,  50, 100) -- Disabled purchase items button
  self:addPanel(128,  92, 100) -- Disabled pick up items button
  self:addPanel(129, 134, 100) -- Disabled confirm button
  
  object_list = {
    {object = TheApp.objects.radiator, qty = 5},
    {object = TheApp.objects.plant, qty = 5},
    {object = TheApp.objects.bench, qty = 5},
    {object = TheApp.objects.drinks_machine, qty = 5},
    {object = TheApp.objects.reception_desk, qty = 5},
    {object = TheApp.objects.extinguisher, qty = 5},
  }
  self.objects = object_list
  self.object_anim = TH.animation()
  self.object_footprint = {}
  self:setActiveIndex(1)
  
  local function idx(i)
    return function(self)
      if i == self.active_index then
        self:nextOrientation()
      else
        self:setActiveIndex(i)
      end
    end
  end
  
  self:addPanel(123, 0, 146) -- Object list header
  for i = 1, #object_list - 1 do
    self:addPanel(124, 0, 121 + i * 29)
      :makeButton(15, 8, 130, 23, 125, idx(i))
      :preservePanel()
  end
  self:addPanel(156, 0, 117 + #object_list * 29)
    :makeButton(15, 12, 130, 23, 125, idx(#object_list))
    :preservePanel()
end

function UIPlaceObjects:close()
  self:clearBlueprint()
  return Window.close(self)
end

function UIPlaceObjects:cancel()
  self:close()
end

function UIPlaceObjects:setActiveIndex(index)
  if index == self.active_index then
    return
  end
  self.active_index = index
  
  local object = self.objects[self.active_index].object
  local anims = self.anims
  local _, ghost = self.ui.app.gfx:loadPalette()
  for _, anim in pairs(object.idle_animations) do
    anims:setAnimationGhostPalette(anim, ghost)
  end
  
  self.object_orientation = "west"
  self:nextOrientation()
end

local orient_mirror = {
  north = "west",
  west = "north",
  east = "south",
  south = "east",
}

local orient_next = {
  north = "east",
  east = "south",
  south = "west",
  west = "north",
}

function UIPlaceObjects:nextOrientation()
  local object = self.objects[self.active_index].object
  local orient = self.object_orientation
  repeat
    orient = orient_next[orient]
  until object.orientations[orient]
  self.object_orientation = orient
  
  local anim = object.idle_animations[orient]
  local flag = 0
  if not anim then
    anim = object.idle_animations[orient_mirror[orient]]
    flag = 1
  end
  self.object_anim:setAnimation(self.anims, anim, flag)
  self:setBlueprintCell(self.object_cell_x, self.object_cell_y)
end

function UIPlaceObjects:onMouseUp(button, ...)
  local repaint = Window.onMouseUp(self, button, ...)
  
  if button == "right" then
    self:nextOrientation()
    repaint = true
  end
  
  return repaint
end

function UIPlaceObjects:draw(canvas)
  if not ATTACH_BLUEPRINT_TO_TILE and self.object_cell_x then
    self.object_anim:draw(canvas, self.ui:WorldToScreen(self.object_cell_x, self.object_cell_y))
  end
  
  Window.draw(self, canvas)
  
  local x, y = self.x, self.y
  self.white_font:draw(canvas, self.title_text, x + 17, y + 21, 153, 0)
  self.white_font:drawWrapped(canvas, self.desc_text, x + 20, y + 46, 147)
  
  for i, o in ipairs(self.objects) do
    local font = self.white_font
    local y = y + 136 + i * 29
    if i == self.active_index then
      font = self.blue_font
    end
    font:draw(canvas, o.object.name, x + 15, y, 130, 0)
    font:draw(canvas, o.qty, x + 151, y, 19, 0)
  end
end

function UIPlaceObjects:clearBlueprint()
  local map = self.map.th
  self.object_anim:setTile(nil)
  for _, xy in ipairs(self.object_footprint) do
    map:setCell(xy[1], xy[2], 4, 0)
  end
end

local flag_alpha75 = 256 * 8
local flag_altpal = 16

function UIPlaceObjects:setBlueprintCell(x, y)
  self:clearBlueprint()
  self.object_cell_x = x
  self.object_cell_y = y
  if x and y then
    local object = self.objects[self.active_index].object
    local object_footprint = object.orientations[self.object_orientation].footprint
    local map = self.map.th
    if #object_footprint ~= #self.object_footprint then
      self.object_footprint = {}
      for i = 1, #object_footprint do
        self.object_footprint[i] = {}
      end
    end
    local flags = {}
    local allgood = true
    for i, xy in ipairs(object_footprint) do
      local x = x + xy[1]
      local y = y + xy[2]
      if map:getCellFlags(x, y, flags).buildable then
        map:setCell(x, y, 4, 24 + flag_alpha75)
      else
        map:setCell(x, y, 4, 67 + flag_alpha75)
        allgood = false
      end
      self.object_footprint[i][1] = x
      self.object_footprint[i][2] = y
    end
    if ATTACH_BLUEPRINT_TO_TILE then
      self.object_anim:setTile(map, x, y)
    end
    self.object_anim:setPartialFlag(flag_altpal, not allgood)
  else
    self.object_footprint = {}
  end
end

function UIPlaceObjects:onMouseMove(x, y, ...)
  local repaint = Window.onMouseMove(self, x, y, ...)
  
  local ui = self.ui
  local wx, wy = ui:ScreenToWorld(self.x + x, self.y + y)
  wx = math_floor(wx)
  wy = math_floor(wy)
  if wx < 1 or wy < 1 or wx > self.map.width or wy > self.map.height then
    wx, wy = nil
  end
  if wx ~= self.object_cell_x or wy ~= self.object_cell_y then
    self:setBlueprintCell(wx, wy)
    repaint = true
  end
  
  return repaint
end