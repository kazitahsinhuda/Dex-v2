extends Node3D

const WALK_SPEED := 5.0
const CAR_SPEED := 22.0
const TURN_SPEED := 1.7

var player: CharacterBody3D
var player_visual: MeshInstance3D
var car: CharacterBody3D
var camera: Camera3D
var hud: Label
var objective: Label
var message: Label
var held: Dictionary = {}
var in_car := false
var first_deal_done := false
var mission_stage := 0
var cash := 2450
var sales_completed := 0
var stock_owned := false
var marcus: Node3D
var package_crate: Node3D
var mission_marker: Node3D
var police_car: CharacterBody3D
var police_active := false
var wanted_timer := 0.0
var police_flash_timer := 0.0
var sun_light: DirectionalLight3D
var day_clock := 8.2
var save_timer := 0.0
var story_message := "WESTBRIDGE, 8:12 AM — Your father's old dealership is finally yours."
var message_timer := 7.0

func _ready() -> void:
	_build_world()
	_build_player()
	_build_car()
	_build_police_car()
	_build_story_characters()
	_build_camera()
	_build_ui()
	_build_mission_marker()
	_load_game()
	_update_hud()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.69, 0.82)
	env.ambient_light_energy = 0.7
	world_env.environment = env
	add_child(world_env)

	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-48, -28, 0)
	sun_light.light_energy = 1.25
	sun_light.shadow_enabled = true
	add_child(sun_light)

	_make_static_box("Ground", Vector3(0, -0.25, 0), Vector3(100, 0.5, 100), Color(0.18, 0.23, 0.22))
	_make_static_box("Main road", Vector3(0, 0.015, 15), Vector3(100, 0.08, 12), Color(0.075, 0.085, 0.10))
	_make_static_box("Cross road", Vector3(-24, 0.02, -2), Vector3(12, 0.09, 80), Color(0.075, 0.085, 0.10))
	for x in range(-45, 50, 10):
		_make_box("Road marking", Vector3(x, 0.07, 15), Vector3(4, 0.025, 0.18), Color(0.88, 0.82, 0.55), self)

	# The dealership: a large glass-fronted showroom with a service bay.
	_make_static_box("Showroom body", Vector3(0, 2.2, -10), Vector3(22, 4.4, 15), Color(0.24, 0.29, 0.34))
	_make_box("Showroom glass", Vector3(0, 2.0, -2.38), Vector3(17, 3.1, 0.12), Color(0.18, 0.48, 0.62, 0.55), self)
	_make_box("Showroom roof", Vector3(0, 4.55, -10), Vector3(23, 0.35, 16), Color(0.055, 0.07, 0.09), self)
	_make_box("Dealership sign", Vector3(0, 4.0, -2.22), Vector3(8.5, 0.65, 0.16), Color(0.82, 0.57, 0.20), self)
	var sign := Label3D.new()
	sign.text = "WESTBRIDGE MOTORS"
	sign.font_size = 46
	sign.position = Vector3(0, 4.0, -2.08)
	sign.pixel_size = 0.012
	sign.modulate = Color(0.08, 0.09, 0.11)
	add_child(sign)

	# Reception desk and a highlighted mission marker.
	_make_box("Reception desk", Vector3(0, 0.65, -1.2), Vector3(3.8, 1.3, 1.1), Color(0.12, 0.15, 0.19), self)
	_make_box("Desk top", Vector3(0, 1.34, -1.2), Vector3(4.0, 0.12, 1.2), Color(0.65, 0.48, 0.30), self)
	_make_box("Mission marker", Vector3(0, 0.08, -3.0), Vector3(2.0, 0.06, 2.0), Color(0.88, 0.62, 0.16, 0.8), self)

	# A small city block around the dealership.
	_make_building(Vector3(-19, 0, -17), Vector3(12, 13, 13), Color(0.31, 0.36, 0.43))
	_make_building(Vector3(19, 0, -19), Vector3(13, 17, 12), Color(0.38, 0.33, 0.30))
	_make_building(Vector3(-20, 0, 8), Vector3(12, 9, 13), Color(0.32, 0.39, 0.39))
	_make_building(Vector3(21, 0, 8), Vector3(14, 11, 14), Color(0.36, 0.35, 0.42))
	_make_building(Vector3(0, 0, -36), Vector3(20, 19, 12), Color(0.28, 0.33, 0.40))
	# More blocks make Westbridge feel like a connected district rather than a test platform.
	_make_building(Vector3(-39, 0, -34), Vector3(11, 15, 15), Color(0.30, 0.34, 0.39))
	_make_building(Vector3(40, 0, -36), Vector3(12, 21, 14), Color(0.35, 0.32, 0.31))
	_make_building(Vector3(-42, 0, 4), Vector3(14, 10, 16), Color(0.34, 0.39, 0.40))
	_make_building(Vector3(42, 0, 5), Vector3(13, 14, 16), Color(0.31, 0.34, 0.43))
	_make_building(Vector3(-4, 0, -53), Vector3(18, 12, 12), Color(0.39, 0.34, 0.30))
	_make_building(Vector3(24, 0, -54), Vector3(15, 17, 13), Color(0.28, 0.35, 0.39))
	_make_box("Garage floor", Vector3(7, 0.04, -1), Vector3(12, 0.12, 9), Color(0.13, 0.15, 0.18), self)
	for tree_pos in [Vector3(-10, 0, 7), Vector3(-14, 0, -7), Vector3(14, 0, 7), Vector3(34, 0, -8), Vector3(-34, 0, -8), Vector3(8, 0, -43), Vector3(-8, 0, -43)]:
		_make_tree(tree_pos)
	for lamp_pos in [Vector3(-12, 0, 11), Vector3(12, 0, 11), Vector3(-12, 0, 19), Vector3(12, 0, 19), Vector3(31, 0, -12), Vector3(-31, 0, -12)]:
		_make_streetlight(lamp_pos)
	_make_parked_car(Vector3(-8, 0.7, 11), Color(0.48, 0.16, 0.12), PI / 2.0)
	_make_parked_car(Vector3(8, 0.7, 11), Color(0.12, 0.27, 0.42), -PI / 2.0)
	_make_parked_car(Vector3(-34, 0.7, 12), Color(0.42, 0.42, 0.39), 0.0)
	_make_parked_car(Vector3(34, 0.7, 12), Color(0.16, 0.34, 0.24), PI)
	_make_pedestrian(Vector3(-8, 0, 5), Color(0.42, 0.18, 0.16))
	_make_pedestrian(Vector3(12, 0, 6), Color(0.18, 0.32, 0.42))
	_make_pedestrian(Vector3(-17, 0, -5), Color(0.46, 0.38, 0.20))
	_make_pedestrian(Vector3(18, 0, -8), Color(0.28, 0.25, 0.38))
	_make_pedestrian(Vector3(-36, 0, -18), Color(0.20, 0.37, 0.27))

