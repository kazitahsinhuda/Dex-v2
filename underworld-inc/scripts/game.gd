extends Node3D

const WALK_SPEED := 5.0
const CAR_SPEED := 9.5
const REVERSE_SPEED := 4.2
const TURN_SPEED := 2.0

var player: CharacterBody3D
var player_visual: MeshInstance3D
var player_legs: Array[MeshInstance3D] = []
var player_arms: Array[MeshInstance3D] = []
var walk_time := 0.0
var car: CharacterBody3D
var active_car: CharacterBody3D
var parked_cars: Array[CharacterBody3D] = []
var generated_material_cache: Dictionary = {}
var inheritance_letter: Node3D
var camera: Camera3D
var hud: Label
var objective: Label
var message: Label
var minimap_player: ColorRect
var minimap_target: ColorRect
var minimap_alt_target: ColorRect
var minimap_panel: ColorRect
var held: Dictionary = {}
var in_car := false
var first_deal_done := false
var mission_stage := 0
var cash := 2450
var sales_completed := 0
var stock_owned := false
var stock_repaired := false
var repair_bay_position := Vector3(10, 0, -2)
var marcus: Node3D
var package_crate: Node3D
var lena: Node3D
var detective: Node3D
var prologue_manager: Node3D
var evidence_case: Node3D
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
var intro_active := false
var intro_index := 0
var touch_points: Dictionary = {}
var touch_last: Dictionary = {}
var camera_yaw := 0.0
var camera_pitch := 0.0
var intro_lines: Array[String] = [
	"Alex Carter. 7:40 AM. Another shift, another empty promise.",
	"MANAGER: You're fired, Alex. The company is cutting staff. Clear your locker.",
	"Three weeks later. The rent is overdue, the landlord is calling, and your savings are almost gone.",
	"A solicitor's voicemail is the only lead: your missing father left an old dealership in Westbridge. The paperwork is still there.",
	"With nowhere else to go, Alex packs what he can and takes the first bus out of town.",
	"By noon, he is standing outside Westbridge Motors — an abandoned dealership with unpaid bills and a locked office.",
	"Alex has no plan beyond opening the doors, selling a car, and keeping a roof over his head."
]

func _ready() -> void:
	_build_world()
	_build_player()
	_build_car()
	active_car = car
	_build_police_car()
	_build_story_characters()
	_build_prologue_stage()
	_build_camera()
	_build_ui()
	_build_mission_marker()
	_load_game()
	_update_hud()
	if mission_stage == 0:
		_start_intro()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.69, 0.82)
	env.ambient_light_energy = 0.82
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.60, 0.68, 0.76)
	env.fog_density = 0.0018
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
	# Raised pavements, curbs and painted lane guides give the district a real street profile.
	_make_static_box("Sidewalk", Vector3(0, 0.07, 8.35), Vector3(100, 0.14, 2.7), Color(0.36, 0.37, 0.36))
	_make_static_box("Sidewalk", Vector3(0, 0.07, 21.65), Vector3(100, 0.14, 2.7), Color(0.36, 0.37, 0.36))
	_make_static_box("Sidewalk", Vector3(-31.35, 0.07, -2), Vector3(2.7, 0.14, 80), Color(0.36, 0.37, 0.36))
	_make_static_box("Sidewalk", Vector3(-16.65, 0.07, -2), Vector3(2.7, 0.14, 80), Color(0.36, 0.37, 0.36))
	for x in range(-45, 50, 10):
		_make_box("Road marking", Vector3(x, 0.08, 15), Vector3(4.0, 0.028, 0.18), Color(0.95, 0.88, 0.64), self)
	for z in range(-38, 38, 9):
		_make_box("Road marking", Vector3(-24, 0.08, z), Vector3(0.18, 0.028, 4.0), Color(0.92, 0.91, 0.84), self)
	_build_street_detail()

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
	var vehicle := CharacterBody3D.new()
	vehicle.name = "Parked vehicle"
	vehicle.position = pos
	var collision := CollisionShape3D.new()
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(2.0, 1.15, 3.9)
	collision.shape = collision_shape
	vehicle.add_child(collision)
	vehicle.rotation.y = facing
	_build_car_visual(vehicle, paint)
	add_child(vehicle)
	parked_cars.append(vehicle)

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
	var floors := maxi(1, int(size.y / 2.6))
	var columns := maxi(2, int(size.x / 2.6))
	var front_z := pos.z - size.z / 2.0 - 0.055
	for floor_index in range(floors):
		var floor_y := float(floor_index) * 2.55 + 1.35
		for column_index in range(columns):
			var x_pos := pos.x - size.x * 0.5 + (float(column_index) + 0.5) * size.x / float(columns)
			var window_width := size.x / float(columns) * 0.62
			var window_height := 1.25 if floor_index > 0 else 1.05
			var glass := _make_box("Facade glass", Vector3(x_pos, floor_y, front_z), Vector3(window_width, window_height, 0.075), Color(0.075, 0.18, 0.25), self)
			glass.material_override = _material(Color(0.055, 0.14, 0.20))
			var frame_color := Color(0.18, 0.20, 0.22)
			_make_box("Facade frame", Vector3(x_pos - window_width * 0.5, floor_y, front_z - 0.045), Vector3(0.07, window_height + 0.12, 0.045), frame_color, self)
			_make_box("Facade frame", Vector3(x_pos + window_width * 0.5, floor_y, front_z - 0.045), Vector3(0.07, window_height + 0.12, 0.045), frame_color, self)
			_make_box("Window sill", Vector3(x_pos, floor_y - window_height * 0.5 - 0.07, front_z - 0.07), Vector3(window_width + 0.12, 0.10, 0.14), color.darkened(0.22), self)
		_make_box("Floor ledge", Vector3(pos.x, floor_y + 1.23, front_z - 0.10), Vector3(size.x + 0.25, 0.13, 0.24), color.lightened(0.12), self)
	# Ground-floor entrance and a sign band make buildings read as places, not blank blocks.
	_make_box("Shop entrance", Vector3(pos.x, 1.05, front_z - 0.08), Vector3(1.35, 2.1, 0.10), Color(0.025, 0.055, 0.075), self)
	_make_box("Shop sign", Vector3(pos.x, 2.45, front_z - 0.10), Vector3(minf(size.x * 0.72, 7.0), 0.38, 0.16), color.lightened(0.24), self)
	# Side-facing windows prevent the city from looking like a row of untextured cubes.
	for floor_index in range(1, floors):
		var side_y := float(floor_index) * 2.55 + 1.35
		for side_index in [-1.0, 1.0]:
			var side_x := pos.x + side_index * (size.x * 0.5 + 0.045)
			_make_box("Window", Vector3(side_x, side_y, pos.z), Vector3(0.08, 1.05, 1.0), Color(0.08, 0.20, 0.28), self)

