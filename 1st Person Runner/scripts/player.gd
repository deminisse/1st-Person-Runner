extends CharacterBody3D

# Character nodes.
@onready var collider = $CollisionShape3D
@onready var ray_cast_3d = $RayCast3D
@onready var head = $head

# Movement.
var current_speed = 5.0
const walking_speed = 5.0
const running_speed = 8.0
const crouching_speed = 3.0
const JUMP_VELOCITY = 5.0
var direction = Vector3.ZERO

#Camera.
const mouse_sens = 0.25
var crouching_depth = -0.5
var lerp_speed = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	# Running & crouching.
	if Input.is_action_pressed("crouch"):
		current_speed = crouching_speed
		collider.shape.height = 1.2
		head.position.y = lerp(head.position.y, 1.8 + crouching_depth, delta * lerp_speed)
	elif !ray_cast_3d.is_colliding():
		collider.shape.height = 2
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		if Input.is_action_pressed("sprint"):
			current_speed = running_speed
		else:
			current_speed = walking_speed
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !ray_cast_3d.is_colliding():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