func _make_parked_car(pos: Vector3, paint: Color, facing: float) -> void:
	var vehicle := Node3D.new()
	vehicle.position = pos
	vehicle.rotation.y = facing
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.8, 0.65, 3.6)
	body.mesh = body_mesh
	body.position.y = 0.0
	body.material_override = _material(paint)
	vehicle.add_child(body)
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.42, 0.72, 1.75)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 0.62, -0.1)
	cabin.material_override = _material(Color(0.07, 0.14, 0.19))
	vehicle.add_child(cabin)
	for x in [-0.92, 0.92]:
		for z in [-1.15, 1.15]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.31
			wheel_mesh.bottom_radius = 0.31
			wheel_mesh.height = 0.2
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x, -0.28, z)
			wheel.material_override = _material(Color(0.02, 0.025, 0.03))
			vehicle.add_child(wheel)
	add_child(vehicle)

func _make_pedestrian(pos: Vector3, clothing: Color) -> void:
	var person := Node3D.new()
	person.position = pos
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.27
	torso_mesh.height = 1.15
	torso.mesh = torso_mesh
	torso.position.y = 0.78
	torso.material_override = _material(clothing)
	person.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.38
	head.mesh = head_mesh
	head.position.y = 1.52
	head.material_override = _material(Color(0.66, 0.47, 0.35))
	person.add_child(head)
	add_child(person)

func _make_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.25
	trunk_mesh.height = 1.8
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0, 0.9, 0)
	trunk.material_override = _material(Color(0.24, 0.15, 0.09))
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.15
	crown_mesh.height = 2.1
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(0, 2.35, 0)
	crown.material_override = _material(Color(0.12, 0.29, 0.19))
	add_child(crown)

