# World implementation and validation

Five runtime-built 3,200-pixel regions are defined in `data/regions.json`. Each has its own palette, three parallax layers, original temporary pixel geometry, atmosphere particles, Turkish inscription, four enemy placements, two checkpoint altars, a mirror seal, a boss arena and an exit requiring E after victory.

- Lost Forest: return the continuously retrying seed shot to the crystal.
- Crystal Mines: the crystal ignores the first reflected pass; the visible wall mirror at x2048 must bounce the shot back a second time.
- Ash Castle: the seal accepts heavy fire projectiles. Heavy Mirror makes the encounter more forgiving; perfect timing also follows the core's heavy-projectile rules. A visibly telegraphed fire vent interrupts the route.
- Shadow Temple: dark projectiles require Soul Mirror; a visible outline becomes a solid bridge in Soul or Prism mode.
- Prism Realm: return red, blue, then green projectiles; wrong colors do not reset progress and the emitter never runs out.

The moving platform bridges the first gap in the other four regions. Platforms use layer 1 and one-way elevated collisions. Falls cost 18 HP and return the player to the last altar. Death resets the current boss and clears projectiles. A loaded second checkpoint restores the already-open puzzle seal. Checkpoint signals only occur from player interaction, and boss victory opens the exit rather than immediately changing regions.

## Integration API

`configure(region, progress)` before add_child. Progress flags `checkpoint_region` and `checkpoint_id` (0/1) restore the altar. Root saves the rest. `player`, `boss`, `objective`, `info`, `puzzle_solved`, `boss_defeated`, `checkpoint`, `checkpoint_id` are public. Signals: `checkpoint_reached(region)`, `region_completed(region)`, `story_requested(key)`, `player_died`. Stories use `curse`, `region_N`, `encounter_N`, `victory_N` (N=0..4).

## Verified

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/world_test.gd`

76 checks pass: data/geometry of all five worlds; real hostile projectile motion into the actual player shield and onward into each puzzle target, including the wall bounce and all three colors; gate removal; altar interaction; boss creation; lethal player damage; respawn; boss reset; saved checkpoint reopening. These tests control aim and reflection timing deterministically. They do not measure real player difficulty or completion time.

Integrated startup `--headless --quit-after 120 -- --smoke` runs. At the time of testing the root integration reported two ObjectDB exit leaks; no world test leak or runtime error occurred. A real OpenGL forest frame was rendered and visually inspected: foreground, platforms, player, enemy and shrine are readable.

## Honest limitations

Art is original programmatic placeholder geometry, not a finished production tileset. All five regions currently share the same underlying platform topology with differing encounters, environmental motifs and seal rules. There is one mandatory seal per region, no sprawling exploration map, and no independent continuous-light puzzle or moving-target timing puzzle yet. Three-to-five-hour length has not been achieved or measured. Full human playthrough, all controller paths, and final production balance remain necessary.
