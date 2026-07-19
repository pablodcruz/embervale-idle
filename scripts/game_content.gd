class_name GameContent
extends RefCounted

const LOCATION_NAMES := {
	"emberstead": "Emberstead",
	"whisperwood": "Whisperwood",
}

const PINE_LOG_XP := 5
const TRAVEL_SECONDS := 6.0
const CHOP_SECONDS := 2.0
const OFFLINE_CAP_SECONDS := 8.0 * 60.0 * 60.0


static func new_state() -> Dictionary:
	return {
		"version": 1,
		"location": "emberstead",
		"inventory": {"pine_log": 0},
		"skills": {"woodcutting_xp": 0},
		"queue": [],
		"current_action": null,
		"paused": false,
		"total_play_seconds": 0.0,
		"last_saved_unix": 0.0,
	}


static func woodcutting_level(xp: int) -> int:
	# Friendly prototype curve: every 50 XP grants a level.
	return 1 + int(xp / 50.0)


static func action_label(action: Variant) -> String:
	if action == null:
		return "Resting in town"
	match action.get("type", ""):
		"travel":
			return "Travelling to %s" % LOCATION_NAMES.get(action.get("to", ""), "Unknown")
		"gather":
			return "Chopping pine · %d remaining" % int(action.get("count", 0))
		_:
			return "Preparing the next step"