func _make_streetlight(pos: Vector3) -> void:
	_make_box("Streetlight pole", pos + Vector3(0, 3.0, 0), Vector3(0.12, 6.0, 0.12), Color(0.12, 0.14, 0.17), self)
	_make_box("Streetlight arm", pos + Vector3(0.55, 5.8, 0), Vector3(1.2, 0.1, 0.1), Color(0.12, 0.14, 0.17), self)
	_make_box("Streetlight lamp", pos + Vector3(1.05, 5.7, 0), Vector3(0.55, 0.16, 0.45), Color(0.95, 0.78, 0.45), self)

func _make_building(pos: Vector3, size: Vector3, color: Color) -> void:
	_make_static_box("City building", pos + Vector3(0, size.y / 2.0, 0), size, color)
	for floor_index in range(1, int(size.y / 2.5)):
		for side_index in [-1, 1]:
			var window_pos := pos + Vector3(side_index * (size.x / 2.0 + 0.02), floor_index * 2.5 + 1.2, -size.z / 2.0 - 0.03)
			_make_box("Window", window_pos, Vector3(0.9, 1.0, 0.08), Color(0.12, 0.29, 0.39), self)

func _make_box(label_text: String, pos: Vector3, size: Vector3, color: Color, parent: Node) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label_text
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = _material(color)
	parent.add_child(mesh_instance)
	return mesh_instance

func _make_static_box(label_text: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label_text
	body.position = pos
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	var visual := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.material_override = _material(color)
	body.add_child(visual)
	add_child(body)
	return body

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.0, 5)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)

	# Alex Carter — a simple low-poly character rather than a featureless capsule.
	player_visual = MeshInstance3D.new()
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.72, 0.82, 0.42)
	player_visual.mesh = torso_mesh
	player_visual.position.y = 0.88
	player_visual.material_override = _material(Color(0.12, 0.25, 0.48))
	player.add_child(player_visual)

	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.15
		leg_mesh.height = 0.78
		leg.mesh = leg_mesh
		leg.position = Vector3(side * 0.19, 0.34, 0)
		leg.material_override = _material(Color(0.075, 0.09, 0.13))
		player.add_child(leg)
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.12
		arm_mesh.height = 0.72
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.43, 0.91, 0)
		arm.rotation.z = side * -0.16
		arm.material_override = _material(Color(0.12, 0.25, 0.48))
		player.add_child(arm)
		var shoe := MeshInstance3D.new()
		var shoe_mesh := BoxMesh.new()
		shoe_mesh.size = Vector3(0.28, 0.13, 0.42)
		shoe.mesh = shoe_mesh
		shoe.position = Vector3(side * 0.19, 0.08, -0.07)
		shoe.material_override = _material(Color(0.025, 0.03, 0.04))
		player.add_child(shoe)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	head.mesh = head_mesh
	head.position = Vector3(0, 1.52, 0)
	head.material_override = _material(Color(0.72, 0.52, 0.39))
	player.add_child(head)
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.245
	hair_mesh.height = 0.22
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 1.68, 0.015)
	hair.material_override = _material(Color(0.08, 0.065, 0.055))
	player.add_child(hair)
	add_child(player)

