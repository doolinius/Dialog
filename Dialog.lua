-- Taken from http://lua-users.org/wiki/InheritanceTutorial
-- Create a new class that inherits from a base class
--
function inheritsFrom( baseClass )

    -- The following lines are equivalent to the SimpleClass example:

    -- Create the table and metatable representing the class.
    local new_class = {}
    local class_mt = { __index = new_class }

    -- Note that this function uses class_mt as an upvalue, so every instance
    -- of the class will share the same metatable.
    --
    function new_class:Create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    -- The following is the key to implementing inheritance:

    -- The __index member of the new class's metatable references the
    -- base class.  This implies that all methods of the base class will
    -- be exposed to the sub-class, and that the sub-class can override
    -- any of these methods.
    --
    if baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end

    return new_class
end

-- Basically a class to configure the whole dialog system
-- Determines the look, feel and sound of the panels and
-- dialog text
-- It will also serve as a generator for individual
-- panels and dialog boxes
--
-- Having it as a class allows multiple dialogue styles
--  in the same game

Dialog = {}
Dialog.__index = Dialog
function Dialog:init(config)
  if config.style then
    assert(config.style == "rect" or config.style == "tile" or config.style == "fancy")
  end
  local this = {
    style = config.style or "rect",
    color = config.color or {25, 25, 25, 255},
    font = config.font or love.graphics.getFont(),
    textPadding = config.textPadding or 10,
    textShadow = config.textShadow or 0,
    typeSpeed = config.typeSpeed or "medium",
    typeSound = config.typeSound,
    outerPadding = config.outerPadding or 0
  }

  -- Using Love2D rectangles
  if this.style == "rect" then
    this.radius = config.radius or 0
    this.borderWidth = config.borderWidth or 0
    this.borderColor = config.borderColor or {0, 0, 0, 255}
    this.dropShadow = config.dropShadow or 0
    this.shadowColor = config.shadowColor or {0, 0, 0, 255}
  -- Using a 3x3 tile grid
  elseif this.style == "tile" then
    this.borderImageFile = config.borderImageFile
    this.bgImageFile = config.bgImageFile
    --this.imageType = config.imageType
    this.tileSize = config.tileSize
    this.tileBorder = config.tileBorder or 0
    this.scaleFilter = config.scaleFilter or "nearest"
    -- Using RPGMager Windowskin ("fancy")
  else
    this.imageFile = config.imageFile
    this.tileSize = config.tileSize
    this.bg2Alpha = config.bg2Alpha
  end

  setmetatable(this, self)
  return this
end

function Dialog:setColor(color)
  self.color = color
end

function Dialog:setFont(font)
  self.font = font
end

function Dialog:setTypeSpeed(speed)
  self.typeSpeed = speed
end

function Dialog:setTypeSound(sound)
  self.typeSound = sound
end

function Dialog:newPanel(type, position, size, text)
  local panel = nil

  if self.style == "rect" then
    panel = RectPanel:Create({x=position.x, y=position.y, w=size.w, h=size.h}, self, text)
  elseif self.style == "tile" then
    panel = TilePanel:Create({x=position.x, y=position.y, w=size.w, h=size.h}, self, text)
  elseif self.style == "fancy" then
    panel = FancyPanel:Create({x=position.x, y=position.y, w=size.w, h=size.h}, self, text)
  end

  if type == "info" then

  elseif type == "dialogue" then

  else

  end
  return panel
end

function Dialog:newMenuLayout(name, size, padding)
  local menu = MenuLayout:Create(name, size, padding, self)
  return menu
end

MenuLayout = {}
MenuLayout.__index = MenuLayout

function MenuLayout:Create(name, size, padding, dialog)
  local this = {
    dialog = dialog,
    padding = padding,
    panelDefs = {},
    panels = {}
  }
  print("Making a MenuLayout...")
  if size == "fullScreen" then
    local winW, winH = love.graphics.getDimensions()
    this.panelDefs[name] = {x=0, y=0, w=winW, h=winH}
  elseif size == "fullSize" then
    local winW, winH = love.graphics.getDimensions()
    this.panelDefs[name] = {
      x=dialog.outerPadding,
      y=dialog.outerPadding,
      w=winW-dialog.outerPadding*2,
      h=winH-dialog.outerPadding*2
    }
  else
    -- TODO: assert size makes sense
    this.panelDefs[name] = {
      x = size.x,
      y = size.y,
      w = size.w,
      h = size.h
    }
  end

  setmetatable(this, self)
  this:makePanels()
  return this
