class_name PrismTimeControl
extends RefCounted

const SLOW_SCALE := 0.3
const MAX_METER := 3.0
const REGEN_DELAY := 1.5
const REGEN_TIME := 2.0
const MIN_ACTIVATE := 0.1

var meter: float = MAX_METER
var active: bool = false
var idle_time: float = 0.0

# real_delta is unscaled seconds (delta / Engine.time_scale).
func update(real_delta: float, wants_slow: bool) -> float:
	var can_slow := meter >= MIN_ACTIVATE or active
	if wants_slow and can_slow:
		active = true
		idle_time = 0.0
		meter = maxf(0.0, meter - real_delta)
		if meter <= 0.0:
			active = false
	else:
		active = false
		var before := idle_time
		idle_time += real_delta
		var regen_span := clampf(idle_time - maxf(before, REGEN_DELAY), 0.0, real_delta)
		meter = minf(MAX_METER, meter + regen_span * MAX_METER / REGEN_TIME)
	var scale := SLOW_SCALE if active else 1.0
	Engine.time_scale = scale
	return scale

func reset() -> void:
	meter = MAX_METER
	active = false
	idle_time = 0.0
	Engine.time_scale = 1.0
