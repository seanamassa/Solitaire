
require "vector"

CardClass = {}

CARD_WIDTH = 50
CARD_HEIGHT = 70
CARD_STATE = {
  IDLE = 0,
  MOUSE_OVER = 1, -- We might not use this state initially
  GRABBED = 2
}

-- Define suits and ranks
SUITS = {"H", "D", "C", "S"} -- Hearts, Diamonds, Clubs, Spades
RANKS = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"} -- T=10

function CardClass:new(suit, rank)
  local card = {}
  local metadata = { __index = CardClass}
  setmetatable(card, metadata)

  card.suit = suit
  card.rank = rank
  card.faceUp = false -- Cards start face down unless specified
  card.color = (suit == "H" or suit == "D") and "red" or "black" -- Store color for rule checking

  card.position = Vector(0, 0) -- Position will be managed by the pile
  card.size = Vector(CARD_WIDTH, CARD_HEIGHT)
  card.state = CARD_STATE.IDLE
  card.pile = nil -- Reference to the pile this card belongs to

  return card
end

function CardClass:update(dt)
  -- Update logic for animation or effects can go here if needed
end

function CardClass:draw()
  -- Draw card shadow/outline (optional)
  -- love.graphics.setColor(0, 0, 0, 0.5)
  -- love.graphics.rectangle("fill", self.position.x + 2, self.position.y + 2, self.size.x, self.size.y, 6, 6)

  if self.faceUp then
    -- Draw Face Up Card
    love.graphics.setColor(1, 1, 1, 1) -- White background
    love.graphics.rectangle("fill", self.position.x, self.position.y, self.size.x, self.size.y, 6, 6)

    -- Set text color based on suit
    if self.color == "red" then
      love.graphics.setColor(1, 0, 0, 1) -- Red
    else
      love.graphics.setColor(0, 0, 0, 1) -- Black
    end
    -- Draw Rank and Suit (adjust font/position as needed)
    local font = love.graphics.setNewFont(12) -- Use a default font or load one
    love.graphics.printf(self.rank .. self.suit, self.position.x, self.position.y + 5, self.size.x, "center")
    love.graphics.setFont(font) -- Reset font if needed elsewhere
    love.graphics.setColor(1, 1, 1, 1) -- Reset color

  else
    -- Draw Face Down Card (e.g., blue back)
    love.graphics.setColor(0.2, 0.4, 0.8, 1) -- Blue back
    love.graphics.rectangle("fill", self.position.x, self.position.y, self.size.x, self.size.y, 6, 6)
    -- You could draw a pattern on the back here too
  end

  -- Draw outline
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", self.position.x, self.position.y, self.size.x, self.size.y, 6, 6)
  love.graphics.setColor(1, 1, 1, 1) -- Reset color

  -- Debug state (optional)
  -- love.graphics.print(tostring(self.state), self.position.x + 20, self.position.y - 20)
end


-- Check if a point (mx, my) is within the card's bounds
function CardClass:isMouseOver(mx, my)
   return mx > self.position.x and
          mx < self.position.x + self.size.x and
          my > self.position.y and
          my < self.position.y + self.size.y
end