func _build_street_detail() -> void:
	# Repeating kerb stones and sidewalk joints add scale cues around the main block.
	for x in range(-48, 49, 3):
		_make_box("Kerb stone", Vector3(x, 0.17, 6.95), Vector3(2.85, 0.20, 0.24), Color(0.47, 0.48, 0.46), self)
		_make_box("Kerb stone", Vector3(x, 0.17, 23.05), Vector3(2.85, 0.20, 0.24), Color(0.47, 0.48, 0.46), self)
	for x in range(-48, 49, 4):
		_make_box("Pavement joint", Vector3(x, 0.145, 8.4), Vector3(0.035, 0.006, 2.6), Color(0.23, 0.24, 0.24), self)
		_make_box("Pavement joint", Vector3(x, 0.145, 21.6), Vector3(0.035, 0.006, 2.6), Color(0.23, 0.24, 0.24), self)
	# Small road repairs and drain covers break up the uniform asphalt plane.
	for patch_pos in [Vector3(-18, 0.071, 12.2), Vector3(26, 0.071, 17.4), Vector3(-39, 0.071, 16.8), Vector3(41, 0.071, 12.8)]:
		var patch := _make_box("Asphalt patch", patch_pos, Vector3(2.8, 0.012, 1.25), Color(0.055, 0.061, 0.068), self)
		patch.rotation.y = 0.08
	for drain_pos in [Vector3(-12, 0.085, 8.8), Vector3(18, 0.085, 21.2), Vector3(-29.5, 0.085, -12)]:
		_make_box("Drain cover", drain_pos, Vector3(0.72, 0.018, 0.42), Color(0.16, 0.18, 0.19), self)

func _make_box(label_text: String, pos: Vector3, size: Vector3, color: Color, parent: Node) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label_text
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = _world_material(label_text, color)
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
	visual.material_override = _world_material(label_text, color)
	body.add_child(visual)
	add_child(body)
	return body

func _world_material(label_text: String, color: Color) -> StandardMaterial3D:
	match label_text:
		"Ground":
			return _textured_material(color, "grass", 0.055, 7.0)
		"Main road", "Cross road":
			return _textured_material(color, "asphalt", 0.11, 3.0)
		"City building", "Showroom body":
			return _textured_material(color, "concrete", 0.075, 3.0)
		"Garage floor", "Sidewalk":
			return _textured_material(color, "garage_concrete", 0.09, 4.0)
		"Road marking":
			return _textured_material(color, "road_paint", 0.12, 2.0)
		"Showroom roof":
			return _textured_material(color, "roof_metal", 0.14, 2.0)
		"Reception desk", "Office desk":
			return _textured_material(color, "wood", 0.12, 2.0)
		"Office floor", "Apartment floor":
			return _textured_material(color, "worn_floorboards", 0.075, 2.5)
		"Bus stop platform":
			return _textured_material(color, "pavement", 0.10, 3.0)
		"Office back wall", "Office side wall", "Apartment back wall":
			return _textured_material(color, "painted_plaster", 0.045, 2.0)
		_:
			return _material(color)

func _paint_material(color: Color) -> StandardMaterial3D:
	var mat := _material(color)
	mat.metallic = 0.48
	mat.roughness = 0.28
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.65
	return mat