end

function MenuLayout:makePanels()
  local panel = nil
  for name,p in pairs(self.panelDefs) do
    print("Making a panel...")
    if self.dialog.style == "rect" then
      panel = RectPanel:Create({x=p.x, y=p.y, w=p.w, h=p.h}, self.dialog)
    elseif self.dialog.style == "tile" then
      panel = TilePanel:Create({x=p.x, y=p.y, w=p.w, h=p.h}, self.dialog)
    elseif self.dialog.style == "fancy" then
      panel = FancyPanel:Create({x=p.x, y=p.y, w=p.w, h=p.h}, self.dialog)
    end
    self.panels[name] = panel
  end
end

function MenuLayout:splitVert(panelName, topName, bottomName, percent)
  assert(self.panelDefs[panelName], "No panel by the name '" .. panelName .. "'")
  local panel = self.panelDefs[panelName]
  local topHeight = math.floor(panel.h * percent) - self.padding / 2
  local bottomHeight = panel.h - topHeight - self.padding / 2
  local bottomY = panel.y + panel.h - bottomHeight

  self.panelDefs[topName] = {
    x = panel.x,
    y = panel.y,
    w = panel.w,
    h = topHeight
  }
  self.panelDefs[bottomName] = {
    x = panel.x,
    y = bottomY,
    w = panel.w,
    h = bottomHeight
  }
  self.panelDefs[panelName] = nil
  self.panels[panelName] = nil
  self:makePanels()
end

function MenuLayout:splitHoriz(panelName, leftName, rightName, percent)
  assert(self.panelDefs[panelName], "No panel by the name '" .. panelName .. "'")
  local panel = self.panelDefs[panelName]
  local leftWidth = math.floor(panel.w * percent) - self.padding / 2
  local rightWidth = panel.w - leftWidth - self.padding / 2
  local rightX = panel.x + panel.w - rightWidth

  self.panelDefs[leftName] = {
    x = panel.x,
    y = panel.y,
    w = leftWidth,
    h = panel.h
  }
  self.panelDefs[rightName] = {
    x = rightX,
    y = panel.y,
    w = rightWidth,
    h = panel.h
  }
  self.panelDefs[panelName] = nil
  self.panels[panelName] = nil
  self:makePanels()
end

function MenuLayout:removePanel(panelName)
  assert(self.panelDefs[panelName], "MenuLayout:removePanel: no panel by the name " .. panelName)
  self.panelDefs[panelName] = nil
  self.panels[panelName] = nil
end

function MenuLayout:draw()
  for name, panel in pairs(self.panels) do
    panel:draw()
  end
end

Panel = {}
Panel.__index = {}

function Panel:Create(params, dialog, text)
  local this = {
    y = params.y or 0,
    x = params.x or 0,
    w = params.w or 0,
    h = params.h or 0,
    textPadding = dialog.textPadding or 10,
    text = text,
    wrappedText = nil,
    font = dialog.font,
    color = params.color or {0, 0, 0, 255},
    outerPadding = params.padding or 0
  }
  setmetatable(this, self)
  return this
end

function Panel:fitToText(width)
  self.w = width or self.w
  local maxWidth, wrappedText = self.font:getWrap(self.text, self.w-self.textPadding *2)
  local height = self.textPadding * 2
  print("text padding: " .. self.textPadding)
  print("text width: " .. self.font:getWidth(self.text))
  print("initial height: " .. height)
  for _, line in pairs(wrappedText) do
    print("wt: " .. line)
    height = height + self.font:getHeight()
  end
  print("MaxWidth: " .. maxWidth)
  self.w = maxWidth + self.textPadding * 2
  self.h = height
  self.wrappedText = wrappedText
  print("adjusted height: " .. height)
  self:drawCanvas()
end

function Panel:alignTopCenter()
  local winW, winH = love.graphics.getDimensions()
  self.x = math.floor((winW - self.w) / 2)
  self.y = self.outerPadding
end

function Panel:alignCenterScreen()
  local winW, winH = love.graphics.getDimensions()
  self.x = math.floor((winW - self.w) / 2)
  self.y = math.floor((winH - self.h) / 2)
end

function Panel:alignBottomCenter()
  local winW, winH = love.graphics.getDimensions()
  self.x = math.floor((winW - self.w) / 2)
  self.y = winH - self.outerPadding - self.h
