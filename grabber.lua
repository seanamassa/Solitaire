-- grabber.lua
require "vector"

GrabberClass = {}

function GrabberClass:new()
  local grabber = {}
  local metadata = {__index = GrabberClass}
  setmetatable(grabber, metadata)

  grabber.currentMousePos = Vector(love.mouse.getX(), love.mouse.getY())
  grabber.grabOffset = Vector(0, 0) -- Offset from *top grabbed card* top-left corner

  grabber.grabbedCards = {} -- Changed from grabbedCard to a table
  grabber.grabbedFromPile = nil -- Reference to the pile the card(s) came from

  return grabber
end

function GrabberClass:update(dt)
  self.currentMousePos = Vector(love.mouse.getX(), love.mouse.getY())

  -- If holding card(s), update their positions to follow the mouse
  if #self.grabbedCards > 0 then
      -- Ensure TABLEAU_OFFSET_Y is accessible or defined here if not global
      -- If pile.lua defines it globally, it might be okay, otherwise define it here:
      local TABLEAU_OFFSET_Y = 15 -- Define locally if not global
      
      local topGrabbedCardPos = self.currentMousePos - self.grabOffset
      -- Update position of all grabbed cards relative to the top one
      for i, card in ipairs(self.grabbedCards) do
          -- Use the locally defined or globally accessible TABLEAU_OFFSET_Y
          card.position = Vector(topGrabbedCardPos.x, topGrabbedCardPos.y + TABLEAU_OFFSET_Y * (i - 1))
      end
  end
end

-- This function will be called from love.mousepressed in main.lua
function GrabberClass:grab(x, y, button)
    -- Ensure CARD_STATE is accessible (defined globally in card.lua usually)
    if button == 1 and #self.grabbedCards == 0 then -- Left click and not already holding cards
        -- Check piles (reverse order to check topmost first)
        for pileIndex = #allPiles, 1, -1 do
            local pile = allPiles[pileIndex]

            -- Allow grabbing from Draw pile (only top card)
            if pile.type == "draw" then
                local topCard = pile:topCard()
                if topCard and topCard:isMouseOver(x, y) then
                     self.grabbedCards = { pile:removeCard() } -- Grab only the top card as a list
                     if #self.grabbedCards > 0 then
                         print("Grabbed from Draw:", self.grabbedCards[1].rank .. self.grabbedCards[1].suit)
                         self.grabbedFromPile = pile
                         self.grabbedCards[1].state = CARD_STATE.GRABBED -- Assumes CARD_STATE is global
                         self.grabOffset = self.currentMousePos - self.grabbedCards[1].position
                         -- Update position immediately
                         self.grabbedCards[1].position = self.currentMousePos - self.grabOffset
                         return true -- Indicate click was handled
                     end
                end
            -- Allow grabbing from Tableau pile (single top card OR stack)
            elseif pile.type == "tableau" and #pile.cards > 0 then
                -- Check cards in stack from top down
                for cardIndex = #pile.cards, 1, -1 do
                    local card = pile.cards[cardIndex]
                    -- Can only grab face-up cards
                    if card.faceUp and card:isMouseOver(x, y) then
                        -- Found the clicked card in the stack! Grab it and all cards below it.
                        self.grabbedCards = {}
                        self.grabbedFromPile = pile
                        local cardsToRemove = #pile.cards - cardIndex + 1

                        print("Attempting to grab stack of", cardsToRemove, "from Tableau starting with", card.rank..card.suit)

                        -- Remove cards from tableau pile and add to grabbedCards
                        local tempRemovedCards = {}
                        for i=1, cardsToRemove do
                            table.insert(tempRemovedCards, 1, table.remove(pile.cards)) -- Remove last, add to front of temp
                        end

                        -- Now add them to grabbedCards in the correct order
                        self.grabbedCards = tempRemovedCards

                        -- Set state and clear pile reference for all grabbed cards
                        for _, grabbedCard in ipairs(self.grabbedCards) do
                             grabbedCard.state = CARD_STATE.GRABBED -- Assumes CARD_STATE is global
                             grabbedCard.pile = nil
                        end


                        if #self.grabbedCards > 0 then
                            -- Calculate offset based on the *top* card of the grabbed stack
                            self.grabOffset = self.currentMousePos - self.grabbedCards[1].position
                            -- Update position immediately (will be handled by update loop too)
                            local TABLEAU_OFFSET_Y = 15 -- Define locally if not global
                            local topGrabbedCardPos = self.currentMousePos - self.grabOffset
                            for i, c in ipairs(self.grabbedCards) do
                                c.position = Vector(topGrabbedCardPos.x, topGrabbedCardPos.y + TABLEAU_OFFSET_Y * (i - 1))
                            end
                            return true -- Indicate click was handled
                        else
                            -- Should not happen if we found a card, but reset just in case
                            self.grabbedFromPile = nil
                        end
                        -- Only grab the first stack found under the mouse in this pile
                        goto next_pile -- Use goto to exit the inner loop cleanly
                    end
                end
                 ::next_pile:: -- Label for goto
            end -- End Tableau check
        end -- End loop through piles
    end
    -- If we didn't grab anything, return false
    return false
