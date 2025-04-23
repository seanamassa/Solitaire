
require "vector"

GrabberClass = {}

function GrabberClass:new()
  local grabber = {}
  local metadata = {__index = GrabberClass}
  setmetatable(grabber, metadata)

  grabber.currentMousePos = Vector(love.mouse.getX(), love.mouse.getY())
  grabber.grabOffset = Vector(0, 0) -- Offset from card top-left corner to mouse click point

  grabber.grabbedCard = nil -- Reference to the card being dragged
  grabber.grabbedFromPile = nil -- Reference to the pile the card came from

  return grabber
end

function GrabberClass:update(dt)
  self.currentMousePos = Vector(love.mouse.getX(), love.mouse.getY())

  -- If holding a card, update its position to follow the mouse
  if self.grabbedCard then
    self.grabbedCard.position = self.currentMousePos - self.grabOffset
  end
end

-- This function will be called from love.mousepressed in main.lua
function GrabberClass:grab(x, y, button)
    if button == 1 and not self.grabbedCard then -- Left click and not already holding a card
        -- Check piles (reverse order to check topmost first)
        for i = #allPiles, 1, -1 do
            local pile = allPiles[i]
            local topCard = pile:topCard()

            -- --- CORRECTED LOGIC ---
            -- Check if clicking the top card of a pile (if it exists and is face up)
            -- Allow grabbing from Draw pile top card or Tableau top card (if face up)
            -- DO NOT handle the base deck click here - main.lua will do that.
            if topCard and topCard.faceUp and topCard:isMouseOver(x,y) then
                 if pile.type == "draw" or pile.type == "tableau" then
                     -- TODO: Later, allow grabbing multiple cards from tableau
                     self.grabbedCard = pile:removeCard() -- Take the card from the pile
                     if self.grabbedCard then
                         print("Grabbed:", self.grabbedCard.rank .. self.grabbedCard.suit)
                         self.grabbedFromPile = pile
                         self.grabbedCard.state = CARD_STATE.GRABBED
                         -- Calculate offset
                         self.grabOffset = self.currentMousePos - self.grabbedCard.position
                         -- Make sure the card's position is immediately set correctly
                         self.grabbedCard.position = self.currentMousePos - self.grabOffset
                         return true -- Indicate click WAS handled (we grabbed a card)
                     end
                 end
            -- Check if clicking a face-up card lower down in a tableau stack (for multi-card grab - future)
            -- elseif pile.type == "tableau" then
                -- Add logic here later to check lower cards if needed

            end
             -- --- END CORRECTED LOGIC ---
        end
    end
    -- If we didn't grab a card, return false so main.lua can check other things (like deck click)
    return false
end


-- This function will be called from love.mousereleased in main.lua
function GrabberClass:release(x, y, button)
    if button == 1 and self.grabbedCard then -- Left release while holding a card
        print("Released:", self.grabbedCard.rank .. self.grabbedCard.suit)
        local cardDropped = false

        -- Check if dropped onto a valid pile
        for i = #allPiles, 1, -1 do
             local pile = allPiles[i]
             -- Check if mouse is roughly over the pile *and* if the pile can accept the card (basic check)
             -- A more precise check would consider the top card area for tableau/foundation
             if pile:isMouseOverBase(x, y) or pile:isMouseOverTopCard(x, y) then
                  -- !!! --- KLONDIKE RULE CHECKING NEEDED HERE --- !!!
                  -- For now, just check if the pile *type* can accept cards
                  if pile:canAcceptCard(self.grabbedCard) then
                     print("Dropped onto pile type:", pile.type)
                     pile:addCard(self.grabbedCard)
                     self.grabbedCard.state = CARD_STATE.IDLE
                     cardDropped = true
                     break -- Stop checking piles once dropped
                  end
             end
        end

        -- If not dropped successfully onto a new pile, return it to the original pile
        if not cardDropped then
            print("Returned to pile type:", self.grabbedFromPile.type)
            self.grabbedFromPile:addCard(self.grabbedCard)
            self.grabbedCard.state = CARD_STATE.IDLE
        end

        -- Reset grabber state
        self.grabbedCard = nil
        self.grabbedFromPile = nil
        self.grabOffset = Vector(0, 0)
    end
end

-- Function to draw the grabbed card (so it appears on top)
function GrabberClass:draw()
    if self.grabbedCard then
        self.grabbedCard:draw()
    end
end