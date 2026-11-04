# Enemy/boss implementation

`scripts/enemy.gd` is a configurable Node2D combat actor. All seven regular enemy types and five bosses share an explicit idle/patrol/detect/telegraph/attack/recover/stunned/dead state machine. Boss names and temporary original geometric pixel silhouettes are Turkish. Threats sleep outside 740 pixels. Attack cycles are deterministic, with wind-ups of 0.65 seconds (regular) or 0.8 seconds (boss), and recovery gaps. Bosses enter phase two below 50% HP; the final boss adds phase three below 25%.

## Patterns

- Forest: seeds, lobbed thorns, ground waves, fan volleys.
- Mine: heavy crystal, floor waves, crystal fans, sweeping beam segments; vulnerable core during recovery.
- Castle: fire waves, heavy fire, telegraphed short dash/melee, explosive fan. Non-perfect damage is reduced but not blocked entirely.
- Temple: spirit orbs, spirit fans, visible beam segments, cursed ground waves. Spirit or Prism mode reveals the boss and enables damage.
- Prism: elemental sequences, heavy projectiles, dark fan, beam segments; mirrors horizontal player displacement during recovery. Returns first-reflection projectiles only on selected attack cycles and never returns a projectile twice.

Regular enemies teach a straight shot, delayed feint, angled spread, frontal armor, repeated beam emission, spirit vulnerability, and close melee respectively. Melee-only warriors need bash or neighboring ranged/environmental shots for damage.

## Integration

Call `configure(type, region, is_boss)` before `add_child`. `defeated(enemy)` emits once immediately when HP reaches zero; the enemy removes its collision group and plays a 0.55-second shard animation before freeing. World owns rewards. Boss `phase_changed` is optional for HUD/audio. `hurt_radius` is 16/27 pixels. Player group lookup is lazy and safe. Core must call `intercept_projectile` before damage to support the final boss return.

## Verification and limits

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/enemy_test.gd` validates configuration, telegraph timing, enemy vocabulary, ghost gating, phase changes, defeat cleanup, final counter ownership and bounded reflection, and all eight projectile categories. Tests override projectile spawning to record patterns; this is **not** proof of real human playthrough, balance, pathfinding or performance. Beam is a chain of travelling luminous segments, not a raycast optical beam. Temple uses visible attacks for fairness; fake orb and invisibility-special laser are not implemented. Silhouettes and animation are temporary geometry, not final sprite sheets. Bosses use constrained horizontal movement, not navigation/pathfinding.
