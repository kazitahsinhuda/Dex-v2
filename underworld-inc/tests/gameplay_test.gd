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

	# A save from the earlier prototype must not bypass the new story opening.
	var legacy_save := ConfigFile.new()
	legacy_save.set_value("career", "mission_stage", 6)
	legacy_save.set_value("career", "cash", 900)
	legacy_save.save("user://underworld_save.cfg")
	game._load_game()
	if not _check(game.mission_stage == 0 and game.cash == 2450, "Legacy saves should migrate to a clean story start."):
		return
	game._start_intro()
	if not _check(game.intro_active and is_equal_approx(game.player.global_position.x, 130.0), "A migrated save should start inside the office prologue."):
		return

	# Reset all runtime state so the test is independent of a previous save.
	game.intro_active = false
	game.mission_stage = 0
	game.cash = 2450
	game.sales_completed = 0
	game.stock_owned = false
	game.stock_repaired = false
	game.in_car = false
	game.police_active = false
	game.marcus.visible = true
	game.package_crate.visible = false
	game.lena.visible = false
	game.evidence_case.visible = false
	game.detective.visible = false
	game.player.visible = true
	game._update_mission_marker()
	game._update_hud()

	if not _check(game.parked_cars.size() >= 4, "Street vehicles should be enterable CharacterBody3D cars."):
		return
	if not _check(game._world_material("Main road", Color(0.07, 0.08, 0.1)).albedo_texture != null, "Roads should use generated surface textures."):
		return
	var shared_material_a := game._textured_material(Color(0.2, 0.2, 0.2), "cache_test", 0.05, 2.0)
	var shared_material_b := game._textured_material(Color(0.2, 0.2, 0.2), "cache_test", 0.05, 2.0)
	if not _check(shared_material_a == shared_material_b, "Procedural materials should be reused instead of duplicated."):
		return
	game._set_intro_scene(0)
	if not _check(is_equal_approx(game.player.global_position.x, 130.0), "Opening should begin in the office, not the showroom."):
		return
	game._set_intro_scene(2)
	if not _check(is_equal_approx(game.player.global_position.x, 150.0), "Opening should move to Alex's apartment."):
		return
	game._set_intro_scene(4)
	if not _check(is_equal_approx(game.player.global_position.x, 170.0), "Opening should move to the bus stop."):
		return
	game._set_intro_scene(5)
	if not _check(is_equal_approx(game.player.global_position.x, 0.0), "Opening should finish outside Westbridge Motors."):
		return

	# Test entering and exiting a parked street vehicle.
	var test_vehicle: CharacterBody3D = game.parked_cars[0]
	game.player.global_position = test_vehicle.global_position + Vector3(0, 0.2, 2.0)
	game._interact()
	if not _check(game.in_car and game.active_car == test_vehicle, "Player should enter a parked car."):
		return
	game._interact()
	if not _check(not game.in_car and game.player.visible, "Player should be able to exit a parked car."):
		return

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

	# First additional sale: buy, repair at the workshop, then sell.
	game._interact()
	game.player.global_position = game.repair_bay_position
	game._interact()
	if not _check(game.stock_repaired, "Workshop should repair the purchased trade-in."):
		return
	game.player.global_position = Vector3(0, 1, -1.2)
	game._interact()
	if not _check(not game.stock_owned and game.sales_completed == 2, "First repaired trade-in sale should complete."):
		return
	# Second repaired sale unlocks Chapter 2.
	game._interact()
	game.player.global_position = game.repair_bay_position
	game._interact()
	game.player.global_position = Vector3(0, 1, -1.2)
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
	if not _check(game.mission_stage == 11, "Returning the final ledger should unlock the final choice."):
		return

	game.player.global_position = game.detective.global_position
	game._interact()
	if not _check(game.mission_stage == 12, "Choosing Detective Reed should unlock the clean ending."):
		return

	# Verify the alternate ending branch as well.
	game.mission_stage = 11
	game.detective.visible = true
	game.marcus.visible = true
	game.player.global_position = game.marcus.global_position
	game._interact()
	if not _check(game.mission_stage == 13, "Choosing Marcus should unlock the underworld ending."):
		return

	game._save_game()
	print("UNDERWORLD GAMEPLAY TEST: PASS")
	quit(0)
