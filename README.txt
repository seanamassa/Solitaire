# Klondike Solitaire (Lua + LOVE2D)
# Created by Sean Massa

A simple Klondike Solitaire game using Lua and LOVE2D.

## Features

* Standard Klondike rules & gameplay.
* Drag/drop cards.
* Deck deals 3 cards, recycles.
* Auto-flips uncovered tableau cards.
* Basic shape/text visuals.

## How it's Built

*OOP-Style: Used Lua tables/metatables for `Card`, `Pile`, `Grabber` classes to keep code organized.
*State: Simple state tracking like `card.faceUp` and `grabber.grabbedCards` manages game flow.
*Game Loop: Standard LOVE2D `load`/`update`/`draw` cycle.
*Input Handling: `main.lua` delegates drag/drop logic to the `Grabber` class.

## Postmortem

Good: Splitting code into classes (Card, Pile, etc.) made development easier.
Could Improve: Rule checking logic needs some improvement I noticed a bug of being able to drop stack of cards into the suit pile
Creating sprite assets for the cards as well as soundfx/music.

## Assets Used
* No assets use only basic shapes that are generated in lua