# Klondike Solitaire (Lua + LOVE2D)
# Created by Sean Massa

A simple Klondike Solitaire game using Lua and LOVE2D.

## Features

* Standard Klondike rules & gameplay.
* Drag/drop cards (single cards and valid tableau stacks).
* Deck deals 3 cards at a time and recycles.
* Automatic flipping of face-down tableau cards.
* Foundation and Tableau pile rule enforcement for most cases.
* Win condition detection and Win screen.
* Reset button.
* Undo button for reversing moves.
* Basic shape/text visuals.

## Programming Patterns Used

*Object-Oriented Programming (OOP)*
*How: The game is built around "classes" for `Card`, `Pile`, and `Grabber`. Each class encapsulates its specific data (like a card's suit/rank, or a pile's cards) and behaviors (like drawing a card, adding a card to a pile, or handling a mouse grab). This is achieved using Lua tables and metatables with `__index` for shared methods.
*Why: This approach organizes the code into logical, manageable units. It makes it easier to understand the role of each part of the game, reuse code (e.g., all cards share drawing logic), and separate concerns (e.g., input handling is mostly in `Grabber`, game logic in `Pile` and `main`).

*State Pattern (Simplified)*
*How: Cards have a `faceUp` boolean that dictates their appearance and interactability. The game itself has a `gameState` variable in `main.lua` (`"playing"`, `"won"`) to control overall behavior and screen display. The `Grabber` manages the "holding cards" state via the `grabbedCards` table.
*Why: Helps manage how different game elements or the game itself should behave or look depending on current conditions. For example, input is processed differently if the game is "won" versus "playing."

*Game Loop:*
*How: Uses LOVE2D's standard `love.load()`, `love.update(dt)`, and `love.draw()` callbacks in `main.lua`. `love.load()` sets up the initial game (piles, deck). `love.update()` handles changes over time (like updating the position of dragged cards). `love.draw()` renders all visible elements each frame.
*Why: This is the fundamental structure for LOVE2D games, providing clear separation for initialization, logic updates, and rendering.

*Input Handling Delegation*
*How: `main.lua` captures mouse events (`love.mousepressed`, `love.mousereleased`). For actions like grabbing and dropping cards, it delegates responsibility to the `Grabber` object. `main.lua` directly handles clicks on UI elements like the Deck, Reset, and Undo buttons.
*Why: This keeps the main input functions in `main.lua` from becoming overly complex. The `Grabber` class specializes in the logic of picking up and releasing cards, while `main.lua` handles broader interactions.

*Command Pattern (for Undo)*
*How: Each significant player action (moving cards, drawing from deck, recycling deck) is recorded as a "command" object (a table with `type` and necessary data like `cards`, `fromPile`, `toPile`, `revealedCard`) and stored in a `moveHistory` list. The `undoLastMove()` function pops the last command and performs the inverse operations.
*Why: This pattern encapsulates all information needed to reverse an action, making the undo functionality possible and relatively clean to manage.

## Feedback Incorporation
1.  Zosia Trela
*Feedback:
* Found the file organization logical (`pile.lua`, `card.lua`, `grabber.lua` separation).
* Appreciated the `grabber.lua` file for keeping `main.lua` less cluttered.
* Noted the `grab` function in `grabber.lua` seemed long but acknowledged its thoroughness based on comments.
* Suggested potential for splitting up tasks further in `main.lua` due to its length, though it was understandable.
* Agreed with readme points about debugging suit pile drops and adding assets.
* Adjustment:
* The separation into `card.lua`, `pile.lua`, and `grabber.lua` was an intentional design to promote modularity, which Zosia's feedback validates.
* The length of the `grab` function is a result of handling different scenarios (draw pile grab vs. tableau stack grab). While it could potentially be broken into more sub-functions, care was taken to ensure its current flow is logical for identifying the correct cards to pick up.
* `main.lua` does orchestrate many parts of the game (setup, input events, button logic, calls to game state changes). Further refactoring of `main.lua` could involve moving UI button handling to a separate UI module or using a more formal game state manager to reduce its direct responsibilities, as Zosia alluded.

