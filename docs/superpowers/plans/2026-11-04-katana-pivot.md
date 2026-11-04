# Katana Zero Pivot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn PRISMBOUND into a one-hit-death, room-based shield action game: kills only by reflected projectiles or a thrown, ricocheting shield; slow-motion; per-room timer; dialogue between chapters; multi-hit phased bosses.

**Architecture:** Refactor in place. `player.gd`/`projectile.gd`/`enemy.gd` are stripped of HP, stamina, modes, elements and absorb. Two new focused modules (`time_control.gd`, `thrown_shield.gd`). `world.gd` becomes a chapter controller that builds one `room.gd` at a time from `data/rooms.json`; room reset = free the room node and rebuild it from data.

**Tech Stack:** Godot 4.7.2, GDScript, headless `SceneTree` test scripts (no test framework).

**Spec:** `docs/superpowers/specs/2026-11-04-katana-pivot-design.md`

## Global Constraints

- Internal resolution 640×360, 60 FPS, Windows export preset "Windows Desktop" unchanged.
- All player-facing text Turkish; identifiers English.
- One-hit death for player and regular enemies. Bosses take hits: region 0..4 → `[3, 4, 4, 5, 5]` hits.
- Reflect window 0.20 s, cooldown 0.30 s. Reflected speed `clamp(incoming * 1.2, 180, 650)`.
- Thrown shield: speed 420 px/s, max 3 bounces, out time 1.2 s, return speed 520 px/s, catch radius 16 px. Reflect disabled while thrown.
- Slow-mo: `Engine.time_scale = 0.3`, meter 3.0 s, regen delay 1.5 s, full regen in 2.0 s (real time).
- Death → room rebuild after 0.3 s on input, automatic after 1.0 s.
- Input actions: `move_left move_right jump dash reflect throw slow restart interact pause aim_left aim_right aim_up aim_down`. Defaults: A/D, Space, Left Ctrl, LMB, RMB, Shift, R, E, Esc. Gamepad: A jump, B dash, RB reflect, RT throw, LT slow, Y restart, Start pause, sticks move/aim.
- Save written only on room/chapter completion. Save schema version 2.
- Tests run with `godot --headless --path . --script tests/<name>.gd` (`godot` = `Godot_v4.7.2-stable_win64_console.exe`; set an alias/`$GODOT` if not on PATH). Each test prints `<NAME> TESTS: N checks, 0 failures` and exits 0 on success. Keep the existing `check(condition, message)` harness pattern from `tests/core_test.gd`.

## Review Focus

1. Player dies (or pauses / returns to menu) while slow-mo is held → `Engine.time_scale` must be 1.0 afterwards. Test in Task 6.
2. Player dies or room resets while the shield is thrown → no orphan `thrown_shields` node, `player.shield_out == false` in the new room. Test in Task 6.
3. Shield thrown point-blank into a wall (spawn overlapping solid) → must not loop forever; returns within `OUT_TIME + 1.0` s. Test in Task 3.
4. Player death and exit entry on the same frame → exactly one room rebuild/advance, never two room nodes. Test in Task 6.
5. Old v1 save or corrupt main save → v1 migrates (`unlocked` → `unlocked_chapter`), corrupt main falls back to backup, garbage yields `fresh()`. Test in Task 5.

---

### Task 1: One-hit core — projectile and player reflect

**Files:**
- Modify: `scripts/projectile.gd`, `scripts/player.gd`, `scripts/combat.gd`, `scripts/enemy.gd:267-278` (`_shoot`/`_spread` call sites only), `scripts/world.gd:251` (spawn call only)
- Rewrite: `tests/core_test.gd`
- Delete: `tests/world_test.gd`, `tests/integration_test.gd` (+ `.uid`) — recreated in Tasks 4 and 6

