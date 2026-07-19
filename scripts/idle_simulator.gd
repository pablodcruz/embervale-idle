class_name IdleSimulator
extends RefCounted

const EPSILON := 0.0001


static func queue_starter_plan(state: Dictionary, log_count: int = 10) -> bool:
	if not state.get("queue", []).is_empty() or state.get("current_action") != null:
		return false
	var current_location: String = state.get("location", "emberstead")
	if current_location != "whisperwood":
		state["queue"].append(_travel_action(current_location, "whisperwood"))
	state["queue"].append(_gather_action(log_count))
	state["queue"].append(_travel_action("whisperwood", "emberstead"))
	return true


static func advance(state: Dictionary, elapsed_seconds: float) -> Array[String]:
	var events: Array[String] = []
	if elapsed_seconds <= 0.0 or state.get("paused", false):
		return events
	var remaining_time := elapsed_seconds
	while remaining_time > EPSILON:
		if state.get("current_action") == null:
			var queue: Array = state.get("queue", [])
			if queue.is_empty():
				break
			state["current_action"] = queue.pop_front()
			events.append("Started: %s" % GameContent.action_label(state["current_action"]))
		var action: Dictionary = state["current_action"]
		var action_remaining := float(action.get("remaining", action.get("duration", 1.0)))
		var step := minf(remaining_time, action_remaining)
		action_remaining -= step
		remaining_time -= step
		state["total_play_seconds"] = float(state.get("total_play_seconds", 0.0)) + step
		action["remaining"] = action_remaining
		state["current_action"] = action
		if action_remaining <= EPSILON:
			_complete_cycle(state, action, events)
	return events


static func current_progress(state: Dictionary) -> float:
	var action: Variant = state.get("current_action")
	if action == null:
		return 0.0
	var duration := maxf(float(action.get("duration", 1.0)), EPSILON)
	return clampf(1.0 - float(action.get("remaining", duration)) / duration, 0.0, 1.0)


static func seconds_remaining(state: Dictionary) -> float:
	var total := 0.0
	var current: Variant = state.get("current_action")
	if current != null:
		total += float(current.get("remaining", 0.0))
		if current.get("type") == "gather":
			total += maxf(float(current.get("count", 1) - 1), 0.0) * float(current.get("duration", 0.0))
	for action: Dictionary in state.get("queue", []):
		if action.get("type") == "gather":
			total += float(action.get("count", 0)) * float(action.get("duration", 0.0))
		else:
			total += float(action.get("remaining", action.get("duration", 0.0)))
	return total


static func _complete_cycle(state: Dictionary, action: Dictionary, events: Array[String]) -> void:
	match action.get("type", ""):
		"travel":
			state["location"] = action.get("to", state.get("location", "emberstead"))
			events.append("Arrived at %s." % GameContent.LOCATION_NAMES.get(state["location"], "Unknown"))
			state["current_action"] = null
		"gather":
			var inventory: Dictionary = state["inventory"]
			inventory["pine_log"] = int(inventory.get("pine_log", 0)) + 1
			var skills: Dictionary = state["skills"]
			skills["woodcutting_xp"] = int(skills.get("woodcutting_xp", 0)) + GameContent.PINE_LOG_XP
			action["count"] = int(action.get("count", 1)) - 1
			if int(action["count"]) <= 0:
				events.append("Gathering complete: pine logs secured.")
				state["current_action"] = null
			else:
				action["remaining"] = float(action.get("duration", GameContent.CHOP_SECONDS))
				state["current_action"] = action
		_:
			state["current_action"] = null


static func _travel_action(from_id: String, to_id: String) -> Dictionary:
	return {
		"type": "travel",
		"from": from_id,
		"to": to_id,
		"duration": GameContent.TRAVEL_SECONDS,
		"remaining": GameContent.TRAVEL_SECONDS,
	}


static func _gather_action(count: int) -> Dictionary:
	return {
		"type": "gather",
		"item": "pine_log",
		"count": maxi(count, 1),
		"duration": GameContent.CHOP_SECONDS,
		"remaining": GameContent.CHOP_SECONDS,
	}
