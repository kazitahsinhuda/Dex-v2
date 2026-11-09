extends SceneTree

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, failure: String) -> bool:
	if not condition:
		push_error("UNDERWORLD GAMEPLAY TEST FAILED: " + failure)
		quit(1)
		return false
	return true

func _run_tests() -> void:
	var packed := load("res://main.tscn") as PackedScene
	if not _check(packed != null, "Main scene could not be loaded."):
		return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	# Reset all runtime state so the test is independent of a previous save.
	game.intro_active = false
	game.mission_stage = 0
	game.cash = 2450
	game.sales_completed = 0
	game.stock_owned = false
	game.in_car = false
	game.police_active = false
	game.marcus.visible = true
	game.package_crate.visible = false
	game.lena.visible = false
	game.evidence_case.visible = false
	game.player.visible = true
	game._update_mission_marker()
	game._update_hud()

	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	if not _check(game.mission_stage == 1, "Desk interaction should start the story."):
		return

	game.player.global_position = Vector3(28, 0, -30)
	game._interact()
	if not _check(game.mission_stage == 2, "Meeting Marcus should unlock the warehouse package."):
		return

	game.player.global_position = Vector3(-30, 0, -25)
	game._interact()
	if not _check(game.mission_stage == 3, "Collecting the package should advance the mission."):
		return
	if not _check(game.police_active, "Collecting the package should trigger the police pursuit."):
		return
	if not _check(game.cash == 3200, "Package reward should add $750."):
		return

	game.police_active = false
	game.police_car.visible = false
	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	if not _check(game.mission_stage == 4, "Returning to the dealership should complete chapter one."):
		return
	if not _check(game.cash == 5700, "Chapter completion should add $2,500."):
		return

	# First additional sale.
	game._interact()
	game._interact()
	if not _check(not game.stock_owned and game.sales_completed == 2, "First trade-in sale should complete."):
		return
	# Second additional sale unlocks Chapter 2.
	game._interact()
	game._interact()
	if not _check(game.mission_stage == 5, "Two profitable trade-in sales should unlock Chapter 2."):
		return

	game.player.global_position = game.lena.global_position
	game._interact()
	if not _check(game.mission_stage == 6, "Lena should give the storage-yard mission."):
		return
	game.player.global_position = game.evidence_case.global_position
	game._interact()
	if not _check(game.mission_stage == 7, "Recovering the service file should advance the story."):
		return
	game.police_active = false
	game.police_car.visible = false

	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	if not _check(game.mission_stage == 8, "Returning the service file should unlock the Marcus meeting."):
		return
	game.player.global_position = game.marcus.global_position
	game._interact()
	if not _check(game.mission_stage == 9, "Marcus should reveal the records-depot location."):
		return
	game.player.global_position = game.evidence_case.global_position
	game._interact()
	if not _check(game.mission_stage == 10, "Finding the final ledger should advance to the finale."):
		return
	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	if not _check(game.mission_stage == 11, "Returning the final ledger should complete the campaign."):
		return

	game._save_game()
	print("UNDERWORLD GAMEPLAY TEST: PASS")
	quit(0)