func _textured_material(color: Color, style: String, frequency: float, uv_scale: float) -> StandardMaterial3D:
	# Reuse generated materials to keep procedural surface memory under control on Android.
	var cache_key := "%s|%s|%.4f|%.2f" % [style, color.to_html(true), frequency, uv_scale]
	if generated_material_cache.has(cache_key):
		return generated_material_cache[cache_key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	var noise := FastNoiseLite.new()
	noise.seed = abs(hash(style))
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.1
	noise.fractal_gain = 0.48
	# Use imported, hand-authored tiling texture assets in the APK. Procedural noise is
	# retained only as a safe fallback if an asset fails to import.
	var texture_asset := style
	match style:
		"garage_concrete", "pavement":
			texture_asset = "concrete"
		"roof_metal":
			texture_asset = "metal"
		"worn_floorboards":
			texture_asset = "wood"
		"road_paint":
			texture_asset = "asphalt"
	var imported_texture := load("res://underworld-inc/assets/textures/%s.svg" % texture_asset) as Texture2D
	if imported_texture != null:
		mat.albedo_texture = imported_texture
	else:
		var texture := NoiseTexture2D.new()
		texture.noise = noise
		texture.width = 1024
		texture.height = 1024
		texture.seamless = true
		mat.albedo_texture = texture

	# Fine surface relief: asphalt grain, concrete pores and wood grain catch light.
	var normal_image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for py in range(256):
		for px in range(256):
			var nx := noise.get_noise_2d(float(px + 1), float(py)) - noise.get_noise_2d(float(px - 1), float(py))
			var ny := noise.get_noise_2d(float(px), float(py + 1)) - noise.get_noise_2d(float(px), float(py - 1))
			var normal := Vector3(-nx * 3.2, -ny * 3.2, 1.0).normalized()
			normal_image.set_pixel(px, py, Color(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5, 1.0))
	mat.normal_enabled = true
	mat.normal_texture = ImageTexture.create_from_image(normal_image)
	mat.normal_scale = 0.52
	generated_material_cache[cache_key] = mat
	return mat

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
	player.position = Vector3(0, 0.0, 5)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)

	# Alex Carter: a layered streetwear character with a rounded silhouette.
	var hoodie := _textured_material(Color(0.055, 0.075, 0.105), "fabric", 0.085, 2.4)
	var denim := _textured_material(Color(0.055, 0.075, 0.11), "denim", 0.12, 2.8)
	var skin := _material(Color(0.67, 0.46, 0.34))
	var hair_mat := _material(Color(0.035, 0.028, 0.025))

	player_visual = MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.34
	torso_mesh.height = 1.08
	player_visual.mesh = torso_mesh
	player_visual.position.y = 1.06
	player_visual.material_override = hoodie
	player.add_child(player_visual)

	# Hood volume and collar sit behind the neck instead of a square shoulder block.
	var hood := MeshInstance3D.new()
	var hood_mesh := SphereMesh.new()
	hood_mesh.radius = 0.34
	hood_mesh.height = 0.55
	hood.mesh = hood_mesh
	hood.scale = Vector3(0.92, 1.0, 0.72)
	hood.position = Vector3(0, 1.43, 0.19)
	hood.material_override = hoodie
	player.add_child(hood)
	var collar := MeshInstance3D.new()
	var collar_mesh := TorusMesh.new()
	collar_mesh.inner_radius = 0.17
	collar_mesh.outer_radius = 0.23
	collar.mesh = collar_mesh
	collar.position.y = 1.51
	collar.rotation_degrees.x = 90
	collar.material_override = _material(Color(0.025, 0.035, 0.05))
	player.add_child(collar)

	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.16
		leg_mesh.height = 0.86
		leg.mesh = leg_mesh
		leg.position = Vector3(side * 0.19, 0.47, 0.015)
		leg.material_override = denim
		player.add_child(leg)
		player_legs.append(leg)

		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.145
		arm_mesh.height = 0.78
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.43, 1.08, 0.015)
		arm.rotation.z = side * -0.12
		arm.material_override = hoodie
		player.add_child(arm)
		player_arms.append(arm)

		var shoe := MeshInstance3D.new()
		var shoe_mesh := CapsuleMesh.new()
		shoe_mesh.radius = 0.13
		shoe_mesh.height = 0.43
		shoe.mesh = shoe_mesh
		shoe.scale = Vector3(1.0, 0.52, 1.35)
		shoe.position = Vector3(side * 0.19, 0.12, -0.10)
		shoe.material_override = _material(Color(0.025, 0.028, 0.035))
		player.add_child(shoe)

		# Small stitched pocket panels break up the flat trouser silhouette.
		var pocket := MeshInstance3D.new()
		var pocket_mesh := SphereMesh.new()
		pocket_mesh.radius = 0.10
		pocket.mesh = pocket_mesh
		pocket.scale = Vector3(0.72, 0.9, 0.10)
		pocket.position = Vector3(side * 0.19, 0.63, -0.145)
		pocket.material_override = _material(Color(0.075, 0.095, 0.13))
		player.add_child(pocket)

	var neck := MeshInstance3D.new()
	var neck_mesh := CapsuleMesh.new()
	neck_mesh.radius = 0.13
	neck_mesh.height = 0.27
	neck.mesh = neck_mesh
	neck.position.y = 1.55
	neck.material_override = skin
	player.add_child(neck)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.235
	head_mesh.height = 0.48
	head.mesh = head_mesh
	head.position = Vector3(0, 1.78, -0.015)
	head.material_override = skin
	player.add_child(head)

	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.245
	hair_mesh.height = 0.27
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 1.94, 0.025)
	hair.material_override = hair_mat
	player.add_child(hair)

	# Face details face forward (-Z), so the character reads clearly from behind-camera view.
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.027
		eye.mesh = eye_mesh
		eye.position = Vector3(side * 0.082, 1.79, -0.226)
		eye.material_override = _material(Color(0.035, 0.025, 0.02))
		player.add_child(eye)
		var brow := MeshInstance3D.new()
		var brow_mesh := CapsuleMesh.new()
		brow_mesh.radius = 0.018
		brow_mesh.height = 0.10
		brow.mesh = brow_mesh
		brow.position = Vector3(side * 0.082, 1.84, -0.225)
		brow.rotation_degrees.z = 90
		brow.material_override = hair_mat
		player.add_child(brow)

	var nose := MeshInstance3D.new()
	var nose_mesh := SphereMesh.new()
	nose_mesh.radius = 0.045
	nose.mesh = nose_mesh
	nose.scale = Vector3(0.75, 0.85, 0.75)
	nose.position = Vector3(0, 1.73, -0.245)
	nose.material_override = skin
	player.add_child(nose)

	# Hoodie drawstrings and front pocket are subtle but visible at gameplay distance.
	for side in [-1.0, 1.0]:
		var string := MeshInstance3D.new()
		var string_mesh := CylinderMesh.new()
		string_mesh.top_radius = 0.012
		string_mesh.bottom_radius = 0.012
		string_mesh.height = 0.24
		string.mesh = string_mesh
		string.position = Vector3(side * 0.075, 1.27, -0.315)
		string.material_override = _material(Color(0.72, 0.72, 0.68))
		player.add_child(string)
	var front_pocket := MeshInstance3D.new()
	var front_pocket_mesh := SphereMesh.new()
	front_pocket_mesh.radius = 0.17
	front_pocket.mesh = front_pocket_mesh
	front_pocket.scale = Vector3(1.55, 0.38, 0.20)
	front_pocket.position = Vector3(0, 0.82, -0.31)
	front_pocket.material_override = _material(Color(0.045, 0.062, 0.09))
	player.add_child(front_pocket)

	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.15
		leg_mesh.height = 0.78
		leg.mesh = leg_mesh
		leg.position = Vector3(side * 0.19, 0.34, 0)
		leg.material_override = _material(Color(0.075, 0.09, 0.13))
		player.add_child(leg)
		player_legs.append(leg)
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.12
		arm_mesh.height = 0.72
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.43, 0.91, 0)
		arm.rotation.z = side * -0.16
		arm.material_override = _material(Color(0.12, 0.25, 0.48))
		player.add_child(arm)
		player_arms.append(arm)
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

	_build_car_visual(car, Color(0.12, 0.19, 0.28))
	add_child(car)