end

function Panel:alignTopLeft()
  self.x = self.outerPadding
  self.y = self.outerPadding
end

function Panel:alignTopRight()
  local winW, winH = love.graphics.getDimensions()
  self.x = winW - self.outerPadding - self.w
  self.y = self.outerPadding
end

function Panel:alignBottomLeft()
  local winW, winH = love.graphics.getDimensions()
  self.x = self.outerPadding
  self.y = winH - self.outerPadding - self.h
end

function Panel:alignBottomRight()
  local winW, winH = love.graphics.getDimensions()
  self.x = winW - self.outerPadding - self.w
  self.y = winH - self.outerPadding - self.h
end

function Panel:drawCanvas()
end

function Panel:draw()
end

FancyPanel = inheritsFrom(Panel)

function FancyPanel:Create(params, dialog, text)
  local this = {
    x = params.x,
    y = params.y,
    w = params.w,
    h = params.h,
    textPadding = dialog.textPadding or 10,
    text = text or nil,
    wrappedText = nil,
    font = dialog.font,
    textShadow = dialog.textShadow,
    outerPadding = dialog.outerPadding,
    imageFile = dialog.imageFile,
    image = love.graphics.newImage(dialog.imageFile),
    borderTiles = {},
    arrows = {},
    background = nil, -- RM Windowskins can have two backgrounds
    background2 = nil,
    bg2Alpha = dialog.bg2Alpha or 255, -- alpha value for 2nd background layer
    bgCanvas = nil,     -- Canvas for drawing the background (both layers)
    borderCanvas = nil, -- Canvas for drawing the border
    cursor = nil,
    moreFrames = {},
  }

  -- Blocksize is either 8 or 12.  Assume 12 for no good reason at all
  local blocksize = 12
  local imgW, imgH = this.image:getDimensions()
  assert(imgW == 192 or imgW == 128, "Unknown RPG Maker WindowSkin dimensions. Use 128x128 (VX) or 192x192 (RM)")
  if imgW == 192 then  -- RMMV style
    blockSize = 12
  else                 -- RMVX style
    blockSize = 8
  end


  -- This code creates Quads for the various pieces of RPG Maker Windowskins

  -- Windowskins are divided into either 8 pixel or 12 pixel blocks
  this.tileSize = blockSize * 2

  -- primary background image of window.  Will be scaled to fit window
  this.background = love.graphics.newQuad(0, 0, blockSize * 8, blockSize * 8, imgW, imgH)
  -- secondary background image, layered above the primary and tiled instead of scaled
  this.background2 = love.graphics.newQuad(0, blockSize * 8, blockSize * 8, blockSize * 8, imgW, imgH)
  -- top row of border sections.  1 = top left, 2 = top center, 3 = top right
  table.insert(this.borderTiles, love.graphics.newQuad(blockSize * 8, 0, blockSize * 2, blockSize * 2, imgW, imgH))
  table.insert(this.borderTiles, love.graphics.newQuad(blockSize * 10, 0, blockSize * 4, blockSize * 2, imgW, imgH))
  table.insert(this.borderTiles, love.graphics.newQuad(blockSize * 14, 0, blockSize * 2, blockSize * 2, imgW, imgH))
  -- middle row of border sections. 4 = left side, 5 = right side
  table.insert(this.borderTiles, love.graphics.newQuad(blockSize * 8, blockSize * 2, blockSize * 2, blockSize * 2, imgW, imgH))
  table.insert(this.borderTiles, love.graphics.newQuad(blockSize * 14, blockSize * 2, blockSize * 2, blockSize * 2, imgW, imgH))
  -- bottom row of border sections. 6 = bottom left, 7 = bottom center, 8 = bottom right
  table.insert(this.borderTiles, love.graphics.newQuad(blockSize * 8, blockSize * 6, blockSize * 2, blockSize * 2, imgW, imgH))
  table.insert(this.borderTiles, love.graphics.newQuad(blockSize * 10, blockSize * 6, blockSize * 4, blockSize * 2, imgW, imgH))
  table.insert(this.borderTiles, love.graphics.newQuad(blockSize * 14, blockSize * 6, blockSize * 2, blockSize * 2, imgW, imgH))

  -- indicator arrows/ pointers
  this.arrows["up"] = love.graphics.newQuad(blockSize * 11, blockSize * 2, blockSize * 2, blockSize, imgW, imgH)
  this.arrows["left"] = love.graphics.newQuad(blockSize * 10, blockSize * 3, blocksize, blockSize * 2, imgW, imgH)
  this.arrows["right"] = love.graphics.newQuad(blockSize * 13, blockSize * 3, blockSize, blockSize * 2, imgW, imgH)
  this.arrows["down"] = love.graphics.newQuad(blockSize * 11, blockSize * 5, blockSize * 2, blockSize, imgW, imgH)
  -- animated "more text" indicator
  table.insert(this.moreFrames, love.graphics.newQuad(blockSize * 12, blockSize * 8, blockSize * 2, blockSize * 2, imgW, imgH))
  table.insert(this.moreFrames, love.graphics.newQuad(blockSize * 14, blockSize * 8, blockSize * 2, blockSize * 2, imgW, imgH))
  table.insert(this.moreFrames, love.graphics.newQuad(blockSize * 12, blockSize * 10, blockSize * 2, blockSize * 2, imgW, imgH))
  table.insert(this.moreFrames, love.graphics.newQuad(blockSize * 14, blockSize * 10, blockSize * 2, blockSize * 2, imgW, imgH))
  -- TODO: the cursor thingy

  setmetatable(this, self)
  self.__index = self

  this:drawBackground()
  this:drawBorder()

  return this
