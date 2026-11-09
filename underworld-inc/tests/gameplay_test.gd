extends SceneTree

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var packed := load("res://main.tscn") as PackedScene
	assert(packed != null, "Main scene could not be loaded.")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	# Start from a clean career and skip the opening prologue for this mission-loop test.
	game.intro_active = false
	game.mission_stage = 0
	game.cash = 2450
	game.sales_completed = 0
	game.stock_owned = false
	game._update_mission_marker()
	game._update_hud()

	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	assert(game.mission_stage == 1, "Desk interaction should start the story.")

	game.player.global_position = Vector3(28, 0, -30)
	game._interact()
	assert(game.mission_stage == 2, "Meeting Marcus should unlock the warehouse package.")

	game.player.global_position = Vector3(-30, 0, -25)
	game._interact()
	assert(game.mission_stage == 3, "Collecting the package should advance the mission.")
	assert(game.police_active, "Collecting the package should trigger the police pursuit.")
	assert(game.cash == 3200, "Package reward should add $750.")

	game.police_active = false
	game.police_car.visible = false
	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	assert(game.mission_stage == 4, "Returning to the dealership should complete chapter one.")
	assert(game.cash == 5700, "Chapter completion should add $2,500.")

	game._interact()
	assert(game.stock_owned, "Dealership should purchase a trade-in.")
	assert(game.cash == 4500, "Buying a trade-in should cost $1,200.")
	game._interact()
	assert(not game.stock_owned, "Dealership should close the trade-in sale.")
	assert(game.cash == 6450, "Selling the trade-in should return $1,950.")
	assert(game.sales_completed == 2, "Story completion and trade-in should count as sales.")

	# Complete the two additional dealership sales required to unlock Chapter 2.
	game._interact()
	game._interact()
	game._interact()
	game._interact()
	assert(game.mission_stage == 5, "Two further profitable sales should unlock Chapter 2.")

	game.player.global_position = game.lena.global_position
	game._interact()
	assert(game.mission_stage == 6, "Lena should give the storage-yard mission.")
	game.player.global_position = game.evidence_case.global_position
	game._interact()
	assert(game.mission_stage == 7, "Recovering the service file should advance the story.")
	game.police_active = false
	game.police_car.visible = false

	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	assert(game.mission_stage == 8, "Returning the service file should unlock the Marcus meeting.")
	game.player.global_position = game.marcus.global_position
	game._interact()
	assert(game.mission_stage == 9, "Marcus should reveal the records-depot location.")
	game.player.global_position = game.evidence_case.global_position
	game._interact()
	assert(game.mission_stage == 10, "Finding the final ledger should advance to the finale.")
	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	assert(game.mission_stage == 11, "Returning the final ledger should complete the campaign.")

	game._save_game()
	print("UNDERWORLD GAMEPLAY TEST: PASS")
	quit()