func _build_car_visual(vehicle: CharacterBody3D, paint: Color) -> void:
	# Rounded ellipsoid body panels replace the old rectangular toy-car silhouette.
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 1.0
	body_mesh.height = 2.0
	body.mesh = body_mesh
	body.scale = Vector3(0.98, 0.34, 1.92)
	body.position.y = 0.02
	body.material_override = _paint_material(paint)
	vehicle.add_child(body)

	var hood := MeshInstance3D.new()
	var hood_mesh := SphereMesh.new()
	hood_mesh.radius = 1.0
	hood_mesh.height = 2.0
	hood.mesh = hood_mesh
	hood.scale = Vector3(0.91, 0.22, 0.72)
	hood.position = Vector3(0, 0.17, -1.18)
	hood.material_override = _paint_material(paint.lightened(0.035))
	vehicle.add_child(hood)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := SphereMesh.new()
	trunk_mesh.radius = 1.0
	trunk_mesh.height = 2.0
	trunk.mesh = trunk_mesh
	trunk.scale = Vector3(0.88, 0.20, 0.48)
	trunk.position = Vector3(0, 0.17, 1.36)
	trunk.material_override = _paint_material(paint.darkened(0.025))
	vehicle.add_child(trunk)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := SphereMesh.new()
	cabin_mesh.radius = 1.0
	cabin_mesh.height = 2.0
	cabin.mesh = cabin_mesh
	cabin.scale = Vector3(0.70, 0.43, 0.91)
	cabin.position = Vector3(0, 0.57, -0.08)
	cabin.material_override = _material(Color(0.035, 0.075, 0.105))
	vehicle.add_child(cabin)

	# Curved front/rear windscreens and side windows give the cabin a glass canopy.
	for z_pos in [-0.77, 0.64]:
		var windshield := MeshInstance3D.new()
		var windshield_mesh := SphereMesh.new()
		windshield_mesh.radius = 1.0
		windshield_mesh.height = 2.0
		windshield.mesh = windshield_mesh
		windshield.scale = Vector3(0.54, 0.27, 0.055)
		windshield.position = Vector3(0, 0.76, z_pos)
		windshield.material_override = _material(Color(0.12, 0.25, 0.31, 0.86))
		vehicle.add_child(windshield)

	# Side windows, mirrors, wheels, bumpers and lamps.
	for side in [-1.0, 1.0]:
		var window := MeshInstance3D.new()
		var window_mesh := SphereMesh.new()
		window_mesh.radius = 1.0
		window_mesh.height = 2.0
		window.mesh = window_mesh
		window.scale = Vector3(0.035, 0.28, 0.66)
		window.position = Vector3(side * 0.685, 0.62, -0.10)
		window.material_override = _material(Color(0.08, 0.19, 0.24, 0.82))
		vehicle.add_child(window)
		var mirror := MeshInstance3D.new()
		var mirror_mesh := SphereMesh.new()
		mirror_mesh.radius = 0.12
		mirror.mesh = mirror_mesh
		mirror.scale = Vector3(1.3, 0.7, 0.65)
		mirror.position = Vector3(side * 0.93, 0.53, -0.72)
		mirror.material_override = _material(Color(0.045, 0.055, 0.065))
		vehicle.add_child(mirror)
		for z in [-1.20, 1.20]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.34
			wheel_mesh.bottom_radius = 0.34
			wheel_mesh.height = 0.24
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(side * 0.94, -0.25, z)
			wheel.material_override = _material(Color(0.018, 0.022, 0.027))
			vehicle.add_child(wheel)
			var rim := MeshInstance3D.new()
			var rim_mesh := CylinderMesh.new()
			rim_mesh.top_radius = 0.18
			rim_mesh.bottom_radius = 0.18
			rim_mesh.height = 0.255
			rim.mesh = rim_mesh
			rim.rotation_degrees.z = 90
			rim.position = Vector3(side * 0.94, -0.25, z)
			rim.material_override = _material(Color(0.48, 0.52, 0.56))
			vehicle.add_child(rim)

	for side in [-0.65, 0.65]:
		var headlight := MeshInstance3D.new()
		var light_mesh := SphereMesh.new()
		headlight.mesh = light_mesh
		headlight.scale = Vector3(0.18, 0.10, 0.055)
		headlight.position = Vector3(side, 0.13, -1.87)
		headlight.material_override = _material(Color(1.0, 0.88, 0.60))
		vehicle.add_child(headlight)
		var taillight := MeshInstance3D.new()
		var tail_mesh := SphereMesh.new()
		taillight.mesh = tail_mesh
		taillight.scale = Vector3(0.15, 0.09, 0.05)
		taillight.position = Vector3(side, 0.12, 1.87)
		taillight.material_override = _material(Color(0.78, 0.035, 0.025))
		vehicle.add_child(taillight)

	var front_bumper := MeshInstance3D.new()
	var bumper_mesh := SphereMesh.new()
	bumper_mesh.radius = 1.0
	bumper_mesh.height = 2.0
	front_bumper.mesh = bumper_mesh
	front_bumper.scale = Vector3(0.92, 0.075, 0.12)
	front_bumper.position = Vector3(0, -0.13, -1.88)
	front_bumper.material_override = _material(Color(0.055, 0.06, 0.07))
	vehicle.add_child(front_bumper)
	var rear_bumper := MeshInstance3D.new()
	rear_bumper.mesh = bumper_mesh
	rear_bumper.scale = Vector3(0.92, 0.075, 0.12)
	rear_bumper.position = Vector3(0, -0.13, 1.88)
	rear_bumper.material_override = _material(Color(0.055, 0.06, 0.07))
	vehicle.add_child(rear_bumper)

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
	lightbar.name = "Lightbar"
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
		var bar := police_car.get_node_or_null("Lightbar") as MeshInstance3D
		if bar:
			bar.material_override = _material(Color(0.12, 0.28, 0.95) if int(Time.get_ticks_msec() / 350) % 2 == 0 else Color(0.95, 0.08, 0.06))
	var target: Node3D = active_car if in_car and is_instance_valid(active_car) else player
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
		active_car = car
		player.global_position = Vector3(0, 0.0, 5)
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
	inheritance_letter = Node3D.new()
	inheritance_letter.name = "Letter from the solicitor"
	inheritance_letter.position = Vector3(0, 1.43, -1.18)
	var envelope := MeshInstance3D.new()
	var envelope_mesh := BoxMesh.new()
	envelope_mesh.size = Vector3(0.72, 0.035, 0.48)
	envelope.mesh = envelope_mesh
	envelope.material_override = _material(Color(0.88, 0.80, 0.62))
	inheritance_letter.add_child(envelope)
	var seal := MeshInstance3D.new()
	var seal_mesh := SphereMesh.new()
	seal_mesh.radius = 0.075
	seal.mesh = seal_mesh
	seal.scale = Vector3(1.0, 0.25, 1.0)
	seal.position = Vector3(0, 0.035, 0)
	seal.material_override = _material(Color(0.58, 0.12, 0.10))
	inheritance_letter.add_child(seal)
	inheritance_letter.visible = false
	add_child(inheritance_letter)

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

	lena = _make_story_npc("Lena Ortiz", Vector3(10, 0, -2), Color(0.16, 0.34, 0.30))
	lena.visible = false
	detective = _make_story_npc("Detective Reed", Vector3(-24, 0, -2), Color(0.12, 0.17, 0.28))
	detective.visible = false

	evidence_case = Node3D.new()
	evidence_case.name = "Father Evidence Case"
	evidence_case.position = Vector3(30, 0, -26)
	var case_mesh := MeshInstance3D.new()
	var case_box := BoxMesh.new()
	case_box.size = Vector3(1.0, 0.7, 0.65)
	case_mesh.mesh = case_box
	case_mesh.position.y = 0.38
	case_mesh.material_override = _material(Color(0.12, 0.13, 0.15))
	evidence_case.add_child(case_mesh)
	var latch := MeshInstance3D.new()
	var latch_box := BoxMesh.new()
	latch_box.size = Vector3(0.22, 0.16, 0.05)
	latch.mesh = latch_box
	latch.position = Vector3(0, 0.4, -0.34)
	latch.material_override = _material(Color(0.78, 0.58, 0.22))
	evidence_case.add_child(latch)
	evidence_case.visible = false
	add_child(evidence_case)

