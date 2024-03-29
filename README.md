![alt text](https://img.itch.zone/aW1hZ2UvNDQwMDI1LzIyMTE4MDUuZ2lm/347x500/aTQB0O.gif)

[Try it out in the browser](https://achie72.github.io/crazy_rabbit_afternoon/)

Or just download your wanted executable from the `exports` directory.

# How to play

__Start__: C/Z/Y (builtin differs on keyboard layouts, the button next to 'x')

__Move__: Arrows, you can step twice while wolves moves once.

__Skip step__: X

Collect all carrots to proceed to the next level. Avoid wolves, by hiding in the rabbit holes.  You can step twice, while wolves step one.

If they can't see you, they are dark red, and start to wander around. If the can, they turn bright red, and start to chase you down. They can't eat you, while you are in a rabbit hole.

Difficulty goes up by reached levels and steps taken, so plan ahead!

# General Idea
Create and oldschool rogue-like feel puzzle game.

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

---  

[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/L4L81GBPX)

**Social media:**  

Other social sites:  
🐦 [Twitter](https://twitter.com/Achie7240)  
📷 [Instagram](https://www.instagram.com/justanerdlife/)  
🎥 [Twitch](https://www.twitch.tv/achie7240)  
🎬 [YouTube](https://www.youtube.com/channel/UCzWXrvo-Pj7_KDv4w4q-4Kg)  


Games and devlogs i made:
⌨️ [GitHub repos](https://github.com/Achie72)  
🎮 [Itch.io](https://achie.itch.io/)  
🕹️ [Newgrounds](https://achie72.newgrounds.com/)  

All my links in one place:  
🌳 [Linktr.ee](https://linktr.ee/AchieGameDev)  
