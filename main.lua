-- Sean Massa
-- 5-14-25 Solitaire (ADDED Win/Reset/Undo)

io.stdout:setvbuf("no")

require "vector"
require "card"
require "pile"
require "grabber"

-- Game Constants
WINDOW_WIDTH = 960
WINDOW_HEIGHT = 640
CARD_MARGIN = 15

-- Button Constants
RESET_BUTTON_X = WINDOW_WIDTH - 100
RESET_BUTTON_Y = WINDOW_HEIGHT - 40
RESET_BUTTON_WIDTH = 80
RESET_BUTTON_HEIGHT = 30

UNDO_BUTTON_X = WINDOW_WIDTH - 100 - RESET_BUTTON_WIDTH - CARD_MARGIN
UNDO_BUTTON_Y = WINDOW_HEIGHT - 40
UNDO_BUTTON_WIDTH = 80
UNDO_BUTTON_HEIGHT = 30


-- Global Game Objects
grabber = nil
allPiles = {}
deckPile = nil
drawPile = nil
foundationPiles = {}
tableauPiles = {}
gameState = "playing" -- "playing", "won"
moveHistory = {}


function love.load()
  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {resizable=false, vsync=true})
  love.window.setTitle("Klondike Solitaire")
  love.graphics.setBackgroundColor(0.1, 0.5, 0.1, 1)

  math.randomseed(os.time())

  grabber = GrabberClass:new()

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

function shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function setupGame()
    allPiles = {}
    foundationPiles = {}
    tableauPiles = {}
    moveHistory = {}

    -- Deck Pile
    local deckX = CARD_MARGIN
    local deckY = CARD_MARGIN
    deckPile = PileClass:new(deckX, deckY, "deck")
    table.insert(allPiles, deckPile)

    -- Draw Pile
    local drawX = deckX + CARD_WIDTH + CARD_MARGIN
    local drawY = deckY
    drawPile = PileClass:new(drawX, drawY, "draw")
    table.insert(allPiles, drawPile)

    -- Foundation Piles
    local foundationXStart = WINDOW_WIDTH - (4 * (CARD_WIDTH + CARD_MARGIN)) + CARD_MARGIN/2
    for i = 1, 4 do
        local foundationX = foundationXStart + (i-1) * (CARD_WIDTH + CARD_MARGIN)
        local foundationY = deckY
        local pile = PileClass:new(foundationX, foundationY, "foundation")
        table.insert(foundationPiles, pile)
        table.insert(allPiles, pile)
    end

    -- Tableau Piles
    local tableauY = deckY + CARD_HEIGHT + CARD_MARGIN * 2
    for i = 1, 7 do
        local tableauX = CARD_MARGIN + (i-1) * (CARD_WIDTH + CARD_MARGIN)
        local pile = PileClass:new(tableauX, tableauY, "tableau")
        table.insert(tableauPiles, pile)
        table.insert(allPiles, pile)
    end

    local fullDeck = createDeck()
    shuffleDeck(fullDeck)

    -- Deal to Tableau
    for i = 1, 7 do
        for j = i, 7 do
            if #fullDeck == 0 then goto end_tableau_deal end
            local card = table.remove(fullDeck)
            card.faceUp = (i == j)
            tableauPiles[j]:addCard(card)
        end
    end
    ::end_tableau_deal::

    -- Put remaining cards in Deck Pile
    for i = #fullDeck, 1, -1 do
        local card = table.remove(fullDeck)
        card.faceUp = false
        deckPile:addCard(card)
    end

    gameState = "playing"
end

function recordMove(moveData)
    table.insert(moveHistory, moveData)
end

