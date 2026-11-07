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
var story_message := "WESTBRIDGE, 8:12 AM — Your father's old dealership is finally yours."
var message_timer := 7.0

func _ready() -> void:
	_build_world()
	_build_player()
	_build_car()
	_build_camera()
	_build_ui()
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

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

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
	_make_box("Garage floor", Vector3(7, 0.04, -1), Vector3(12, 0.12, 9), Color(0.13, 0.15, 0.18), self)

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

	player_visual = MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.38
	body_mesh.height = 1.8
	player_visual.mesh = body_mesh
	player_visual.material_override = _material(Color(0.16, 0.30, 0.58))
	player.add_child(player_visual)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	head.mesh = head_mesh
	head.position = Vector3(0, 0.88, 0)
	head.material_override = _material(Color(0.72, 0.52, 0.39))
	player.add_child(head)
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
	_follow_camera(delta)

func _physics_process(delta: float) -> void:
	if in_car:
		_drive_car(delta)
	else:
		_move_player(delta)
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
	var direction := Vector3(x, 0, z).normalized()
	if direction.length() > 0.05:
		player.rotation.y = atan2(direction.x, direction.z)
	var movement_speed: float = WALK_SPEED * (1.65 if held.get("run", false) else 1.0)
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
	var desired := target.global_position + target.global_transform.basis.z * distance + Vector3(0, height, 0)
	camera.global_position = camera.global_position.lerp(desired, clamp(delta * 5.0, 0.0, 1.0))
	camera.look_at(target.global_position + Vector3(0, 1.1, 0))

func _interact() -> void:
	if in_car:
		in_car = false
		player.global_position = car.global_position + car.global_transform.basis.x * 2.2 + Vector3(0, 0.2, 0)
		player.visible = true
		_show_message("You stepped out of the car. The city is waiting.")
		_update_hud()
		return

	var player_pos := player.global_position
	if player_pos.distance_to(car.global_position) < 4.0 and first_deal_done:
		in_car = true
		player.visible = false
		_show_message("TEST DRIVE STARTED — Use the arrows to steer. ▲ accelerates, ▼ reverses.")
		_update_hud()
		return

	var desk_pos := Vector3(0, 0, -1.2)
	if not first_deal_done and player_pos.distance_to(desk_pos) < 5.0:
		first_deal_done = true
		_show_message("A folder is waiting on the desk. One name is circled: MARCUS VALE. Your father's old business partner. Why is his number here?")
		_update_hud()
	elif player_pos.distance_to(car.global_position) < 4.0:
		_show_message("The car is ready, but check the dealership desk first.")
	else:
		_show_message("Nothing to interact with here. Explore the showroom.")

func _show_message(text_value: String) -> void:
	message.text = text_value
	message_timer = 9.0

func _update_hud() -> void:
	hud.text = "WESTBRIDGE MOTORS     $2,450"
	if not first_deal_done:
		objective.text = "MISSION 01  |  Find the folder on the reception desk."
	else:
		objective.text = "MISSION 01 COMPLETE  |  Get into your first car and take a test drive."
