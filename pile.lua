
require "vector"

PileClass = {}

-- Constants for Pile Drawing Offsets
TABLEAU_OFFSET_Y = 15
DRAW_OFFSET_X = 10

function PileClass:new(x, y, type)
  local pile = {}
  setmetatable(pile, { __index = PileClass })

  pile.position = Vector(x, y)
  pile.cards = {}
  pile.type = type or "tableau" -- tableau, foundation, deck, draw
  pile.size = Vector(CARD_WIDTH, CARD_HEIGHT) -- Base size for interaction/placeholder

  return pile
end

function PileClass:draw()
  -- Draw empty pile placeholder
  love.graphics.setColor(0, 0, 0, 0.3) -- Dark transparent green/grey
  love.graphics.rectangle("line", self.position.x, self.position.y, self.size.x, self.size.y, 6, 6)
  love.graphics.setColor(1, 1, 1, 1) -- Reset color

  -- Draw cards in the pile
  for i, card in ipairs(self.cards) do
      -- Calculate position based on pile type
      local cardX = self.position.x
      local cardY = self.position.y

      if self.type == "tableau" then
          cardY = self.position.y + TABLEAU_OFFSET_Y * (i - 1)
      elseif self.type == "draw" then
          -- Only show top 3, slightly offset? Or just top one? Let's show top 3 offset.
          -- This only affects drawing, the actual cards are still in order.
          if i >= #self.cards - 2 then -- Draw only the top 3 (or fewer)
             cardX = self.position.x + DRAW_OFFSET_X * (#self.cards - i)
          else
             goto continue_loop -- Skip drawing cards below the top 3 in draw pile
          end
      -- Deck pile cards are usually all drawn at the same position (only top visible or back shown)
      -- Foundation piles also usually stack directly on top

      end

      card.position = Vector(cardX, cardY)
      card:draw()

      ::continue_loop::
  end
end

function PileClass:addCard(card)
  -- Set the card's pile reference
  card.pile = self
  table.insert(self.cards, card)
  self:updateCardPositions() -- Update positions after adding
end

function PileClass:removeCard()
  -- Remove and return the top card
  if #self.cards > 0 then
    local card = table.remove(self.cards)
    card.pile = nil -- Remove pile reference
    return card
  end
  return nil
end

function PileClass:topCard()
  if #self.cards > 0 then
    return self.cards[#self.cards]
  else
    return nil
  end
end

-- Updates the visual position of cards based on pile layout rules
-- Important for tableau stacks after adding/removing cards
function PileClass:updateCardPositions()
   for i, card in ipairs(self.cards) do
        local cardX = self.position.x
        local cardY = self.position.y
        if self.type == "tableau" then
            cardY = self.position.y + TABLEAU_OFFSET_Y * (i - 1)
        -- Other types currently stack directly
        end
        card.position = Vector(cardX, cardY)
   end
end

-- Checks if mouse coordinates are over the *base* area of the pile
function PileClass:isMouseOverBase(x, y)
  return x > self.position.x and x < self.position.x + self.size.x and
         y > self.position.y and y < self.position.y + self.size.y
end

-- Checks if mouse coordinates are over the *top card* of the pile
function PileClass:isMouseOverTopCard(x, y)
    local topCard = self:topCard()
    if topCard then
        -- For tableau, the clickable area of lower cards might be relevant later
        -- For now, just check the bounds of the top card itself
        return topCard:isMouseOver(x,y)
    else
        -- If no top card, check the base
        return self:isMouseOverBase(x, y)
    end
end

function PileClass:canAcceptCard(cardToPlace)
    -- Card object must have: suit, rank, color, rankValue (added in card.lua)
    if not cardToPlace then return false end

    local topCard = self:topCard()

    if self.type == "tableau" then
        if not topCard then
            -- Empty tableau pile: Only accepts Kings
            return cardToPlace.rank == "K"
        else
            -- Non-empty tableau pile: Must be face-up to accept cards
            if not topCard.faceUp then return false end -- Cannot place on face-down card

            -- Check alternating color and rank decrease
            local colorsMatch = (topCard.color == cardToPlace.color)
            local rankIsOneLower = (topCard.rankValue == cardToPlace.rankValue + 1)

            -- print("Checking Tableau:", "Top:", topCard.rank..topCard.suit, "Place:", cardToPlace.rank..cardToPlace.suit, "Alt Color:", not colorsMatch, "Rank Lower:", rankIsOneLower)
            return not colorsMatch and rankIsOneLower
        end
    elseif self.type == "foundation" then
        if not topCard then
            -- Empty foundation pile: Only accepts Aces
            return cardToPlace.rank == "A"
        else
            -- Non-empty foundation pile: Check same suit and rank increase
            local suitsMatch = (topCard.suit == cardToPlace.suit)
            local rankIsOneHigher = (topCard.rankValue == cardToPlace.rankValue - 1)

            -- print("Checking Foundation:", "Top:", topCard.rank..topCard.suit, "Place:", cardToPlace.rank..cardToPlace.suit, "Same Suit:", suitsMatch, "Rank Higher:", rankIsOneHigher)
            return suitsMatch and rankIsOneHigher
        end
    elseif self.type == "draw" then
        -- Cannot manually place cards on the draw pile
        return false
    elseif self.type == "deck" then
        -- Cannot manually place cards on the deck pile
        return false
    end

    return false -- Default deny
end

-- helper function to add multiple cards easily
function PileClass:addCards(cardsToAdd)
    for _, card in ipairs(cardsToAdd) do
        self:addCard(card) -- Use existing addCard to handle pile reference etc.
    end
    -- No need to call updateCardPositions here, addCard calls it
end