function undoLastMove()
    if #moveHistory == 0 then
        return
    end

    local lastMove = table.remove(moveHistory)

    if lastMove.type == "move" then
        for i = #lastMove.cards, 1, -1 do
            local cardFound = false
            for k = #lastMove.toPile.cards, 1, -1 do
                if lastMove.toPile.cards[k] == lastMove.cards[i] then
                    table.remove(lastMove.toPile.cards, k)
                    cardFound = true
                    break
                end
            end
        end
        lastMove.fromPile:addCards(lastMove.cards)

        if lastMove.revealedCard then
            lastMove.revealedCard.faceUp = false
        end
        lastMove.fromPile:updateCardPositions()
        lastMove.toPile:updateCardPositions()

    elseif lastMove.type == "drawDeck" then
        for i = #lastMove.cardsDrawn, 1, -1 do
            local cardFound = false
            for k = #drawPile.cards, 1, -1 do
                if drawPile.cards[k] == lastMove.cardsDrawn[i] then
                    table.remove(drawPile.cards, k)
                    cardFound = true
                    break
                end
            end
        end

        for i = #lastMove.cardsDrawn, 1, -1 do
            lastMove.cardsDrawn[i].faceUp = false
            deckPile:addCard(lastMove.cardsDrawn[i])
        end
        deckPile:updateCardPositions()
        drawPile:updateCardPositions()

    elseif lastMove.type == "recycleDeck" then
        for i = #lastMove.cardsRecycled, 1, -1 do
            local cardFound = false
            for k = #deckPile.cards, 1, -1 do
                if deckPile.cards[k] == lastMove.cardsRecycled[i] then
                    table.remove(deckPile.cards, k)
                    cardFound = true
                    break
                end
            end
        end

        for i = #lastMove.cardsRecycled, 1, -1 do
            lastMove.cardsRecycled[i].faceUp = true
            drawPile:addCard(lastMove.cardsRecycled[i])
        end
        deckPile:updateCardPositions()
        drawPile:updateCardPositions()
    end
    if gameState == "won" then
        gameState = "playing"
    end
end


function love.update(dt)
  if gameState == "playing" then
    grabber:update(dt)
  end
end