func _make_story_npc(person_name: String, pos: Vector3, clothing: Color) -> Node3D:
	var person := Node3D.new()
	person.name = person_name
	person.position = pos
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.38
	body_mesh.height = 1.75
	body.mesh = body_mesh
	body.position.y = 0.88
	body.material_override = _material(clothing)
	person.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	head.mesh = head_mesh
	head.position.y = 1.88
	head.material_override = _material(Color(0.68, 0.49, 0.37))
	person.add_child(head)
	var tag := Label3D.new()
	tag.text = person_name.to_upper()
	tag.font_size = 28
	tag.position.y = 2.5
	tag.pixel_size = 0.012
	tag.modulate = Color(1.0, 0.84, 0.58)
	person.add_child(tag)
	add_child(person)
	return person

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

func _build_prologue_stage() -> void:
	# Separate sets for the opening: office, Alex's apartment, then the bus stop.
	_make_static_box("Office floor", Vector3(130, -0.12, 0), Vector3(16, 0.24, 14), Color(0.20, 0.22, 0.24))
	_make_static_box("Office back wall", Vector3(130, 2.2, -7), Vector3(16, 4.4, 0.25), Color(0.28, 0.31, 0.34))
	_make_static_box("Office side wall", Vector3(122, 2.2, 0), Vector3(0.25, 4.4, 14), Color(0.24, 0.27, 0.30))
	_make_box("Office desk", Vector3(130, 0.72, -1.5), Vector3(4.2, 1.35, 1.2), Color(0.19, 0.13, 0.09), self)
	_make_box("Office desk surface", Vector3(130, 1.42, -1.5), Vector3(4.4, 0.12, 1.35), Color(0.38, 0.25, 0.15), self)
	_make_box("Office monitor", Vector3(130, 2.0, -1.75), Vector3(1.1, 0.72, 0.12), Color(0.035, 0.05, 0.065), self)
	_make_box("Office window", Vector3(135, 2.5, -6.82), Vector3(4.0, 2.2, 0.08), Color(0.10, 0.22, 0.30, 0.75), self)
	prologue_manager = _make_story_npc("MANAGER", Vector3(133, 0, -3.0), Color(0.22, 0.25, 0.29))

	_make_static_box("Apartment floor", Vector3(150, -0.12, 0), Vector3(14, 0.24, 12), Color(0.31, 0.27, 0.22))
	_make_static_box("Apartment back wall", Vector3(150, 2.1, -6), Vector3(14, 4.2, 0.25), Color(0.42, 0.35, 0.28))
	_make_box("Apartment bed base", Vector3(147, 0.38, -1), Vector3(3.4, 0.65, 2.8), Color(0.17, 0.19, 0.22), self)
	_make_box("Apartment mattress", Vector3(147, 0.78, -1), Vector3(3.3, 0.22, 2.7), Color(0.70, 0.68, 0.60), self)
	_make_box("Apartment table", Vector3(153, 0.62, -2), Vector3(1.5, 1.1, 1.0), Color(0.24, 0.16, 0.10), self)
	_make_box("Apartment window", Vector3(150, 2.3, -5.82), Vector3(3.5, 1.8, 0.08), Color(0.12, 0.24, 0.31), self)

	_make_static_box("Bus stop platform", Vector3(170, -0.1, 0), Vector3(16, 0.2, 10), Color(0.30, 0.31, 0.30))
	_make_box("Bus shelter roof", Vector3(170, 3.0, -1), Vector3(8.0, 0.22, 3.0), Color(0.10, 0.13, 0.17), self)
	_make_box("Bus shelter glass", Vector3(170, 1.5, -2.4), Vector3(8.0, 2.8, 0.08), Color(0.20, 0.37, 0.43, 0.5), self)
	_make_box("Bus stop bench", Vector3(170, 0.72, -0.8), Vector3(3.2, 0.18, 0.55), Color(0.31, 0.20, 0.12), self)
	_make_box("Westbridge bus", Vector3(175, 1.45, 4.0), Vector3(7.0, 2.8, 2.5), Color(0.18, 0.30, 0.39), self)
	_make_box("Bus windows", Vector3(175, 2.05, 2.72), Vector3(6.2, 1.15, 0.08), Color(0.07, 0.17, 0.22), self)

func _set_intro_scene(index: int) -> void:
	if not is_instance_valid(player):
		return
	if index <= 1:
		player.global_position = Vector3(130, 0.0, 3.0)
		prologue_manager.visible = true
	elif index <= 3:
		player.global_position = Vector3(150, 0.0, 3.0)
		prologue_manager.visible = false
	elif index == 4:
		player.global_position = Vector3(170, 0.0, 3.0)
		prologue_manager.visible = false
	else:
		player.global_position = Vector3(0, 0.0, 5.0)
		prologue_manager.visible = false
	player.velocity = Vector3.ZERO
	camera_yaw = 0.0
	camera_pitch = 0.0
	if is_instance_valid(camera):
		camera.global_position = player.global_position + Vector3(0, 3.4, 7.0)
		camera.look_at(player.global_position + Vector3(0, 1.1, -1.0))

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
	_build_minimap(root)

	_add_touch_button(root, "▲", "forward", Vector2(88, -190), false)
	_add_touch_button(root, "◀", "left", Vector2(24, -126), false)
	_add_touch_button(root, "▼", "back", Vector2(88, -126), false)
	_add_touch_button(root, "▶", "right", Vector2(152, -126), false)
	_add_touch_button(root, "INTERACT", "interact", Vector2(-164, -132), true)
	_add_touch_button(root, "RUN", "run", Vector2(-164, -64), true)

func _build_minimap(root: Control) -> void:
	minimap_panel = ColorRect.new()
	minimap_panel.name = "WestbridgeMinimap"
	minimap_panel.color = Color(0.035, 0.055, 0.075, 0.88)
	minimap_panel.size = Vector2(190, 145)
	minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.position = Vector2(-210, 18)
	minimap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(minimap_panel)

	var title := Label.new()
	title.text = "WESTBRIDGE  |  N"
	title.position = Vector2(8, 4)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	minimap_panel.add_child(title)

	var horizontal_road := ColorRect.new()
	horizontal_road.position = Vector2(5, 115)
	horizontal_road.size = Vector2(180, 5)
	horizontal_road.color = Color(0.25, 0.29, 0.33)
	minimap_panel.add_child(horizontal_road)
	var vertical_road := ColorRect.new()
	vertical_road.position = Vector2(50, 20)
	vertical_road.size = Vector2(5, 118)
	vertical_road.color = Color(0.25, 0.29, 0.33)
	minimap_panel.add_child(vertical_road)
	var cross_road := ColorRect.new()
	cross_road.position = Vector2(5, 70)
	cross_road.size = Vector2(180, 4)
	cross_road.color = Color(0.18, 0.22, 0.26)
	minimap_panel.add_child(cross_road)

	minimap_target = ColorRect.new()
	minimap_target.size = Vector2(9, 9)
	minimap_target.color = Color(1.0, 0.72, 0.18)
	minimap_panel.add_child(minimap_target)
	minimap_alt_target = ColorRect.new()
	minimap_alt_target.size = Vector2(9, 9)
	minimap_alt_target.color = Color(0.95, 0.28, 0.22)
	minimap_panel.add_child(minimap_alt_target)
	minimap_player = ColorRect.new()
	minimap_player.size = Vector2(8, 8)
	minimap_player.color = Color(0.28, 0.9, 0.62)
	minimap_panel.add_child(minimap_player)
	_update_minimap()