**Interfaces:**
- Produces:
  - `PrismProjectile.spawn(parent: Node, pos: Vector2, vel: Vector2, type: String = "normal", allegiance: int = 0) -> PrismProjectile`. Kinds kept: `normal arc heavy beam shockwave`. Removed: `damage element explosion_timer primary_hit perfect` and splash logic.
  - Projectile hit dispatch: team 0 vs player → `player.handle_projectile(p) -> bool` first (true = reflected, keep flying), else `player.kill(from: Vector2)`. Team 1 vs group `enemies` → `target.hit_by(source: Node, from: Vector2, cause: String) -> bool` with `cause = "reflect"`; projectile is consumed whether or not it returns true. `intercept_projectile` call removed.
  - `PrismPlayer`: `signal died`, `var dead: bool`, `var shield_out: bool = false`, `func kill(from: Vector2) -> void`, `func handle_projectile(p: Node) -> bool`, `const REFLECT_WINDOW := 0.20`, `const REFLECT_COOLDOWN := 0.30`. `combat_event(kind, position)` kept with kinds `jump dash reflect throw catch death`.
  - Removed from player: hp/stamina/energy/shards/mode/unlocked_modes/stored_attacks/absorb/guard/bash/statuses/`configure_progress`/`heal`/`take_damage`/`apply_status`/`stats_changed`.
  - `combat.gd`: keep `reflected`, `facing`, `segment_distance`; delete mode/element constants and `element_color`.

- [ ] **Step 1: Rewrite `tests/core_test.gd`** with the same harness (InputMap actions from Global Constraints) and these checks:
  - `test_front_reflect`: player aim RIGHT, `reflect_timer = 0.0`; shot from (+60, -18) relative, velocity (-200, 0) → `handle_projectile` true, `p.team == 1`, `p.velocity.x > 0`, `abs(p.velocity.length() - 240) < 1`.
  - `test_reflect_window_expired`: `reflect_timer = 0.21` → `handle_projectile` false.
  - `test_rear_hit_kills`: aim RIGHT, shot from the left moving right → false; then dispatch via projectile physics one step → `player.dead == true`, `died` emitted once.
  - `test_no_reflect_while_shield_out`: `shield_out = true`, valid front shot → false.
  - `test_kill_idempotent`: `kill()` twice → `died` emitted exactly once.
  - `test_dash_iframes`: `dash_timer > 0` → `kill()` ignored, `dead == false`.
  - `test_reflected_shot_kills_enemy`: stub enemy (group `enemies`, `hurt_radius`, `hit_by` records cause) → team-1 projectile stepped into it → stub got `"reflect"`, projectile `dead`.
  - Keep existing movement/jump/dash/landing checks and the 32-direction `Combat.reflected` check.
- [ ] **Step 2: Run** `godot --headless --path . --script tests/core_test.gd` → expect failures (missing `kill`, `shield_out`, `hit_by` dispatch).
- [ ] **Step 3: Implement** the Interfaces above. Reflect: inside window and `Combat.facing(...)` true → velocity `Combat.reflected(v, aim) * clamp(|v|*1.2, 180, 650)`, `team = 1`, `owner_actor = player`, `collision_grace = 0.055`, reposition to `center + aim * 33`, `reflection_count += 1`, 35 ms hit-stop. Update `enemy._shoot`/`_spread` and `world.gd:251` to the new `spawn` signature (drop damage/element args) so the project still parses.
- [ ] **Step 4: Run** core test → `CORE TESTS: N checks, 0 failures`. Also `godot --headless --path . --editor --import --quit` → no script parse errors.
- [ ] **Step 5: Commit** `feat: one-hit player and reflect-only projectile core`.

### Task 2: Slow-motion time control

**Files:**
- Create: `scripts/time_control.gd`
- Test: `tests/core_test.gd` (append)

