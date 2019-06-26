# General Idea

# Assets, Architecture  
## Player  
An 8x8 bit sprite, about a bunny, in white color.  
## Enemies  
An 8x8 bit sprite, indicating wolves, in a color that is distinct to them.
## Tiles
- __Field__: Walkable field, inidcatig legal movement target.
- __Forest__: Non-walkable field, the player stays in place, if he/she tries to move over a forest tile.
- __Rabbit Holes__: Walkable field, indicating places where wolves can't see the player.
- __Carrots__: Walkable field, indicating the carrots to be picked up.

## Goals  
Moving around, and picking up all __Carrots__ on the map.
## Movement  
The __Player__ is capable of moving 2 tiles per turn, while the __Wolves__ can only move one.
## Maps  
Randomly generated: 
- contiguous __Field__ tiles, mixed with __Forest__ tiles indicating walls. 
- Randomly placed __Rabbit Holes__ 
- Randomly placed,`x` > 0 number of __Carrots__. 
__Player__ randomly placed on one of the __Rabbit Holes__ to give time for movement and strategies.
__Wolves__ randomly placed, numbers calculated by difficulty.

## Mechanics and Gameplay
### Player Movement, Interactions  
__General movement__: With the primary movement buttons, in the 4 cardinal direction.  
__Skipping turn__: The player can use the primary action button, to skip (meaning not move) on the actual turn.  
__Picking up carrots__: The player picks up a carrot as soon as he/she steps on the given tile:
- Player steps on tile
- Sound effect is played
- Carrot dissapears
- Score goes up
- Carrot Counter goes down
### Rabbit Holes  
The player can hide inside them. While the player is on a rabbit hole tile:  
- Enemies can't see him  
- It's sprite is changed, indicating invisibility.
- A __Wolf__ cannot eat the __Player__, while he/she is inside a __Rabbit Hole__.
### Carrot Counter
Indicates the leftover carrots on the map. All carrots must be picked up, to proceed to the next level.
### Carrot
Inidcates the goal carrots, that the player must pick up, to proceed to the next level. Ones stepped on:
- Sound effect is played
- Carrot dissapears
- Score goes up
- Carrot Counter goes down
### Wolves 
__Eating the Player__: If the __Wolf__ and the __Player__ are on the same tile, and the __Player__ is not inside a __Rabbit Hole__, then the __Wolf__ eats the __Player__:
- A sound is played indicating the end of the game.
- A score is shown, showing the number of __Carrots__ picked up, and the number of levels cleared.  

__AI__: Wolves are randomly placed on the map. Each turn, they do the following:
- If `wolves.x == player.x` or `wolves.x == player.x` they try to see the __Player__. If a __Forest__ is in the way, they skip to last step. If the __Player__ is in a __Rabbit Hole__, they skip to the last step.
- If a wolves sees the player, it moves towards him/her.
- If no __Player__ is seen, the wolf moves to a random neghbour tile, if capable, defined by the rules for __Player__.
### Difficulty
A number, that goes up every time a player finishes a level, or takes a step (even if that is a skip step).
### Ending a level
The player finishes the level, if all carrots are picked up.
- A tune is played.
- `Placeholder stage cleared` text is shown.
- The player proceeds to the next level, by pressing the secondary action button.
### Death
If the __Wolf__ and the __Player__ are on the same tile, and the __Player__ is not inside a __Rabbit Hole__, then the __Wolf__ eats the __Player__:
- A sound is played indicating the end of the game.
- A score is shown, showing the number of __Carrots__ picked up, and the number of levels cleared.  
- The menu screen is loaded, by pressing the secondary action button.
## Menu
A Title screen is shown. By pressing the secondary action button the __Player__ starts the game.