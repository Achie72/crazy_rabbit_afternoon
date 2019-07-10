# New mechanics:
## Season
The game now support for `Seasons`, Summer, Fall, Winter, Spring. Each of these has an own tileset, and modifiers for the game:

|                 |Summer|Fall  |Winter|Spring |
|-----------------|------|------|------|-------|
|Number of Burrows|Normal|Less  |Normal|Least  |
|Number of Carrots|Normal|Less  |Least |Less   |
|Number of Wolf   |Normal|Normal| Half |Normal |
|Number of Steps  |  2   |   2  |   2  |   2   |

`Number of Steps` is a WIP feature, that is up to experimental changes.

Each `Season` lasts for 50 `Steps` (see more in `Stat Menu`)

## Burrowing
The game now grant the `Player` the ability, to move from `Burrow`, to `Burrow`, the following way:
- `Player` standing on burrow can press `C/Y/Z` to enter `Burrow` selection
- By Left and Right movement buttons, you can cycle through `Burrows`. The currently selected one appears orange.
- By pressing `X` the `Player` exists this selection
- By pressing `C/Y/Z` the `Player` jumps to the selected `Burrow`, without `Step` cost.
- However, both `Burrows` are destroyed, and the `Player` is visible immediately (Lore: The wolf notice your digging, and will watch over those burrows, so you can't use them anymore)  

**Warning**: If the `Player` tries to move between `Burrows`, while a wolf is on that tile, the `Player` will die (Lore: the wolf notices you)  

Burrowing costs `Difficulty` (increases it by `0.2`) instead of `Steps` (see more in `Stat Menu`), so should be used sparingly, cause it can lead to pretty hard levels later on.

## Stat Menu
While in game, by pressing `Enter` (or general Pico-8 menu button on controllers), a new menupoint appears, named `Stats`.
It contains:
- Your current score
- The current `Difficulty`
- The current `Steps`
- The current `Season`

Difficulty controls wolf spawn, by the following (up to changes):
```
Round Down(Current Level/5) + Difficulty)
```
where `Difficulty` starts at 1, and is calculated this way:

```
Difficulty = 1 + (Steps/100) + (Step Overflow_1*100) + (Step Overflow_2*1000) + Burrow Movement
```
