extends KinematicBody

const GRAVITY = -24.8
export var vel = Vector3()
const MAX_SPEED = 20
const SPRINT_MULTIPLIER = 1.0005
const JUMP_SPEED = 15
const ACCEL = 4.5
var lift = 1 # -1 means lift is active, 1 is inactive
var room = 1
var preview_room = 2


var sprint = 1
var dir = Vector3()
var time = 0

const WARNING_TIME = 2

const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

var MOUSE_SENSITIVITY = 0.05

var room_label
var preview_label
var cant_swap_label
var preview_player
var hud
var viewport_container

func _ready():
	camera = $Rotation_Helper/Camera
	rotation_helper = $Rotation_Helper
	cant_swap_label = $HUD/Cant_swap_label
	hud = $HUD
	viewport_container = $HUD/ViewportContainer
	
	preview_player = get_parent().get_node("PreviewPlayer")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	room_label = get_node("HUD/Room_label")
	room_label.set_text("Room: 1")
	preview_label = get_node("HUD/Preview_label")
	preview_label.set_text("Preview: 1")

func can_swap(target):
	return not preview_player.is_colliding()

func swap_room(target):
	global_translate(Vector3((target-room) * 100, 0, 0))
	room = target
	
func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	

func process_input(delta):
	var hud_size = OS.get_window_size()
	var view_size = viewport_container.get_size()
	cant_swap_label.set_position(Vector2(hud_size.x/2 - cant_swap_label.get_size().x/2, cant_swap_label.get_position().y))
	
	viewport_container.set_position(Vector2(hud_size.x - view_size.x, 0))
	
	if cant_swap_label.is_visible():
		time += delta

	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()
	
	sprint = 1

	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x += 1

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x 
	# ----------------------------------

	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
		
		if Input.is_action_pressed("sprint"):
			sprint = SPRINT_MULTIPLIER
	# ----------------------------------

	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

	# ----------------------------------
	# Previewing rooms
	if Input.is_action_just_pressed("teleport_1") and room != 1:
		preview_room = 1
	elif Input.is_action_just_pressed("teleport_2") and room != 2:
		preview_room = 2
	elif Input.is_action_just_pressed("teleport_3") and room != 3:
		preview_room = 3
	elif Input.is_action_just_pressed("teleport_4") and room != 4:
		preview_room = 4
	preview_label.set_text("Preview: " + str(preview_room))
	# ----------------------------------
	
	# ----------------------------------
	# Teleport
	if Input.is_action_just_pressed("teleport_commit") and can_swap(preview_room):
		var temp = room
		swap_room(preview_room)
		preview_room = temp
		
		room_label.set_text("Room: " + str(room))
		preview_label.set_text("Preview: " + str(preview_room))
		time = 0
		cant_swap_label.hide()
	elif Input.is_action_just_pressed("teleport_commit"):
		cant_swap_label.show()
		time = 0
		
	if time >= WARNING_TIME:
		time = 0
		cant_swap_label.hide()
	# ----------------------------------
	
	
	
func process_movement(delta):
	lift = 1
	for body in get_parent().get_node("Room 1/Lift_Volume").get_overlapping_bodies():
		if body == self:
			lift = -1
	
	dir.y = 0
	dir = dir.normalized()

	vel.y += delta * GRAVITY * lift

	var hvel = vel
	hvel.y = 0

	var target = dir
	target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x * sprint
	vel.z = hvel.z * sprint
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