end

function FancyPanel:drawCanvas()
  self:drawBackground()
  self:drawBorder()
end

function FancyPanel:drawBorder()
  self.borderCanvas = love.graphics.newCanvas(self.w, self.h)
  self.borderCanvas:setFilter("nearest", "nearest")
  love.graphics.setCanvas(self.borderCanvas)
    -- draw the corners
    --love.graphics.draw(self.image, self.borderTiles[1], self.x, self.y)
    love.graphics.draw(self.image, self.borderTiles[1], 0, 0)
    love.graphics.draw(self.image, self.borderTiles[3], self.w - self.tileSize, 0)
    love.graphics.draw(self.image, self.borderTiles[6], 0, self.h - self.tileSize)
    love.graphics.draw(self.image, self.borderTiles[8], self.w - self.tileSize, self.h - self.tileSize)
    -- sides
    local widthScale = (self.w - (2 * self.tileSize)) / (self.tileSize * 2) -- * 2 is required because the tiles are 2x wider
    local heightScale = (self.h - (2 * self.tileSize)) / self.tileSize

    -- top side
    love.graphics.draw(self.image, self.borderTiles[2], self.tileSize,        0,               0, widthScale, 1)
    -- left side
    love.graphics.draw(self.image, self.borderTiles[4], 0,                      self.tileSize, 0, 1, heightScale)
    -- right side
    love.graphics.draw(self.image, self.borderTiles[5], self.w-self.tileSize, self.tileSize, 0, 1, heightScale)
    -- bottom side
    love.graphics.draw(self.image, self.borderTiles[7], self.tileSize,        self.h-self.tileSize, 0, widthScale, 1)
  love.graphics.setCanvas()
end

function FancyPanel:drawBackground()
  self.bgCanvas = love.graphics.newCanvas(self.w, self.h)
  local wScale = (self.w - (2 * 3)) / (self.tileSize * 4)
  local hScale = (self.h - (2 * 3)) / (self.tileSize * 4)
  -- Backgrounds are drawn to the canvas with the regular alpha blend mode.
  love.graphics.setCanvas(self.bgCanvas)
      --love.graphics.clear()
      love.graphics.setColor(255, 255, 255, 180)
      -- TODO: get rid of the magic numbers x=3, y=3
      -- this is done so the background doesn't appear behind
      -- border corners with transparency
      love.graphics.draw(self.image, self.background, 3, 3, 0, wScale, hScale)
      love.graphics.setColor(255, 255, 255, self.bg2Alpha)
      local bgWidth = self.tileSize * 4
      for i=0, 1 + self.w / bgWidth do
        for j=0, 1+ self.h / bgWidth do
          love.graphics.draw(self.image, self.background2, (bgWidth * i), (bgWidth * j))
        end
      end
      --love.graphics.setDefaultFilter("nearest", "nearest")
      love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setCanvas()
end