func _update_minimap() -> void:
	if not is_instance_valid(minimap_panel) or not is_instance_valid(player):
		return
	var player_pos: Vector3 = active_car.global_position if in_car and is_instance_valid(active_car) else player.global_position
	minimap_player.position = Vector2(
		clampf(5.0 + (player_pos.x + 50.0) * 1.8, 5.0, 176.0),
		clampf(20.0 + (player_pos.z + 60.0) * 1.3, 20.0, 132.0)
	)
	minimap_target.visible = is_instance_valid(mission_marker) and mission_marker.visible
	if minimap_target.visible:
		var target_pos: Vector3 = mission_marker.global_position
		minimap_target.position = Vector2(
			clampf(5.0 + (target_pos.x + 50.0) * 1.8, 5.0, 176.0),
			clampf(20.0 + (target_pos.z + 60.0) * 1.3, 20.0, 132.0)
		)
	minimap_alt_target.visible = mission_stage == 11 and is_instance_valid(marcus) and marcus.visible
	if minimap_alt_target.visible:
		var alternate_pos: Vector3 = marcus.global_position
		minimap_alt_target.position = Vector2(
			clampf(5.0 + (alternate_pos.x + 50.0) * 1.8, 5.0, 176.0),
			clampf(20.0 + (alternate_pos.z + 60.0) * 1.3, 20.0, 132.0)
		)

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
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(button)
	# Native GUI button events keep movement active while another finger presses INTERACT.
	if action == "interact":
		button.pressed.connect(_interact)
	else:
		button.button_down.connect(func(): held[action] = true)
		button.button_up.connect(func(): held[action] = false)