func _build_car() -> void:
	car = CharacterBody3D.new()
	car.name = "First car — test drive"
	car.position = Vector3(5, 0.75, 1)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.1, 4.0)
	collision.shape = shape
	car.add_child(collision)

	var chassis := MeshInstance3D.new()
	var chassis_mesh := BoxMesh.new()
	chassis_mesh.size = Vector3(2.0, 0.75, 4.0)
	chassis.mesh = chassis_mesh
	chassis.position.y = 0.05
	chassis.material_override = _material(Color(0.12, 0.19, 0.28))
	car.add_child(chassis)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.55, 0.72, 1.85)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 0.65, -0.15)
	cabin.material_override = _material(Color(0.16, 0.34, 0.43))
	car.add_child(cabin)

	# Windshield, rear glass, bumpers and headlights give the starter car a readable silhouette.
	_make_box("Front windshield", Vector3(0, 1.02, -0.92), Vector3(1.38, 0.48, 0.07), Color(0.045, 0.10, 0.15, 0.92), car)
	_make_box("Rear windshield", Vector3(0, 1.02, 0.70), Vector3(1.38, 0.48, 0.07), Color(0.045, 0.10, 0.15, 0.92), car)
	_make_box("Front bumper", Vector3(0, -0.12, -2.02), Vector3(1.95, 0.22, 0.16), Color(0.055, 0.065, 0.075), car)
	_make_box("Rear bumper", Vector3(0, -0.12, 2.02), Vector3(1.95, 0.22, 0.16), Color(0.055, 0.065, 0.075), car)
	for x in [-0.68, 0.68]:
		_make_box("Headlight", Vector3(x, 0.18, -2.03), Vector3(0.42, 0.22, 0.07), Color(0.96, 0.88, 0.63), car)
		_make_box("Tail light", Vector3(x, 0.18, 2.03), Vector3(0.38, 0.22, 0.07), Color(0.68, 0.08, 0.055), car)
	for x in [-1.0, 1.0]:
		for z in [-1.25, 1.25]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.36
			wheel_mesh.bottom_radius = 0.36
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x, -0.28, z)
			wheel.material_override = _material(Color(0.025, 0.03, 0.035))
			car.add_child(wheel)
	add_child(car)

func _build_police_car() -> void:
	police_car = CharacterBody3D.new()
	police_car.name = "Westbridge Police Cruiser"
	police_car.position = Vector3(-42, 0.72, 15)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.2, 4.0)
	collision.shape = shape
	police_car.add_child(collision)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.0, 0.72, 4.0)
	body.mesh = body_mesh
	body.material_override = _material(Color(0.82, 0.84, 0.86))
	police_car.add_child(body)
	var hood := MeshInstance3D.new()
	var hood_mesh := BoxMesh.new()
	hood_mesh.size = Vector3(1.9, 0.12, 1.15)
	hood.mesh = hood_mesh
	hood.position = Vector3(0, 0.40, -1.28)
	hood.material_override = _material(Color(0.08, 0.12, 0.18))
	police_car.add_child(hood)
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(1.45, 0.55, 1.8)
	roof.mesh = roof_mesh
	roof.position.y = 0.62
	roof.material_override = _material(Color(0.12, 0.18, 0.25))
	police_car.add_child(roof)
	var lightbar := MeshInstance3D.new()
	var lightbar_mesh := BoxMesh.new()
	lightbar_mesh.size = Vector3(1.05, 0.18, 0.28)
	lightbar.mesh = lightbar_mesh
	lightbar.position = Vector3(0, 1.0, 0)
	lightbar.material_override = _material(Color(0.9, 0.08, 0.06))
	police_car.add_child(lightbar)
	police_car.visible = false
	add_child(police_car)

func _update_police(delta: float) -> void:
	if not police_active or not is_instance_valid(police_car):
		return
	wanted_timer -= delta
	police_flash_timer += delta
	if police_flash_timer >= 0.35:
		police_flash_timer = 0.0
		var bar := police_car.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if bar:
			bar.material_override = _material(Color(0.12, 0.28, 0.95) if int(Time.get_ticks_msec() / 350) % 2 == 0 else Color(0.95, 0.08, 0.06))
	var target: Node3D = car if in_car else player
	var chase := target.global_position - police_car.global_position
	chase.y = 0.0
	var distance := chase.length()
	if distance > 2.8:
		var direction := chase.normalized()
		police_car.rotation.y = atan2(-direction.x, -direction.z)
		police_car.velocity.x = direction.x * 12.5
		police_car.velocity.z = direction.z * 12.5
		police_car.velocity.y = 0.0
		police_car.move_and_slide()
	else:
		police_active = false
		police_car.visible = false
		cash = maxi(0, cash - 500)
		in_car = false
		player.visible = true
		player.global_position = Vector3(0, 1.0, 5)
		car.global_position = Vector3(5, 0.75, 1)
		_show_message("BUSTED. The police impounded your run and fined you $500. The package is safe — get back to the dealership.")
		_update_hud()
		_save_game()
		return
	if wanted_timer <= 0.0:
		police_active = false
		police_car.visible = false
		_show_message("You lost the police. Get the package back to Westbridge Motors.")
		_update_hud()