**Interfaces:**
- Produces: `class_name PrismTimeControl extends RefCounted` with `const SLOW_SCALE := 0.3`, `const MAX_METER := 3.0`, `const REGEN_DELAY := 1.5`, `const REGEN_TIME := 2.0`, `var meter: float = MAX_METER`, `var active: bool`, `func update(real_delta: float, wants_slow: bool) -> float` (returns scale and writes `Engine.time_scale`), `func reset() -> void` (meter full, inactive, `Engine.time_scale = 1.0`). Caller passes real delta (`delta / Engine.time_scale`).

- [ ] **Step 1: Append tests**:
  - `test_slow_drains`: `update(1.0, true)` → returns 0.3, `meter == 2.0`, `Engine.time_scale == 0.3`.
  - `test_slow_empties`: three more seconds held → meter 0, returns 1.0, `active == false`.
  - `test_regen_delay`: after release, `update(1.4, false)` → meter unchanged; `update(0.1 + 2.0, false)` → `meter == 3.0`.
  - `test_reset`: while active, `reset()` → `Engine.time_scale == 1.0`.
- [ ] **Step 2: Run** → FAIL (missing script).
- [ ] **Step 3: Implement** `scripts/time_control.gd`. Regen rate `MAX_METER / REGEN_TIME` per real second after `REGEN_DELAY` of not slowing; no reactivation while meter < 0.1.
- [ ] **Step 4: Run** → 0 failures.
- [ ] **Step 5: Commit** `feat: add slow-motion meter`.

### Task 3: Thrown, ricocheting shield

**Files:**
- Create: `scripts/thrown_shield.gd`
- Modify: `scripts/player.gd` (`throw` action, shield draw hidden while out)
- Test: `tests/core_test.gd` (append)

**Interfaces:**
- Consumes: `player.shield_out`, `enemy.hit_by(source, from, cause)`.
- Produces: `class_name PrismThrownShield extends Node2D`, group `thrown_shields`; `const SPEED := 420.0`, `MAX_BOUNCES := 3`, `OUT_TIME := 1.2`, `RETURN_SPEED := 520.0`, `CATCH_RADIUS := 16.0`; `static func launch(parent: Node, from: Vector2, direction: Vector2, thrower: Node2D) -> PrismThrownShield`; `var velocity`, `var bounces: int`, `var returning: bool`; `func recall() -> void`; `signal caught`. Player: pressing `throw` with shield in hand → `launch(get_parent(), center + aim*20, aim, self)`, `shield_out = true`; pressing again while out → `recall()`; on `caught` → `shield_out = false`. Player `kill()` frees any own shield.

- [ ] **Step 1: Append tests** (world with a `StaticBody2D` wall at x=300 on layer 1, a floor):
  - `test_shield_bounces_and_returns`: launch right from x=200 → after stepping physics, `bounces >= 1` and velocity.x < 0 after hitting wall; eventually `caught` emitted and `player.shield_out == false`.
  - `test_shield_max_bounces`: in a 2-wall corridor, `bounces` never exceeds 3 and `returning` becomes true at the 3rd.
  - `test_shield_kills_each_enemy_once`: two stub enemies on path → each `hit_by(..., "shield")` called exactly once per throw, shield keeps flying.
  - `test_shield_recall`: `recall()` → `returning == true` immediately.
  - `test_shield_point_blank_wall` (Review Focus 3): launch from inside wall overlap → caught within `OUT_TIME + 1.0` s simulated.
  - `test_reflect_blocked_while_out` already covered in Task 1 — verify through real `throw` here.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** Outbound: ray query layer 1 from previous to next position; on hit, `velocity = velocity.bounce(normal)`, move to `hit.position + normal * 2`, `bounces += 1`; `returning` when `bounces == MAX_BOUNCES` or age ≥ `OUT_TIME`. Returning: ignore walls, home toward thrower center at `RETURN_SPEED`, emit `caught` and free within `CATCH_RADIUS`. Enemy hits by `Combat.segment_distance` against `hurt_radius + 8`, tracked in a `hit_set` Dictionary.
- [ ] **Step 4: Run** → 0 failures.
- [ ] **Step 5: Commit** `feat: add thrown ricocheting shield`.