func _input(event: InputEvent) -> void:
	var view_size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			touch_points[touch.index] = touch.position
			touch_last[touch.index] = touch.position
		else:
			touch_points.erase(touch.index)
			touch_last.erase(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if touch_points.has(drag.index):
			var previous: Vector2 = touch_last.get(drag.index, drag.position)
			var origin: Vector2 = touch_points[drag.index]
			if origin.x > view_size.x * 0.42 and origin.y < view_size.y - 225.0 and not (origin.x > view_size.x - 220.0 and origin.y < 175.0):
				camera_yaw -= (drag.position.x - previous.x) * 0.008
				camera_pitch = clampf(camera_pitch + (drag.position.y - previous.y) * 0.004, -0.18, 0.55)
			touch_last[drag.index] = drag.position

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
	_update_minimap()

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
	_animate_player(delta)

func _animate_player(delta: float) -> void:
	var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.5
	if moving:
		walk_time += delta * (13.0 if held.get("run", false) else 9.0)
	for i in range(player_legs.size()):
		var swing := sin(walk_time + float(i) * PI) * 0.48 if moving else 0.0
		player_legs[i].rotation.x = lerp_angle(player_legs[i].rotation.x, swing, delta * 12.0)
	for i in range(player_arms.size()):
		var swing := -sin(walk_time + float(i) * PI) * 0.32 if moving else 0.0
		player_arms[i].rotation.x = lerp_angle(player_arms[i].rotation.x, swing, delta * 12.0)
	if is_instance_valid(player_visual):
		var bob := absf(sin(walk_time * 2.0)) * 0.045 if moving else 0.0
		player_visual.position.y = lerpf(player_visual.position.y, 1.06 + bob, delta * 10.0)

func _drive_car(delta: float) -> void:
	var vehicle: CharacterBody3D = active_car if is_instance_valid(active_car) else car
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
	throttle = clampf(throttle, -1.0, 1.0)
	steering = clampf(steering, -1.0, 1.0)

	var forward_dir := -vehicle.global_transform.basis.z
	var forward_speed := vehicle.velocity.dot(forward_dir)
	var target_speed: float = throttle * CAR_SPEED if throttle >= 0.0 else throttle * REVERSE_SPEED
	var acceleration: float = 6.5
	if throttle != 0.0 and forward_speed * throttle < -0.1:
		acceleration = 14.0 # Brakes first, then engages reverse.
	elif throttle == 0.0:
		acceleration = 3.2 # Natural rolling resistance instead of instant stopping.
	forward_speed = move_toward(forward_speed, target_speed, acceleration * delta)

	# Steering only changes heading while the car is actually rolling.
	var speed_ratio: float = clampf(absf(forward_speed) / 3.0, 0.0, 1.0)
	vehicle.rotation.y -= steering * TURN_SPEED * delta * speed_ratio * sign(forward_speed if absf(forward_speed) > 0.05 else 1.0)
	forward_dir = -vehicle.global_transform.basis.z
	vehicle.velocity.x = forward_dir.x * forward_speed
	vehicle.velocity.z = forward_dir.z * forward_speed
	vehicle.velocity.y = 0.0
	vehicle.move_and_slide()

func _follow_camera(delta: float) -> void:
	var target: Node3D = active_car if in_car and is_instance_valid(active_car) else player
	var distance := 9.0 if in_car else 7.0
	var height := 4.0 if in_car else 3.4
	# Keep the third-person camera behind the player without orbiting when
	# the player turns. This prevents the arrow buttons from spinning the view.
	var horizontal := Vector3(sin(camera_yaw) * distance, 0.0, cos(camera_yaw) * distance)
	var desired := target.global_position + horizontal + Vector3(0, height + camera_pitch * 3.0, 0)
	camera.global_position = camera.global_position.lerp(desired, clamp(delta * 5.0, 0.0, 1.0))
	camera.look_at(target.global_position + Vector3(0, 1.1, 0))

func _start_intro() -> void:
	intro_active = true
	intro_index = 0
	_set_intro_scene(intro_index)
	_show_message(intro_lines[intro_index] + "  (Tap INTERACT to continue)")
	objective.text = "PROLOGUE  |  ALEX CARTER — BEFORE WESTBRIDGE"

func _advance_intro() -> void:
	intro_index += 1
	if intro_index >= intro_lines.size():
		intro_active = false
		_set_intro_scene(intro_lines.size())
		_show_message("You arrive at Westbridge Motors. The keys are yours. Take a look around, then check the reception desk.")
		_update_hud()
		return
	_set_intro_scene(intro_index)
	_show_message(intro_lines[intro_index] + "  (Tap INTERACT to continue)")

func _speak_message(line: String) -> void:
	# Use the device speech engine; gameplay remains available if TTS is unsupported.
	var voices: Array = DisplayServer.tts_get_voices()
	if voices.is_empty():
		return
	var voice_id := str(voices[0].get("id", ""))
	if voice_id.is_empty():
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(line, voice_id, 50, 1.0, 1.0, 1)

func _interact() -> void:
	if intro_active:
		_advance_intro()
		return
	if in_car:
		var exiting_vehicle: CharacterBody3D = active_car if is_instance_valid(active_car) else car
		in_car = false
		player.global_position = exiting_vehicle.global_position + exiting_vehicle.global_transform.basis.x * 2.2 + Vector3(0, 0.0, 0)
		player.visible = true
		active_car = car
		_show_message("You stepped out. Westbridge is yours to explore.")
		_update_hud()
		return

	var player_pos := player.global_position
	var nearest_vehicle: CharacterBody3D = null
	var nearest_distance := 4.5
	if player_pos.distance_to(car.global_position) < nearest_distance:
		nearest_vehicle = car
		nearest_distance = player_pos.distance_to(car.global_position)
	for vehicle in parked_cars:
		var distance_to_vehicle: float = player_pos.distance_to(vehicle.global_position)
		if distance_to_vehicle < nearest_distance:
			nearest_vehicle = vehicle
			nearest_distance = distance_to_vehicle
	if nearest_vehicle != null:
		active_car = nearest_vehicle
		in_car = true
		player.visible = false
		_show_message("VEHICLE ENTERED — ▲ accelerate, ▼ brake/reverse, ◀ ▶ steer. Tap INTERACT to exit.")
		_update_hud()
		return

	if stock_owned and player_pos.distance_to(repair_bay_position) < 3.8:
		if not stock_repaired:
			if cash >= 250:
				cash -= 250
				stock_repaired = true
				_show_message("GARAGE COMPLETE. Lena's workshop has repaired the trade-in. Take it back to the reception desk and close the sale.")
			else:
				_show_message("The workshop needs $250 for parts before it can repair this car.")
		else:
			_show_message("The trade-in is ready for its sale. Return to the reception desk.")
		_update_hud()
		_save_game()
		return

	var desk_pos := Vector3(0, 0, -1.2)
	if player_pos.distance_to(desk_pos) < 4.5:
		if mission_stage == 0:
			if not stock_owned and cash >= 1200:
				cash -= 1200
				stock_owned = true
				stock_repaired = false
				_show_message("FIRST TRADE-IN: You bought a neglected hatchback for $1,200. Take it to the garage workshop for repairs ($250), then bring it back here to sell.")
			elif stock_owned and stock_repaired:
				cash += 1950
				stock_owned = false
				stock_repaired = false
				sales_completed = maxi(sales_completed, 1)
				mission_stage = 1
				first_deal_done = true
				if is_instance_valid(inheritance_letter):
					inheritance_letter.visible = true
				_show_message("FIRST SALE CLOSED. +$1,950. As you clear the old paperwork, you find a sealed letter addressed to Alex Carter. It is from a lawyer — and it mentions your missing father.")
			elif stock_owned:
				_show_message("The hatchback still needs repairs. Take it to the workshop before trying to sell it.")
			else:
				_show_message("You need $1,200 to buy your first trade-in. Check the dealership funds.")
		elif mission_stage == 3:
			mission_stage = 4
			cash += 2500
			_show_message("CHAPTER 1 COMPLETE. You returned with the package. The numbers reveal your father was paying someone to keep the dealership alive. +$2,500.")
		elif mission_stage == 7:
			mission_stage = 8
			marcus.visible = true
			_show_message("The service file points back to Marcus. He has agreed to meet you at the freight yard. This time, get the truth.")
		elif mission_stage == 10:
			mission_stage = 11
			detective.visible = true
			marcus.visible = true
			_show_message("THE FINAL CHOICE. Detective Reed can expose the port network and clear your father's name. Marcus offers you control of the same criminal empire. Choose who you become.")
			_update_mission_marker()
		elif mission_stage >= 4:
			if not stock_owned and cash >= 1200:
				cash -= 1200
				stock_owned = true
				stock_repaired = false
				_show_message("TRADE-IN ACQUIRED: $1,200. Take it to the garage workshop at the right side of the dealership. Repairs cost $250.")
			elif stock_owned and stock_repaired:
				cash += 1950
				stock_owned = false
				stock_repaired = false
				sales_completed += 1
				_show_message("SALE CLOSED: the repaired car sold for $1,950. Your dealership cleared $500 after purchase and repair costs.")
			elif stock_owned:
				_show_message("This trade-in is not ready. Take it to the garage workshop before listing it.")
			else:
				_show_message("You need $1,200 to buy your next trade-in. Take a drive and come back.")
			if mission_stage == 4 and sales_completed >= 3:
				mission_stage = 5
				lena.visible = true
				_show_message("CHAPTER 2 — THE DEBT. Two profitable sales have kept the doors open. Lena Ortiz found a suspicious VIN in the old service records. Talk to her in the garage.")
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

	if mission_stage == 5 and is_instance_valid(lena) and player_pos.distance_to(lena.global_position) < 3.5:
		mission_stage = 6
		lena.visible = false
		evidence_case.visible = true
		_show_message("LENA: 'This VIN belongs to a car your father hid before he vanished. The police impounded it, but the storage yard clerk kept the original service file. Bring it back before the file disappears.'")
		_update_mission_marker()
		_update_hud()
		_save_game()
		return

	if mission_stage == 6 and is_instance_valid(evidence_case) and player_pos.distance_to(evidence_case.global_position) < 3.5:
		mission_stage = 7
		evidence_case.visible = false
		cash += 1000
		police_active = true
		wanted_timer = 65.0
		police_car.visible = true
		police_car.global_position = Vector3(-42, 0.72, 15)
		_show_message("SERVICE FILE RECOVERED. +$1,000. The yard cameras caught your plate. Lose the cruiser and return to Westbridge Motors.")
		_update_mission_marker()
		_update_hud()
		_save_game()
		return

	if mission_stage == 8 and is_instance_valid(marcus) and player_pos.distance_to(marcus.global_position) < 3.5:
		mission_stage = 9
		marcus.visible = false
		evidence_case.position = Vector3(-38, 0, -43)
		evidence_case.visible = true
		_show_message("MARCUS: 'Your father wasn't stealing cars. He was collecting proof that the port authority was laundering money through fake dealerships. He hid the original ledger in the old records depot.'")
		_update_mission_marker()
		_update_hud()
		_save_game()
		return

	if mission_stage == 9 and is_instance_valid(evidence_case) and player_pos.distance_to(evidence_case.global_position) < 3.5:
		mission_stage = 10
		evidence_case.visible = false
		_show_message("THE LAST LEDGER. A recording from your father explains why he disappeared — and leaves the future of Westbridge Motors in your hands. Get back to the dealership.")
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

	if mission_stage == 11 and is_instance_valid(detective) and player_pos.distance_to(detective.global_position) < 3.5:
		mission_stage = 12
		detective.visible = false
		marcus.visible = false
		cash += 5000
		_show_message("ENDING — CLEAN HANDS. Reed releases the evidence. The port network is exposed, your father's name is cleared, and Westbridge Motors survives as a legitimate business. +$5,000.")
		_update_mission_marker()
		_update_hud()
		_save_game()
		return

	if mission_stage == 11 and is_instance_valid(marcus) and player_pos.distance_to(marcus.global_position) < 3.5:
		mission_stage = 13
		detective.visible = false
		marcus.visible = false
		cash += 7500
		_show_message("ENDING — KINGMAKER. You destroy the public copy and take Marcus's offer. Westbridge Motors becomes the front for a city-wide operation. +$7,500.")
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
	elif mission_stage == 5:
		_show_message("Talk to Lena Ortiz in the garage.")
	elif mission_stage == 6:
		_show_message("Recover the service file from the storage yard.")
	elif mission_stage == 8:
		_show_message("Meet Marcus at the old freight yard.")
	elif mission_stage == 9:
		_show_message("Find the original ledger at the records depot.")
	elif mission_stage == 10:
		_show_message("Return to Westbridge Motors with the final ledger.")
	else:
		_show_message("No interaction nearby. Follow the gold waypoint or explore Westbridge.")

func _show_message(text_value: String) -> void:
	message.text = text_value
	message_timer = 9.0
	_speak_message(text_value)

func _update_mission_marker() -> void:
	if not is_instance_valid(mission_marker):
		return
	match mission_stage:
		0:
			mission_marker.global_position = repair_bay_position + Vector3(0, 0.12, 0) if stock_owned and not stock_repaired else Vector3(0, 0.12, -1.2)
		3, 7, 10:
			mission_marker.global_position = Vector3(0, 0.12, -1.2)
		1, 8:
			mission_marker.global_position = Vector3(28, 0.12, -30)
		2:
			mission_marker.global_position = Vector3(-30, 0.12, -25)
		5:
			mission_marker.global_position = Vector3(10, 0.12, -2)
		11:
			mission_marker.global_position = Vector3(-24, 0.12, -2)
		6, 9:
			mission_marker.global_position = evidence_case.global_position + Vector3(0, 0.12, 0)
		_:
			mission_marker.visible = false
			return
	mission_marker.visible = true

func _save_game() -> void:
	var data := ConfigFile.new()
	data.set_value("career", "save_version", 3)
	data.set_value("career", "mission_stage", mission_stage)
	data.set_value("career", "cash", cash)
	data.set_value("career", "sales_completed", sales_completed)
	data.set_value("career", "stock_owned", stock_owned)
	data.set_value("career", "stock_repaired", stock_repaired)
	data.save("user://underworld_save.cfg")

func _load_game() -> void:
	var data := ConfigFile.new()
	if data.load("user://underworld_save.cfg") == OK:
		# Older prototype saves could skip the new opening and drop the player
		# straight into the dealership. Start those saves cleanly once.
		var save_version := int(data.get_value("career", "save_version", 0))
		if save_version < 3:
			mission_stage = 0
			cash = 2450
			sales_completed = 0
			stock_owned = false
			stock_repaired = false
			_save_game()
		else:
			mission_stage = int(data.get_value("career", "mission_stage", 0))
			cash = int(data.get_value("career", "cash", 2450))
			sales_completed = int(data.get_value("career", "sales_completed", 0))
			stock_owned = bool(data.get_value("career", "stock_owned", false))
			stock_repaired = bool(data.get_value("career", "stock_repaired", false))
	first_deal_done = mission_stage >= 1
	if is_instance_valid(marcus):
		marcus.visible = mission_stage == 1 or mission_stage == 8 or mission_stage == 11
	if is_instance_valid(inheritance_letter):
		inheritance_letter.visible = mission_stage >= 1
	if is_instance_valid(detective):
		detective.visible = mission_stage == 11
	if is_instance_valid(package_crate):
		package_crate.visible = mission_stage == 2
	if is_instance_valid(lena):
		lena.visible = mission_stage == 5
	if is_instance_valid(evidence_case):
		evidence_case.visible = mission_stage == 6 or mission_stage == 9
	_update_mission_marker()

func _update_hud() -> void:
	hud.text = "WESTBRIDGE MOTORS     $%s     |     SALES %s" % [str(cash), str(sales_completed)]
	match mission_stage:
		0:
			if not stock_owned:
				objective.text = "FIRST SALE  |  Buy a $1,200 trade-in at the reception desk."
			elif not stock_repaired:
				objective.text = "FIRST SALE  |  Repair your trade-in at the workshop ($250)."
			else:
				objective.text = "FIRST SALE  |  Return to reception and sell the repaired car."
		1:
			objective.text = "THE LETTER  |  Meet Marcus Vale at the old freight yard."
		2:
			objective.text = "MISSION 01  |  Retrieve the sealed package from the warehouse."
		3:
			objective.text = "MISSION 01  |  Return to Westbridge Motors with the package."
		4:
			objective.text = "CHAPTER 1 COMPLETE  |  Complete 2 more profitable trade-in sales."
		5:
			objective.text = "CHAPTER 2  |  Talk to Lena Ortiz in the garage."
		6:
			objective.text = "CHAPTER 2  |  Recover the service file from the storage yard."
		7:
			objective.text = "CHAPTER 2  |  Return to Westbridge Motors and review the file."
		8:
			objective.text = "CHAPTER 3  |  Meet Marcus Vale at the freight yard."
		9:
			objective.text = "CHAPTER 3  |  Retrieve the original ledger from the records depot."
		10:
			objective.text = "CHAPTER 3  |  Return to Westbridge Motors with the final ledger."
		11:
			objective.text = "FINAL CHOICE  |  Detective Reed: expose the network. Marcus Vale: take control."
		12:
			objective.text = "ENDING: CLEAN HANDS  |  The network is exposed. Continue building a legitimate dealership."
		13:
			objective.text = "ENDING: KINGMAKER  |  You control the underworld. Continue building your empire."
		_:
			objective.text = "CAMPAIGN COMPLETE  |  Run Westbridge Motors and build your future."
	if police_active:
		objective.text += "     |     HEAT: 1"