func _build_story_characters() -> void:
	marcus = Node3D.new()
	marcus.name = "Marcus Vale"
	marcus.position = Vector3(28, 0, -30)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.42
	body_mesh.height = 1.85
	body.mesh = body_mesh
	body.position.y = 0.92
	body.material_override = _material(Color(0.18, 0.20, 0.23))
	marcus.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	head.mesh = head_mesh
	head.position.y = 1.95
	head.material_override = _material(Color(0.68, 0.48, 0.36))
	marcus.add_child(head)
	var name_tag := Label3D.new()
	name_tag.text = "MARCUS VALE"
	name_tag.font_size = 32
	name_tag.position.y = 2.65
	name_tag.pixel_size = 0.012
	name_tag.modulate = Color(1.0, 0.82, 0.48)
	marcus.add_child(name_tag)
	add_child(marcus)

	package_crate = Node3D.new()
	package_crate.name = "Sealed package"
	package_crate.position = Vector3(-30, 0, -25)
	var crate := MeshInstance3D.new()
	var crate_mesh := BoxMesh.new()
	crate_mesh.size = Vector3(1.5, 1.1, 1.5)
	crate.mesh = crate_mesh
	crate.position.y = 0.55
	crate.material_override = _material(Color(0.43, 0.29, 0.16))
	package_crate.add_child(crate)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(1.52, 0.12, 1.52)
	stripe.mesh = stripe_mesh
	stripe.position.y = 0.62
	stripe.material_override = _material(Color(0.83, 0.65, 0.31))
	package_crate.add_child(stripe)
	package_crate.visible = false
	add_child(package_crate)

func _build_mission_marker() -> void:
	mission_marker = Node3D.new()
	mission_marker.name = "MissionWaypoint"
	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.08
	beam_mesh.bottom_radius = 0.55
	beam_mesh.height = 2.4
	beam.mesh = beam_mesh
	beam.position.y = 1.2
	beam.material_override = _material(Color(1.0, 0.72, 0.18, 0.48))
	mission_marker.add_child(beam)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.65
	ring_mesh.outer_radius = 0.82
	ring.mesh = ring_mesh
	ring.position.y = 0.12
	ring.material_override = _material(Color(1.0, 0.78, 0.24))
	mission_marker.add_child(ring)
	add_child(mission_marker)
	_update_mission_marker()

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.current = true
	camera.fov = 72
	add_child(camera)
	camera.global_position = Vector3(0, 5, 13)
	camera.look_at(player.global_position)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	hud = Label.new()
	hud.position = Vector2(24, 18)
	hud.add_theme_font_size_override("font_size", 25)
	hud.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(hud)

	objective = Label.new()
	objective.position = Vector2(24, 58)
	objective.size = Vector2(700, 58)
	objective.add_theme_font_size_override("font_size", 18)
	objective.add_theme_color_override("font_color", Color(1.0, 0.84, 0.55))
	root.add_child(objective)

	message = Label.new()
	message.position = Vector2(24, 122)
	message.size = Vector2(720, 70)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 17)
	message.add_theme_color_override("font_color", Color(0.91, 0.94, 1.0))
	root.add_child(message)

	_add_touch_button(root, "▲", "forward", Vector2(88, -190), false)
	_add_touch_button(root, "◀", "left", Vector2(24, -126), false)
	_add_touch_button(root, "▼", "back", Vector2(88, -126), false)
	_add_touch_button(root, "▶", "right", Vector2(152, -126), false)
	_add_touch_button(root, "INTERACT", "interact", Vector2(-164, -132), true)
	_add_touch_button(root, "RUN", "run", Vector2(-164, -64), true)

func _add_touch_button(root: Control, caption: String, action: String, pos: Vector2, right_side: bool) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(62, 58) if not right_side else Vector2(132, 58)
	button.size = button.custom_minimum_size
	if right_side:
		button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	else:
		button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	button.position = pos
	button.add_theme_font_size_override("font_size", 17 if right_side else 24)
	button.modulate = Color(1, 1, 1, 0.88)
	root.add_child(button)
	if action == "interact":
		button.button_down.connect(_interact)
	else:
		button.button_down.connect(func(): held[action] = true)
		button.button_up.connect(func(): held[action] = false)