function FancyPanel:draw()

  -- draw the window background canvas
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.setBlendMode("alpha")--, "premultiplied")
  love.graphics.draw(self.bgCanvas, self.x, self.y)
  love.graphics.setBlendMode("alpha")
  -- draw the border canvas
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(self.borderCanvas, self.x, self.y)
  love.graphics.setColor(255, 255, 255, 255)

  -- text
  local oldFont = love.graphics.getFont()
  love.graphics.setFont(self.font)
  if self.textShadow > 0 then
    print("Text shadow is " .. self.textShadow)
    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.printf(self.text, self.x + self.textPadding+self.textShadow, self.y + self.textPadding+self.textShadow, self.w - (self.textPadding * 2), "left")
    love.graphics.setColor(r, g, b, a)
  end
  love.graphics.printf(self.text, self.x + self.textPadding, self.y + self.textPadding, self.w - (self.textPadding * 2), "left")
  love.graphics.setFont(oldFont)
end

RectPanel = inheritsFrom(Panel)--{}
--RectPanel.__index = RectPanel

function RectPanel:Create(params, dialog, text)
  local this = {
    y = params.y,
    x = params.x,
    w = params.w,
    h = params.h,
    textPadding = params.textPadding or 10,
    text = text or nil,
    wrappedText = nil,
    font = dialog.font,
    textShadow = dialog.textShadow,
    outerPadding = dialog.outerPadding,
    color = dialog.color,
    radius = dialog.radius,
    borderWidth = dialog.borderWidth or 4,
    borderColor = dialog.borderColor or {255, 255, 255, 255},
    dropShadow = dialog.dropShadow or false,
    shadowColor = dialog.shadowColor or {0,0,0,255},
    canvas = nil
  }

  setmetatable(this, self)
  self.__index = self

  print("RectPanel x: " .. this.x .. " y:" .. this.y)
  this:drawCanvas()

  return this
end

function RectPanel:drawCanvas()
  self.canvas = love.graphics.newCanvas(self.w+self.dropShadow, self.h+self.dropShadow)
  love.graphics.setCanvas(self.canvas)
    if self.dropShadow > 0 then
      --love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(unpack(self.shadowColor))
      love.graphics.rectangle("fill", self.dropShadow, self.dropShadow, self.w, self.h, self.radius, self.radius)
      love.graphics.setBlendMode("replace")
    end
    if self.borderWidth > 0 then
      love.graphics.setColor(unpack(self.borderColor))
      love.graphics.rectangle("fill", 0, 0, self.w, self.h, self.radius, self.radius)
      love.graphics.setColor(unpack(self.color))
      love.graphics.rectangle("fill", self.borderWidth, self.borderWidth, self.w-self.borderWidth*2, self.h - self.borderWidth*2, self.radius  , self.radius )
      --love.graphics.setColor(255,255,255,255)
    else
      love.graphics.setColor(unpack(self.color))
      love.graphics.rectangle("fill", 0, 0, self.w, self.h, self.radius, self.radius)
      --love.graphics.setColor(255,255,255,255)
    end
  love.graphics.setCanvas()
  love.graphics.setColor(255,255,255,255)
  love.graphics.setBlendMode("alpha")
end

function RectPanel:draw()
  -- draw the canvas (use transition values when we get to that)
  love.graphics.draw(self.canvas, self.x, self.y)
  -- draw the text, but only if ready (transition is finished)
  local oldFont = love.graphics.getFont()
  love.graphics.setFont(self.font)
  if self.textShadow > 0 then
    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.printf(self.text, self.x + self.textPadding+self.textShadow, self.y + self.textPadding+self.textShadow, self.w - (self.textPadding * 2), "left")
    love.graphics.setColor(r, g, b, a)
  end
  love.graphics.printf(self.text, self.x + self.textPadding, self.y + self.textPadding, self.w - (self.textPadding * 2), "left")
  love.graphics.setFont(oldFont)
end

--[[
  TilePanel

  Assumes a 3x3 grid of tiles (9 total) of variable size with a 1 pixel border
    to avoid quad bleeding
  Outer tiles will be used for the Panel border
  Inner tile will be scaled for Panel window
]]

TilePanel = inheritsFrom(Panel)