### Task 4: One-hit enemies, armored, melee, multi-hit bosses

**Files:**
- Modify: `scripts/enemy.gd`
- Rewrite: `tests/enemy_test.gd`

**Interfaces:**
- Consumes: projectile `spawn` (Task 1), `player.kill(from)`.
- Produces:
  - `const TYPE_IDS := {"shooter": 0, "feint": 1, "spread": 2, "armored": 3, "beam": 4, "melee": 6}`; archetype 5 (ghost) removed with decoys, statuses, stun, `take_damage`, `apply_status`, `intercept_projectile`, hp.
  - `func configure(type: int, area: int, boss: bool = false, start_phase: int = 1) -> void`.
  - `func hit_by(source: Node, from: Vector2, cause: String) -> bool`: dead → false. Armored (3) and `cause == "reflect"` and `signf(from.x - global_position.x) == facing` → false. Regular → `_die()`, true. Boss → `hits_left -= 1`, flash, update phase, true; `_die()` at 0.
  - Boss: `const BOSS_HITS := [3, 4, 4, 5, 5]`, `var hits_left: int`, `var phase: int`, `func phase_for_hits(hits_left: int) -> int` (phase 1 until hits taken ≥ ceil(total/2), phase 2 after; region 4 adds phase 3 when hits_left == 1), `signal phase_changed(phase)`. `configure(..., start_phase)` sets `hits_left` to the first value of that phase.
  - Melee (6): contact within 22 px during attack → `player.kill(global_position)`. Any regular enemy's contact attack kills the player the same way.
  - `signal defeated(enemy)` emitted once (unchanged).