end


function GrabberClass:release(x, y, button)
    -- Ensure CARD_STATE is accessible (defined globally in card.lua usually)
    if button == 1 and #self.grabbedCards > 0 then -- Left release while holding card(s)
        print("Released:", self.grabbedCards[1].rank .. self.grabbedCards[1].suit, "(", #self.grabbedCards, "card(s))")
        local cardDropped = false
        local bottomGrabbedCard = self.grabbedCards[1] -- The card that needs to follow the rule

        -- Check if dropped onto a valid pile
        for i = #allPiles, 1, -1 do
             local pile = allPiles[i]
             -- Check if mouse is roughly over the pile
             if pile ~= self.grabbedFromPile and (pile:isMouseOverBase(x, y) or pile:isMouseOverTopCard(x, y)) then -- Don't drop onto self
                  -- Check rules using the BOTTOM card of the grabbed stack
                  if pile:canAcceptCard(bottomGrabbedCard) then
                     print("Dropped onto pile type:", pile.type, "at", pile.position.x)
                     -- Use the addCards method from pile.lua
                     pile:addCards(self.grabbedCards)
                     -- Set state for all dropped cards
                     for _, card in ipairs(self.grabbedCards) do
                         card.state = CARD_STATE.IDLE -- Assumes CARD_STATE is global
                     end
                     cardDropped = true
                     break -- Stop checking piles once dropped
                  end
             end
        end

        -- If not dropped successfully onto a new pile, return it to the original pile
        if not cardDropped then
            print("Returned to pile type:", self.grabbedFromPile.type)
            -- Use the addCards method from pile.lua
            self.grabbedFromPile:addCards(self.grabbedCards)
             -- Set state for all returned cards
            for _, card in ipairs(self.grabbedCards) do
               card.state = CARD_STATE.IDLE -- Assumes CARD_STATE is global
            end
        end

        -- Reset grabber state regardless of success
        local originalPile = self.grabbedFromPile -- Keep ref for main.lua reveal check
        self.grabbedCards = {}
        self.grabbedFromPile = nil
        self.grabOffset = Vector(0, 0)

    end
end

-- Function to draw the grabbed card(s) (so they appear on top)
function GrabberClass:draw()
    if #self.grabbedCards > 0 then
        -- Ensure TABLEAU_OFFSET_Y is accessible
        local TABLEAU_OFFSET_Y = 15 -- Define locally if not global
        -- Draw from bottom up so top cards overlap correctly
        for i = #self.grabbedCards, 1, -1 do
            self.grabbedCards[i]:draw()
        end
    end
end