function love.draw()
  for _, pile in ipairs(allPiles) do
    pile:draw()
  end

  if gameState == "playing" then
    grabber:draw()
  end

  love.graphics.setColor(1, 1, 1, 1)
  --love.graphics.print("Mouse: " .. math.floor(love.mouse.getX()) .. ", " ..
  --  math.floor(love.mouse.getY()), 5, WINDOW_HEIGHT - 20)

  if #grabber.grabbedCards > 0 then
     --love.graphics.print("Holding: " .. grabber.grabbedCards[1].rank..grabber.grabbedCards[1].suit .. " (" .. #grabber.grabbedCards .. ")", 150, WINDOW_HEIGHT - 20)
  end

  -- Draw Reset Button
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.rectangle("fill", RESET_BUTTON_X, RESET_BUTTON_Y, RESET_BUTTON_WIDTH, RESET_BUTTON_HEIGHT, 5, 5)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf("Reset", RESET_BUTTON_X, RESET_BUTTON_Y + RESET_BUTTON_HEIGHT/2 - 7, RESET_BUTTON_WIDTH, "center")

  -- Draw Undo Button
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.rectangle("fill", UNDO_BUTTON_X, UNDO_BUTTON_Y, UNDO_BUTTON_WIDTH, UNDO_BUTTON_HEIGHT, 5, 5)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf("Undo", UNDO_BUTTON_X, UNDO_BUTTON_Y + UNDO_BUTTON_HEIGHT/2 - 7, UNDO_BUTTON_WIDTH, "center")
  love.graphics.setColor(1,1,1,1)

  if gameState == "won" then
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setColor(0, 1, 0, 1)
    local winFont = love.graphics.setNewFont(48)
    love.graphics.printf("You Win!", 0, WINDOW_HEIGHT/2 - 50, WINDOW_WIDTH, "center")
    love.graphics.setFont(winFont)
    love.graphics.setColor(1,1,1,1)
  end
end

function checkForWin()
    if #foundationPiles ~= 4 then return false end
    for _, pile in ipairs(foundationPiles) do
        if #pile.cards ~= 13 then
            return false
        end
    end
    return true
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 and
       x >= RESET_BUTTON_X and x <= RESET_BUTTON_X + RESET_BUTTON_WIDTH and
       y >= RESET_BUTTON_Y and y <= RESET_BUTTON_Y + RESET_BUTTON_HEIGHT then
        setupGame()
        return
    end

    if button == 1 and
       x >= UNDO_BUTTON_X and x <= UNDO_BUTTON_X + UNDO_BUTTON_WIDTH and
       y >= UNDO_BUTTON_Y and y <= UNDO_BUTTON_Y + UNDO_BUTTON_HEIGHT then
        if gameState == "playing" or #moveHistory > 0 then
            undoLastMove()
        end
        return
    end

    if gameState == "playing" then
        local handledByGrabber = grabber:grab(x, y, button)

        if not handledByGrabber and button == 1 then
            if deckPile and deckPile:isMouseOverBase(x, y) then
                dealFromDeckToDraw()
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if gameState ~= "playing" then return end

    local cardWasGrabbedInitially = #grabber.grabbedCards > 0 -- State before release
    local originalPileFromGrabber = grabber.grabbedFromPile   -- Pile before release potentially modifies it
    local cardsAboutToMove = {}
    if cardWasGrabbedInitially then
        for _, c in ipairs(grabber.grabbedCards) do table.insert(cardsAboutToMove, c) end
    end

    local tempTargetPile = nil -- To determine if a valid drop location was targeted
    if cardWasGrabbedInitially then
        for i = #allPiles, 1, -1 do
             local pile = allPiles[i]
             if pile ~= originalPileFromGrabber and (pile:isMouseOverBase(x, y) or pile:isMouseOverTopCard(x, y)) then
                  if pile:canAcceptCard(grabber.grabbedCards[1]) then
                     tempTargetPile = pile
                     break
                  end
             end
        end
    end

    -- Perform the release action - this will move cards if valid, or return them
    grabber:release(x, y, button)

    local revealedCardForUndo = nil

    -- Check for tableau reveal IF cards were initially grabbed AND came from a tableau pile
    if cardWasGrabbedInitially and originalPileFromGrabber and originalPileFromGrabber.type == "tableau" then

        local cardsWereSuccessfullyMovedAway = false
        if tempTargetPile then -- A valid target was identified
            -- Check if the first card of the moved stack is now in tempTargetPile
            if #cardsAboutToMove > 0 and cardsAboutToMove[1].pile == tempTargetPile then
                cardsWereSuccessfullyMovedAway = true
            end
        end

        if cardsWereSuccessfullyMovedAway then
            local topCardAfterMove = originalPileFromGrabber:topCard()
            if topCardAfterMove and not topCardAfterMove.faceUp then
                topCardAfterMove.faceUp = true
                revealedCardForUndo = topCardAfterMove
            end
        end
    end

    -- Record the move if it was successful and a target was identified
    if cardWasGrabbedInitially and tempTargetPile then
        -- Check if the drop was actually successful (cards are in tempTargetPile)
        local cardsActuallyInTarget = true
        if #cardsAboutToMove > 0 then
            local firstMovedCard = cardsAboutToMove[1]
            if firstMovedCard.pile ~= tempTargetPile then
                cardsActuallyInTarget = false
            end
        else
            cardsActuallyInTarget = false -- No cards were about to move
        end

        if cardsActuallyInTarget then
            recordMove({
                type = "move",
                cards = cardsAboutToMove,
                fromPile = originalPileFromGrabber, -- Use the stored reference
                toPile = tempTargetPile,
                revealedCard = revealedCardForUndo
            })
            if checkForWin() then
                gameState = "won"
                print("-------------------------")
                print("------ YOU WIN! ---------")
                print("-------------------------")
            end
        end
    end
end

function dealFromDeckToDraw()
    local numToDraw = 3
    local cardsDrawnForHistory = {}

    if #deckPile.cards == 0 then
        if #drawPile.cards > 0 then
            local cardsRecycledForHistory = {}
            for i = 1, #drawPile.cards do table.insert(cardsRecycledForHistory, drawPile.cards[i]) end

            while #drawPile.cards > 0 do
                local card = drawPile:removeCard()
                card.faceUp = false
                deckPile:addCard(card)
            end
            recordMove({type = "recycleDeck", cardsRecycled = cardsRecycledForHistory})
        end
    else
        for i = 1, numToDraw do
            local card = deckPile:removeCard()
            if card then
                card.faceUp = true
                drawPile:addCard(card)
                table.insert(cardsDrawnForHistory, card)
            else
                break
            end
        end
        if #cardsDrawnForHistory > 0 then
            recordMove({type = "drawDeck", cardsDrawn = cardsDrawnForHistory})
        end
         drawPile:updateCardPositions()
    end
end