func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message.text = ""
	if is_instance_valid(mission_marker):
		mission_marker.rotation.y += delta * 0.9
		mission_marker.position.y = 0.12 + sin(Time.get_ticks_msec() * 0.002) * 0.12
	day_clock = fmod(day_clock + delta * 0.004, 24.0)
	if is_instance_valid(sun_light):
		var daylight := clampf(sin((day_clock - 6.0) / 12.0 * PI), 0.12, 1.0)
		sun_light.light_energy = 0.18 + daylight * 1.15
		sun_light.rotation_degrees.x = -((day_clock - 6.0) / 12.0 * 180.0)
	save_timer += delta
	if save_timer >= 30.0:
		save_timer = 0.0
		_save_game()
	_follow_camera(delta)

func _physics_process(delta: float) -> void:
	if in_car:
		_drive_car(delta)
	else:
		_move_player(delta)
	_update_police(delta)
	if Input.is_action_just_pressed("ui_accept"):
		_interact()

func _move_player(delta: float) -> void:
	var x := float(held.get("right", false)) - float(held.get("left", false))
	var z := float(held.get("back", false)) - float(held.get("forward", false))
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		z += 1.0
	# Move relative to the fixed third-person camera, not world axes.
	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var direction := (camera_right * x + camera_forward * -z).normalized()
	if direction.length() > 0.05:
		player.rotation.y = atan2(direction.x, direction.z)
	var movement_speed: float = WALK_SPEED * (1.8 if held.get("run", false) else 1.0)
	player.velocity.x = direction.x * movement_speed
	player.velocity.z = direction.z * movement_speed
	if not player.is_on_floor():
		player.velocity.y -= 22.0 * delta
	else:
		player.velocity.y = -0.1
	player.move_and_slide()

func _drive_car(delta: float) -> void:
	var throttle := float(held.get("forward", false)) - float(held.get("back", false))
	var steering := float(held.get("right", false)) - float(held.get("left", false))
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steering -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steering += 1.0
	var speed_factor: float = clampf(absf(throttle), 0.0, 1.0)
	car.rotation.y -= steering * TURN_SPEED * delta * max(speed_factor, 0.25) * sign(throttle if throttle != 0.0 else 1.0)
	var forward_dir := -car.global_transform.basis.z
	car.velocity.x = forward_dir.x * throttle * CAR_SPEED
	car.velocity.z = forward_dir.z * throttle * CAR_SPEED
	car.velocity.y = 0.0
	car.move_and_slide()

func _follow_camera(delta: float) -> void:
	var target: Node3D = car if in_car else player
	var distance := 9.0 if in_car else 7.0
	var height := 4.0 if in_car else 3.4
	# Keep the third-person camera behind the player without orbiting when
	# the player turns. This prevents the arrow buttons from spinning the view.
	var desired := target.global_position + Vector3(0, height, distance)
	camera.global_position = camera.global_position.lerp(desired, clamp(delta * 5.0, 0.0, 1.0))
	camera.look_at(target.global_position + Vector3(0, 1.1, 0))

