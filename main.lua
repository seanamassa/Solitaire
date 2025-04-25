-- Sean Massa 
-- 4-17-25 Solitaire

-- main.lua
io.stdout:setvbuf("no")

require "vector"
require "card"
require "pile" -- Make sure this matches your pile class filename!
require "grabber"

-- Game Constants
WINDOW_WIDTH = 960
WINDOW_HEIGHT = 640
CARD_MARGIN = 15 -- Spacing between piles

-- Global Game Objects
grabber = nil
allPiles = {} -- Unified list of all piles for easy iteration
deckPile = nil
drawPile = nil
foundationPiles = {}
tableauPiles = {}


function love.load()
  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {resizable=false, vsync=true})
  love.window.setTitle("Klondike Solitaire")
  love.graphics.setBackgroundColor(0.1, 0.5, 0.1, 1) -- Darker green

  math.randomseed(os.time()) -- Seed random number generator

  grabber = GrabberClass:new()
  print("-- DEBUG: Grabber created.") -- DEBUG

  setupGame()
end

function createDeck()
    local deck = {}
    for _, suit in ipairs(SUITS) do
        for _, rank in ipairs(RANKS) do
            table.insert(deck, CardClass:new(suit, rank))
        end
    end
    return deck
end

-- Fisher-Yates Shuffle
function shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function setupGame()
    print("-- DEBUG: Starting setupGame().") -- DEBUG
    -- Create and position Piles
    allPiles = {} -- Clear previous piles if restarting

    -- Deck Pile (Top Left)
    local deckX = CARD_MARGIN
    local deckY = CARD_MARGIN
    deckPile = PileClass:new(deckX, deckY, "deck")
    table.insert(allPiles, deckPile)

    -- Draw Pile (Next to Deck)
    local drawX = deckX + CARD_WIDTH + CARD_MARGIN
    local drawY = deckY
    drawPile = PileClass:new(drawX, drawY, "draw")
    table.insert(allPiles, drawPile)

    -- Foundation Piles (Top Right)
    foundationPiles = {}
    local foundationXStart = WINDOW_WIDTH - (4 * (CARD_WIDTH + CARD_MARGIN)) + CARD_MARGIN/2
    for i = 1, 4 do
        local foundationX = foundationXStart + (i-1) * (CARD_WIDTH + CARD_MARGIN)
        local foundationY = deckY
        local pile = PileClass:new(foundationX, foundationY, "foundation")
        table.insert(foundationPiles, pile)
        table.insert(allPiles, pile)
    end

    -- Tableau Piles (Below Deck/Draw/Foundation)
    tableauPiles = {}
    local tableauY = deckY + CARD_HEIGHT + CARD_MARGIN * 2
    for i = 1, 7 do
        local tableauX = CARD_MARGIN + (i-1) * (CARD_WIDTH + CARD_MARGIN)
        local pile = PileClass:new(tableauX, tableauY, "tableau")
        table.insert(tableauPiles, pile)
        table.insert(allPiles, pile)
    end
    print("-- DEBUG: All piles created. Total piles:", #allPiles) -- DEBUG

    -- Create, Shuffle, and Deal Deck
    local fullDeck = createDeck()
    print("-- DEBUG: Deck created. Size:", #fullDeck) -- DEBUG
    shuffleDeck(fullDeck)
    print("-- DEBUG: Deck shuffled.") -- DEBUG

    -- Deal to Tableau
    for i = 1, 7 do -- For each tableau pile
        for j = i, 7 do -- Deal one card to this pile and subsequent piles
            local card = table.remove(fullDeck)
            if card then
                card.faceUp = (i == j) -- Only the last card dealt to a pile is face up
                tableauPiles[j]:addCard(card)
            else
                print("Error: Deck ran out during tableau deal!")
                break
            end
        end
         if not fullDeck or #fullDeck == 0 then print("-- DEBUG: Deck empty after tableau deal loop", i); break end -- Exit outer loop if deck ran out
    end
    print("-- DEBUG: Tableau dealt.") -- DEBUG

    -- Put remaining cards in Deck Pile (face down)
    local remaining = #fullDeck
    for i = #fullDeck, 1, -1 do
        local card = table.remove(fullDeck)
        card.faceUp = false -- Ensure they are face down in the deck
        deckPile:addCard(card)
    end

    print("-- DEBUG: Game Setup Complete. Deck cards remaining:", #deckPile.cards, "(Expected", remaining, ")") -- DEBUG
end


function love.update(dt)
  grabber:update(dt)
end

function love.draw()
  -- Draw Piles (which will draw their cards)
  for _, pile in ipairs(allPiles) do
    pile:draw()
  end

  -- Draw the grabbed card last so it's on top
  grabber:draw()

  -- Draw Mouse position (Debug)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Mouse: " .. math.floor(grabber.currentMousePos.x) .. ", " ..
    math.floor(grabber.currentMousePos.y), 5, WINDOW_HEIGHT - 20)

  if grabber.grabbedCard then
     love.graphics.print("Holding: " .. grabber.grabbedCard.rank..grabber.grabbedCard.suit, 150, WINDOW_HEIGHT - 20)
  end
end


function love.mousepressed(x, y, button, istouch, presses)
    print("-- DEBUG: love.mousepressed - x:", x, "y:", y, "button:", button) -- DEBUG
    -- Pass the click event to the grabber first
    local handled = grabber:grab(x, y, button)
    print("-- DEBUG: grabber:grab handled click:", handled) -- DEBUG

    -- If the grabber didn't handle it (e.g., didn't click a grabbable card),
    -- check for other interactions, like clicking the deck pile base.
    if not handled and button == 1 then
        print("-- DEBUG: Checking for deck pile click.") -- DEBUG
        if deckPile and deckPile:isMouseOverBase(x, y) then -- Added check for deckPile existing
            print("-- DEBUG: Clicked Deck Base (mousepressed). Calling dealFromDeckToDraw.") -- DEBUG
            dealFromDeckToDraw()
        else
            print("-- DEBUG: Did not click deck pile base.") -- DEBUG
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    print("-- DEBUG: love.mousereleased - x:", x, "y:", y, "button:", button) -- DEBUG
    local cardWasGrabbed = #grabber.grabbedCards > 0 -- Check if the table is not empty
    local originalPile = grabber.grabbedFromPile -- Store before release potentially clears it

    -- Pass the release event to the grabber
    grabber:release(x, y, button)
    print("-- DEBUG: grabber:release called.") -- DEBUG

    -- After releasing, check if we need to turn over a tableau card
    -- Check if a card *was* being held, and it came from a tableau pile
    if cardWasGrabbed and button == 1 and originalPile and originalPile.type == "tableau" then
        print("-- DEBUG: Checking for tableau card reveal on pile:", originalPile.position.x) -- DEBUG
        local topCard = originalPile:topCard()
        if topCard and not topCard.faceUp then
             print("-- DEBUG: Turning card face up on tableau pile:", topCard.rank..topCard.suit) -- DEBUG
             topCard.faceUp = true
        elseif topCard then
             print("-- DEBUG: New top card already face up or no card to turn.") -- DEBUG
        else
             print("-- DEBUG: No top card on original tableau pile.") -- DEBUG
        end
    else
         print("-- DEBUG: No tableau reveal check needed (card not grabbed, not button 1, or not from tableau).") -- DEBUG
    end
end

-- Logic to move cards from Deck to Draw pile
function dealFromDeckToDraw()
    print("-- DEBUG: dealFromDeckToDraw called.") -- DEBUG
    -- Number of cards to draw
    local numToDraw = 3

    if #deckPile.cards == 0 then
        -- Recycle Draw pile back to Deck
        print("-- DEBUG: Recycling Draw Pile to Deck. Draw pile size:", #drawPile.cards) -- DEBUG
        while #drawPile.cards > 0 do
            local card = drawPile:removeCard()
            card.faceUp = false -- Put back face down
            deckPile:addCard(card)
        end
        print("-- DEBUG: Recycle complete. Deck size:", #deckPile.cards) -- DEBUG
    else
        -- Move up to 3 cards
        print("-- DEBUG: Dealing from Deck. Cards in deck:", #deckPile.cards) -- DEBUG
        for i = 1, numToDraw do
            local card = deckPile:removeCard()
            if card then
                card.faceUp = true
                drawPile:addCard(card)
                print("-- DEBUG: Dealt", card.rank..card.suit, "to Draw Pile") -- DEBUG
            else
                print("-- DEBUG: Deck empty, cannot deal more.") -- DEBUG
                break -- Stop if deck runs out
            end
        end
         -- Ensure draw pile cards stack correctly for drawing
         drawPile:updateCardPositions()
         print("-- DEBUG: Draw pile updated. Size:", #drawPile.cards) -- DEBUG
    end
end