2.   Drew Whitmer
* Feedback:
* Praised the use of comments and debug print statements for clarity.
* Noted good delegation of tasks to separate functions in `main.lua`.
* Suggested that the `release` function in `grabber.lua` could be simplified by a helper function to check if a card can be placed on any pile.
* Proposed breaking up large `if` statements in `grabber.lua` (grab/release) and `main.lua` (love.mousereleased) into individual `if` statements with early returns for easier debugging and clarity.
* Suggested using inheritance for pile types instead of a `.type` variable to avoid `.type` checks, or separating piles into different tables.
* Complimented sensible variable names.
* Adjustment:
* (Previous iterations included adding and then removing debug print statements based on development stage; this feedback affirms their utility during development).
* While a dedicated helper for checking all piles in `release` wasn't implemented due to the existing loop structure serving a similar purpose, the feedback on breaking down large `if` statements is valuable for future refactoring to improve readability further.
* The suggestion for pile type handling (inheritance/separate tables) is a good point. The current `.type` variable was chosen for simplicity in this Lua context, but for a larger project, inheritance would be a more robust OOP approach. This was considered, but not implemented in this iteration to maintain the current structure. The feedback highlights a good area for future improvement if the project were to be expanded.

3.  Henry Christopher
*Feedback: 
* Mentioned some of the same things as the others but his unique suggestions was that it would be great if you could see more than just the top card of the draw pile.
*Adjustment: 
* While this suggestion was considered, the current design preference was to maintain the gameplay mechanic where only the top card of the draw pile is immediately playable, keeping other drawn cards hidden until the top one is moved or the deck is recycled. This design choice is intentional and I am satisfiied with the end product

## Postmortem

*Key Pain Points, Planned Addressing, and Success of Refactoring

1.  Rule Implementation & Tableau Card Reveal
* Pain Point: Implementing Klondike placement rules (`PileClass:canAcceptCard`) and ensuring correct tableau card reveals after moves involved careful state management.
* Address & Success: Centralized rule checks in `PileClass:canAcceptCard` and refined `love.mousereleased` in `main.lua` to correctly handle state post-move and track revealed cards for undo. This was largely successful after iterations.

2. Multi-Card Stack Handling
* Pain Point: Refactoring `GrabberClass` from single card to `grabbedCards` (stacks) impacted drag, draw, and drop validation logic.
* Address & Success: `GrabberClass` was updated to manage lists of cards. `grab` identifies stacks, `update` and `draw` handle stack rendering, and `release` validates using the stack's bottom card. This significantly improved gameplay.

3.  Undo Feature
* Pain Point: Creating a reliable undo for diverse actions (moves, deck draws, reveals) while maintaining correct state was complex.
* Address & Success: Implemented a `moveHistory` using a command-like pattern, storing data for each action's reversal. This made undo manageable.

4.  Code Length & Complexity in Core Functions
* Pain Point: Functions like `GrabberClass:grab` and parts of `main.lua` became somewhat long due to handling multiple conditions and game logic steps.
* Planned Address & Success (Partial/Ongoing): Some logic was already separated (e.g., `dealFromDeckToDraw`, `checkForWin`). Further breaking down complex conditional blocks within    these functions into smaller, more focused helper functions or applying a state pattern more formally within `main.lua` are areas for future refinement.

5.  Bug: Dropping Stacks onto Foundation Piles:
* Pain Point (Current): A known issue allows stacks to be dropped onto foundation piles.
* Planned Address (Future Refactor): Modify `GrabberClass:release` to check if the target is a foundation pile and if more than one card is being grabbed; if so, disallow the move. This is a planned fix.

6.  Visuals & Assets:
* Pain Point: Game uses basic shapes, lacking visual polish.
* Planned Address (Future): Integrate card sprites by modifying `CardClass:draw` and possibly adding an asset manager.
* Added sound fx would be a nice to have as well for a future refactoring.


## Assets Used
* No assets use only basic shapes that are generated in lua
