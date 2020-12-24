extends KinematicBody

const GRAVITY = -24.8
#const GRAVITY = 0
var vel = Vector3()
const MAX_SPEED = 20
const SPRINT_MULTIPLIER = 1.08
const JUMP_SPEED = 18
const ACCEL = 4.5

var room = 1
var preview_room = 2


var sprint = 1
var dir = Vector3()

const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

var MOUSE_SENSITIVITY = 0.05

var offset = 0

func _ready():
	rotation_helper = $Rotation_Helper
	
	
func is_colliding():
	return $Area.get_overlapping_bodies().size() > 0 or $Area.get_overlapping_areas().size() > 0

func swap_room(target):
	global_translate(Vector3((target-preview_room) * 100, 0, 0))
	preview_room = target
	
func _physics_process(delta):
	process_input(delta)
	process_movement(delta)

func process_input(_delta):

# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = rotation_helper.get_global_transform()

	var input_movement_vector = Vector2()
	
	sprint = 1

#	if Input.is_action_pressed("movement_forward"):
#		input_movement_vector.y += 1
#	if Input.is_action_pressed("movement_backward"):
#		input_movement_vector.y -= 1
#	if Input.is_action_pressed("movement_left"):
#		input_movement_vector.x -= 1
#	if Input.is_action_pressed("movement_right"):
#		input_movement_vector.x += 1

	#input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
#	dir += -cam_xform.basis.z * input_movement_vector.y
#	dir += cam_xform.basis.x * input_movement_vector.x 
	# ----------------------------------

#	# ----------------------------------
#	# Jumping
#	if is_on_floor():
#		if Input.is_action_just_pressed("movement_jump"):
#			vel.y = JUMP_SPEED
#
#		if Input.is_action_pressed("sprint"):
#			sprint = SPRINT_MULTIPLIER
	# ----------------------------------

	# ----------------------------------
	# Teleporting across rooms
	if Input.is_action_just_pressed("teleport_1") and room != 1:
		swap_room(1)
	elif Input.is_action_just_pressed("teleport_2") and room != 2:
		swap_room(2)
	elif Input.is_action_just_pressed("teleport_3") and room != 3:
		swap_room(3)
	elif Input.is_action_just_pressed("teleport_4") and room != 4:
		swap_room(4)
	# ----------------------------------
	
	if Input.is_action_just_pressed("teleport_commit") and not is_colliding():
		var temp = preview_room
		swap_room(room)
		room = temp
		
		
	
func process_movement(delta):
	if get_node("../Player") != null:
		vel = get_node("../Player").vel
	offset = (preview_room - room) * 100
	global_transform.origin = get_node("../Player").global_transform.origin + Vector3(offset, 0, 0)
	#vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot
