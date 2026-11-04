# Core gameplay implementation

Implemented `PrismPlayer`, `PrismProjectile`, and pure `PrismCombat` helpers. No runtime packages or external art are required.

## Inputs and integration

Root supplies InputMap actions from CONTRACT plus `absorb` (hold while guarding, recommended R) and `release` (recommended C). Absorb needs 10 energy, unlocks in region 1, preserves attack kind/element/damage/speed, expires after 18 seconds. Capacity becomes two at upgrade level 3. Mode advances through unlocked modes with Q.

`combat_event(kind, position)` supports root sound integration: jump, dash, mode, guard, perfect, reflect, guard_break, absorb, release, bash, damage. `stats_changed` is emitted each simulation tick for HUD refresh; root should not persist on every HUD signal.

Player center is `global_position + Vector2(0,-18)` and feet are the Node position. Collision capsule is currently a rectangle 16×32 with terrain mask 1. Enemy hit detection sweeps projectile motion, independent of actor physics bodies. Final boss may implement `intercept_projectile(p)->bool`; returning true skips damage and consumption. Enemy bash supports `stun(seconds)`.

## Behavior

Acceleration, jump release height, 0.10-second coyote time, 0.13-second jump buffer, dash cooldown/i-frames, floor snap, keyboard/mouse or analog aim, optional eight-direction aim. Every attack is shield based. Stamina guard break lasts 0.8 seconds. Reflect lasts 0.28 seconds with a 0.32-second cooldown. Perfect starts at 0.12 seconds (focus mode 0.085); assist adds 0.09 seconds. Front-facing dot-product tests reject attacks from behind. Reflection uses normalized `Vector2.bounce`. Reflected shots change owner/team, receive collision grace and cap speed/reflection count. Burst damage conserves approximately the original total (0.44 + 2×0.2772).

Modes: base; split; focus damage; heavy slow movement with reduced guard cost; soul dark defense; prism accepts dark and heavy. Element is preserved on all reflections. Ice slows, fire burns and poison ticks after successful health hits. Invulnerable contacts do not apply ailments. Healing clears ailments. Upgrades increase stamina and eventually storage. Health and mana are plain public values for root persistence/HUD.

## Art and limitations

All visuals are ORIGINAL TEMPORARY programmatic pixel geometry with separate aimed shield and run/idle/jump/fall/dash/guard/reflect/bash/death cues. They are not a finished authored sprite sheet. Beam projectiles are luminous travelling pulses; true continuous ray clipping/redirection is not implemented in this core module. Hit-stop is currently a 35ms pause of player movement, not a global simulation freeze. Explosions have a 42px splash on both teams with line-of-sight terrain occlusion, primary-hit exclusion and one-shot consumption. Guard and absorb neutralize explosive payloads. Reflected splash preserves elemental status. Prism mode unifies defenses; full element-selection/synergy design remains for content iteration. Victory/interact state animations need root integration.

## Tests

Run `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/core_test.gd`. 60 checks pass, covering reflection vectors across 32 directions, angled reflection, rear vulnerability, normal/perfect windows, ownership, damage/energy, stamina/break, unlocks, dark defense, element-preserving absorb/release, duplicate damage prevention, real physics landing, movement, jumping and dash, explosive guard neutralization, reflected area damage/range/duplicate-hit prevention, burn/slow/heal, and i-frame status rejection. These are deterministic mechanics tests, not a full human playthrough or performance certification.


## Reduced effects
Root may set "effects_intensity" on the player from 0 to 1. At zero, invulnerability blinking, perfect flash rings, dash afterimages and projectile trails are removed. Core projectile shapes, shield arc and explosion boundary remain readable. Projectiles inherit the live player value during drawing. This does not change timing or collision mechanics.