func _interact() -> void:
	if in_car:
		in_car = false
		player.global_position = car.global_position + car.global_transform.basis.x * 2.2 + Vector3(0, 0.2, 0)
		player.visible = true
		_show_message("You stepped out. Westbridge is yours to explore.")
		_update_hud()
		return

	var player_pos := player.global_position
	if player_pos.distance_to(car.global_position) < 4.5 and mission_stage >= 1:
		in_car = true
		player.visible = false
		_show_message("TEST DRIVE — ▲ accelerate, ▼ brake/reverse, ◀ ▶ steer. Hold RUN for a faster drive.")
		_update_hud()
		return

	var desk_pos := Vector3(0, 0, -1.2)
	if player_pos.distance_to(desk_pos) < 4.5:
		if mission_stage == 0:
			mission_stage = 1
			first_deal_done = true
			_show_message("The folder contains an old ledger and a note: 'Ask Marcus what happened to your father.' His last known location is the old freight yard.")
		elif mission_stage == 3:
			mission_stage = 4
			cash += 2500
			sales_completed += 1
			_show_message("CHAPTER 1 COMPLETE. You returned with the ledger. The numbers reveal your father was paying someone to keep the dealership alive. +$2,500.")
		elif mission_stage >= 4:
			if not stock_owned and cash >= 1200:
				cash -= 1200
				stock_owned = true
				_show_message("You bought a trade-in for $1,200. Clean it up and list it — interact with the desk again to close the sale.")
			elif stock_owned:
				cash += 1950
				stock_owned = false
				sales_completed += 1
				_show_message("SALE CLOSED: the car sold for $1,950. Your dealership made $750 profit.")
			else:
				_show_message("You need $1,200 to buy your next trade-in. Take a drive and come back.")
		else:
			_show_message("The reception desk is quiet. Your next lead is marked on the map.")
		_update_mission_marker()
		_update_hud()
		_save_game()
		return

	if mission_stage == 1 and is_instance_valid(marcus) and player_pos.distance_to(marcus.global_position) < 3.5:
		mission_stage = 2
		package_crate.visible = true
		marcus.visible = false
		_show_message("MARCUS: 'Your father didn't disappear. He found something in the freight records.' He gives you a warehouse key. Retrieve the sealed package before the yard crew arrives.")
		_update_mission_marker()
		_update_hud()
		_save_game()
		return

	if mission_stage == 2 and is_instance_valid(package_crate) and player_pos.distance_to(package_crate.global_position) < 3.5:
		mission_stage = 3
		package_crate.visible = false
		cash += 750
		police_active = true
		wanted_timer = 55.0
		police_car.visible = true
		police_car.global_position = Vector3(-42, 0.72, 15)
		_show_message("PACKAGE SECURED. +$750. A yard lookout spotted you — POLICE INBOUND. Lose them and get back to Westbridge Motors!")
		_update_mission_marker()
		_update_hud()
		_save_game()
		return

	if player_pos.distance_to(car.global_position) < 4.5:
		_show_message("The keys are on the reception desk. Find the folder first.")
	elif mission_stage == 1 and is_instance_valid(marcus):
		_show_message("Find Marcus at the old freight yard. Follow the gold waypoint.")
	elif mission_stage == 2 and is_instance_valid(package_crate):
		_show_message("The sealed package is inside the warehouse yard. Follow the gold waypoint.")
	else:
		_show_message("No interaction nearby. Follow the gold waypoint or explore Westbridge.")

func _show_message(text_value: String) -> void:
	message.text = text_value
	message_timer = 9.0

func _update_mission_marker() -> void:
	if not is_instance_valid(mission_marker):
		return
	match mission_stage:
		0, 3:
			mission_marker.global_position = Vector3(0, 0.12, -1.2)
		1:
			mission_marker.global_position = Vector3(28, 0.12, -30)
		2:
			mission_marker.global_position = Vector3(-30, 0.12, -25)
		_:
			mission_marker.visible = false
			return
	mission_marker.visible = true

func _save_game() -> void:
	var data := ConfigFile.new()
	data.set_value("career", "mission_stage", mission_stage)
	data.set_value("career", "cash", cash)
	data.set_value("career", "sales_completed", sales_completed)
	data.set_value("career", "stock_owned", stock_owned)
	data.save("user://underworld_save.cfg")

func _load_game() -> void:
	var data := ConfigFile.new()
	if data.load("user://underworld_save.cfg") == OK:
		mission_stage = int(data.get_value("career", "mission_stage", 0))
		cash = int(data.get_value("career", "cash", 2450))
		sales_completed = int(data.get_value("career", "sales_completed", 0))
		stock_owned = bool(data.get_value("career", "stock_owned", false))
	first_deal_done = mission_stage >= 1
	if mission_stage >= 2 and is_instance_valid(marcus):
		marcus.visible = false
	if mission_stage >= 3 and is_instance_valid(package_crate):
		package_crate.visible = false
	_update_mission_marker()

func _update_hud() -> void:
	hud.text = "WESTBRIDGE MOTORS     $%s     |     SALES %s" % [str(cash), str(sales_completed)]
	match mission_stage:
		0:
			objective.text = "MISSION 01  |  Find the folder on the reception desk."
		1:
			objective.text = "MISSION 01  |  Meet Marcus Vale at the old freight yard."
		2:
			objective.text = "MISSION 01  |  Retrieve the sealed package from the warehouse."
		3:
			objective.text = "MISSION 01  |  Return to Westbridge Motors with the package."
		_:
			objective.text = "WESTBRIDGE MOTORS  |  Buy trade-ins for $1,200 and sell for $1,950. Build your business."
	if police_active:
		objective.text += "     |     HEAT: 1"