function TilePanel:Create(params, dialog, text)
  local this = {
    x = params.x,
    y = params.y,
    w = params.w,
    h = params.h,
    textPadding = dialog.textPadding or 5,
    text = text or nil,
    wrappedText = nil,
    font = dialog.font,
    textShadow = dialog.textShadow,
    outerPadding = dialog.outerPadding,
    borderImageFile = dialog.borderImageFile,
    bgImageFile = dialog.bgImageFile or dialog.borderImageFile,
    tileSize = dialog.tileSize,
    tileBorder = dialog.tileBorder,
    scaleFilter = dialog.scaleFilter, -- scale FilterMode for interior tile
    tiles = {}, -- list of quads
    color = dialog.color, -- RGBA table
    bgCanvas = nil,
    borderCanvas = nil
  }
  this.borderImage = love.graphics.newImage(dialog.borderImageFile)
  this.bgImage = love.graphics.newImage(dialog.bgImageFile)

  -- 1. top left  2. top center  3. top right
  -- 4. left      5. center      6. right
  -- 7. bot left  8. bot center  9. bot right
  local imgW, imgH = this.borderImage:getDimensions()
  --assert(imgW % this.tileSize == 0, "Panel texture atlas is not divisible by tile size")
  for i=0, (imgW / (this.tileSize+this.tileBorder) -1) do
    for j=0, (imgH / (this.tileSize+this.tileBorder) -1) do
      local quad = love.graphics.newQuad(this.tileBorder+j * (this.tileSize + this.tileBorder), this.tileBorder+i * (this.tileSize + this.tileBorder), this.tileSize, this.tileSize, this.borderImage:getDimensions())
      table.insert(this.tiles, quad)
    end
  end
  this.borderImage:setFilter("nearest", "nearest")
  this.bgImage:setFilter(this.scaleFilter, this.scaleFilter)
  setmetatable(this, self)
  self.__index = self

  this:drawCanvas()

  return this
end

function TilePanel:position(x, y, w, h)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
end

function TilePanel:drawBackground()
  self.bgCanvas = love.graphics.newCanvas(self.w, self.h)
  love.graphics.setCanvas(self.bgCanvas)
    local widthScale = (self.w - (2 * self.tileSize)) / self.tileSize
    local heightScale = (self.h - (2 * self.tileSize)) / self.tileSize

    -- center
    love.graphics.draw(self.bgImage, self.tileSize, self.tileSize, 0, widthScale, heightScale)
  love.graphics.setCanvas()
end

function TilePanel:drawBorder()
  self.borderCanvas = love.graphics.newCanvas(self.w, self.h)
  --self.borderCanvas:setFilter("nearest", "nearest")
  love.graphics.setCanvas(self.borderCanvas)
    local widthScale = (self.w - (2 * self.tileSize)) / self.tileSize
    local heightScale = (self.h - (2 * self.tileSize)) / self.tileSize

    -- four corners
    love.graphics.draw(self.borderImage, self.tiles[1], 0, 0)
    love.graphics.draw(self.borderImage, self.tiles[3], self.w - self.tileSize, 0)
    love.graphics.draw(self.borderImage, self.tiles[7], 0, self.h - self.tileSize)
    love.graphics.draw(self.borderImage, self.tiles[9], self.w - self.tileSize, self.h - self.tileSize)

    -- sides
    love.graphics.draw(self.borderImage, self.tiles[2], self.tileSize, 0, 0,widthScale, 1)
    love.graphics.draw(self.borderImage, self.tiles[4], 0, self.tileSize, 0, 1, heightScale)
    love.graphics.draw(self.borderImage, self.tiles[6], self.w-self.tileSize, self.tileSize, 0, 1, heightScale)
    love.graphics.draw(self.borderImage, self.tiles[8], self.tileSize, self.h-self.tileSize, 0, widthScale, 1)
  love.graphics.setCanvas()
end

function TilePanel:drawCanvas()
  self:drawBackground()
  self:drawBorder()
end

-- inner window coords (fill with colored rectangle for now)
-- TilePanel.x + 10, TilePanel.y + 10  ->  TilePanel.width - 8, TilePanel.height - 8
function TilePanel:draw()

  -- setColor
  -- use other parameters necessary for Transitions
  love.graphics.draw(self.bgCanvas, self.x, self.y)
  love.graphics.draw(self.borderCanvas, self.x, self.y)

  -- text
  local oldFont = love.graphics.getFont()
  love.graphics.setFont(self.font)
  if self.textShadow > 0 then
    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.printf(self.text, self.x + self.textPadding+self.textShadow, self.y + self.textPadding+self.textShadow, self.w - (self.textPadding * 2), "left")
    love.graphics.setColor(r, g, b, a)
  end
  love.graphics.printf(self.text, self.x + self.textPadding, self.y + self.textPadding, self.w - (self.textPadding * 2), "left")
  love.graphics.setFont(oldFont)
end
