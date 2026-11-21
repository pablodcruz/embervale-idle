extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_complete_plan(failures)
	_test_chunking_equivalence(failures)
	_test_pause(failures)
	preload("res://tests/save_regression.gd").run(failures)
	if failures.is_empty():
		print("PASS: simulator and save tests")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_complete_plan(failures: Array[String]) -> void:
	var state := GameContent.new_state()
	IdleSimulator.queue_starter_plan(state, 10)
	IdleSimulator.advance(state, 32.0)
	_expect(state["location"] == "emberstead", "plan should finish in Emberstead", failures)
	_expect(int(state["inventory"]["pine_log"]) == 10, "plan should gather 10 logs", failures)
	_expect(int(state["skills"]["woodcutting_xp"]) == 50, "plan should award 50 XP", failures)
	_expect(state["current_action"] == null and state["queue"].is_empty(), "plan should fully drain", failures)


func _test_chunking_equivalence(failures: Array[String]) -> void:
	var one_pass := GameContent.new_state()
	var many_steps := GameContent.new_state()
	IdleSimulator.queue_starter_plan(one_pass, 10)
	IdleSimulator.queue_starter_plan(many_steps, 10)
	IdleSimulator.advance(one_pass, 19.25)
	for i in 77:
		IdleSimulator.advance(many_steps, 0.25)
	_expect(one_pass["location"] == many_steps["location"], "chunked simulation location mismatch", failures)
	_expect(one_pass["inventory"] == many_steps["inventory"], "chunked simulation inventory mismatch", failures)
	_expect(one_pass["skills"] == many_steps["skills"], "chunked simulation XP mismatch", failures)
	_expect(absf(IdleSimulator.seconds_remaining(one_pass) - IdleSimulator.seconds_remaining(many_steps)) < 0.001, "chunked simulation remaining time mismatch", failures)


func _test_pause(failures: Array[String]) -> void:
	var state := GameContent.new_state()
	IdleSimulator.queue_starter_plan(state, 10)
	state["paused"] = true
	IdleSimulator.advance(state, 100.0)
	_expect(state["current_action"] == null, "paused state should not start an action", failures)
	_expect(int(state["inventory"]["pine_log"]) == 0, "paused state should not grant items", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: %s" % message)