- [ ] **Step 1: Rewrite `tests/enemy_test.gd`**:
  - For each type in `TYPE_IDS`: `hit_by(stub, behind, "reflect")` → true, `defeated` once; second call → false.
  - Armored: front `"reflect"` → false and alive; front `"shield"` → true.
  - Melee: `"reflect"` (another enemy's reflected shot) → dies; `"shield"` → dies; touching player during attack → `player.dead`.
  - Bosses 0..4: exactly `BOSS_HITS[r]` hits to die; `phase_changed` emitted at the expected hit; `configure(..., start_phase = 2)` → `hits_left == BOSS_HITS[r] - ceil(BOSS_HITS[r]/2)`.
  - Telegraph timing checks from the old test kept (0.65 s regular, 0.8 s boss).
- [ ] **Step 2: Run** `godot --headless --path . --script tests/enemy_test.gd` → FAIL.
- [ ] **Step 3: Implement** the Interfaces. Keep existing attack patterns; delete element branches (projectile kinds stay).
- [ ] **Step 4: Run** → 0 failures; rerun core_test → still 0.
- [ ] **Step 5: Commit** `feat: one-hit enemies, armored front, melee, hit-count bosses`.

### Task 5: Save schema v2 and migration

**Files:**
- Modify: `scripts/save_manager.gd`
- Create: `tests/save_test.gd`

**Interfaces:**
- Produces: `static func fresh() -> Dictionary` → `{"version": 2, "unlocked_chapter": 0, "best_times": {}, "total_deaths": 0}`; `static func valid(data) -> bool` (v2 shape, chapter 0..4, best_times values numbers > 0, deaths ≥ 0); `static func migrate(data: Dictionary) -> Dictionary` (v1 → v2: `unlocked_chapter = clamp(int(unlocked), 0, 4)`, others fresh; v2 returned as-is); `static func record_room(data: Dictionary, room_id: String, time: float) -> Dictionary` (keeps min); `load_game()` = read main → migrate → valid, else backup, else `fresh()`. Settings functions unchanged. Tests may override `PATH`/`BACKUP` static vars to `user://test_*.json`.
- [ ] **Step 1: Write `tests/save_test.gd`**: fresh is valid; v1 `{"version":1,"region":3,"unlocked":3,"upgrades":2,"shards":9,...}` → `unlocked_chapter == 3`, valid; `record_room` keeps the lower of 12.5 and 9.1, ignores 15.0; corrupt main + valid backup → backup data; both corrupt → `fresh()`; save→load round-trip equals input.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → `SAVE TESTS: N checks, 0 failures`.
- [ ] **Step 5: Commit** `feat: save schema v2 with best times and v1 migration`.

### Task 6: Room system, chapter flow, Forest chapter

**Files:**
- Create: `scripts/room.gd`, `data/rooms.json`, `tests/room_test.gd`
- Rewrite: `scripts/world.gd` (chapter controller; parallax/palette drawing from `data/regions.json` may be kept, everything altar/puzzle/seal/moving-platform removed)

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces:
  - `rooms.json`: `{"chapters": [[room, ...] x5]}`; room = `{"id": String, "size": [w,h], "spawn": [x,y], "exit": [x,y], "solids": [[x,y,w,h]...], "enemies": [{"type": String, "pos": [x,y], "facing": -1|1}], "boss": int|null}`. Chapter 0 (Forest) authored now: 5 rooms (`forest_1`..`forest_5`) teaching in order shooter → feint → spread → armored + throw → melee + mixed, then `forest_boss` (`"boss": 0`). Chapters 1–4 contain one placeholder room each until Task 8.
  - `class_name PrismRoom extends Node2D`: `static func load_rooms(path: String = "res://data/rooms.json") -> Dictionary` (returns `{}` on read/parse failure), `static func validate_room(d: Dictionary) -> String` ("" if ok, else Turkish reason), `func configure(data: Dictionary, boss_start_phase: int = 1) -> void`, `var player: PrismPlayer`, `var enemies_left: int`, `var exit_open: bool`, `var elapsed: float`, `var boss: Node`, signals `cleared`, `exited`, `player_died`, `boss_phase_reached(phase: int)`. Exit opens when `enemies_left == 0`; player overlapping exit (24 px) while open → `exited` once. Implements `on_projectile_environment(p) -> bool` (solid hit → true).
  - `world.gd` (`class_name PrismWorld`): `func configure(chapter: int, start_room: int = 0) -> void`, `var room: PrismRoom`, `var room_index: int`, `var deaths: int`, `var time_control: PrismTimeControl`, `var boss_phase_checkpoint: int = 1`, `func restart_room() -> void`, signals `room_completed(room_id: String, time: float)`, `chapter_completed(chapter: int)`, `story_requested(key: String)`, `player_died`. Room transitions are guarded by a `transitioning` flag; restart frees the room (and every `projectiles`/`thrown_shields` node), calls `time_control.reset()`, rebuilds from data with `boss_phase_checkpoint`. `story_requested("boss_%d")` on entering a boss room. `_process` drives `time_control.update(delta / Engine.time_scale, Input.is_action_pressed("slow") and not dead)`.
- [ ] **Step 1: Write `tests/room_test.gd`**:
  - every room in `rooms.json` passes `validate_room`; chapter 0 has 6 rooms, last has `boss == 0`; malformed JSON path → `load_rooms` returns `{}`.
  - killing all enemies (`hit_by(..., "shield")`) → `cleared` once, `exit_open`; moving player onto exit → `exited` once → world `room_index == 1`, `room_completed("forest_1", t)` with t > 0.
  - player killed → `player_died`; `restart_room()` → new room node, `enemies_left` equals data count, zero `projectiles` nodes.
  - Review Focus 1: hold slow (`time_control.update(0.5, true)`), kill player, restart → `Engine.time_scale == 1.0`.
  - Review Focus 2: throw shield, kill player, restart → 0 `thrown_shields` nodes, `room.player.shield_out == false`.
  - Review Focus 4: kill player and emit `exited` in the same frame → after two frames exactly one `PrismRoom` child, `room_index` unchanged.
  - Boss room: deal hits to reach phase 2, kill player, restart → boss `phase == 2` and `hits_left` at phase-2 start.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** `room.gd`, `world.gd`, author `rooms.json` Forest rooms (each ≤ 640×360 or ≤ 1280 wide with camera follow; floor + 2–4 platforms; enemies placed so each room is solvable with the verb it teaches).
- [ ] **Step 4: Run** room_test, core_test, enemy_test → all 0 failures.
- [ ] **Step 5: Commit** `feat: data-driven rooms and Forest chapter`.

### Task 7: Main integration — inputs, HUD, death, dialogue, menus

**Files:**
- Modify: `scripts/main.gd`, `project.godot` (only if input map lives there), `README.md` (controls + tests sections), `docs/CORE.md`, `docs/ENEMIES.md`, `docs/WORLD.md` (rewrite to new mechanics, short)
- Create: `tests/integration_test.gd`

**Interfaces:**
- Consumes: `PrismWorld` signals, `PrismSave` v2, `dialogues_tr.json` keys `intro region_N boss_N ending_a`.
- Produces: `main.setup_input()` registers exactly the Global Constraints actions/defaults; settings rebinding screen lists those actions; HUD shows room time `"%.2f"`, `"Ölüm: %d"`, slow meter bar; death overlay text `"ÖLDÜN — R / tık: tekrar"` (restart allowed after 0.3 s, auto at 1.0 s); room complete toast `"Süre %.2f · En iyi %.2f"`; flow: new game → `intro` → `region_0` → chapter 0 … → after chapter 4 boss `ending_a` → credits. Continue → chapter `unlocked_chapter`, room 0. Save written on `room_completed` (best time, deaths) and `chapter_completed` (`unlocked_chapter = max(current, chapter+1)` clamped to 4). Pause and return-to-menu call `time_control.reset()`. Delete `show_altar`, `show_altar_refresh`, `show_final_choice`, upgrade/shard/mode HUD.
- [ ] **Step 1: Write `tests/integration_test.gd`** (`--smoke`-style, instantiate `scenes/main.tscn`): all input actions exist with defaults; new game reaches chapter 0 room 0 after skipping dialogue; clear room 0 programmatically and enter exit → save file has `best_times.forest_1`; place a v1 save then Continue → loads chapter from `unlocked`; pause during slow → `Engine.time_scale == 1.0`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement**; update docs/README controls.
- [ ] **Step 4: Run** all five test scripts → 0 failures; `godot --headless --path . --quit-after 120 -- --smoke` → no `SCRIPT ERROR`.
- [ ] **Step 5: Manual check:** run the game (F5) and play Forest rooms 1–5 + boss; note any unfair room in PROGRESS.md.
- [ ] **Step 6: Commit** `feat: integrate one-hit loop, HUD, dialogue and saves in main`.

### Task 8: Remaining chapters and export

**Files:**
- Modify: `data/rooms.json` (chapters 1–4: 4–6 rooms + boss each), `tests/room_test.gd` (counts), `PROGRESS.md`
- Build: `builds/PRISMBOUND.exe`

**Interfaces:**
- Consumes: room schema (Task 6). Room ids `mine_N`, `castle_N`, `temple_N`, `prism_N`, `<name>_boss`; `boss` = chapter index.

- [ ] **Step 1: Update room_test**: chapters 1–4 each have 5–7 rooms (4–6 + boss), last room `boss == chapter`, all ids unique.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Author rooms**. Introduce per chapter: Mine — beam + bounce-shot angles; Castle — heavy + armored groups; Temple — melee packs needing shield ricochet; Prism — mixed, all types.
- [ ] **Step 4: Run** all tests → 0 failures; `godot --headless --path . --export-release "Windows Desktop" builds/PRISMBOUND.exe` → exe created.
- [ ] **Step 5: Update PROGRESS.md** with test counts and exe path; **commit** `feat: author remaining chapters and export build`.
