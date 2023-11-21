extends CharacterBody3D

# Character nodes.
@onready var collider = $CollisionShape3D
@onready var ray_cast_3d = $RayCast3D
@onready var neck = $neck
@onready var head = $neck/head
@onready var eyes = $neck/head/eyes
@onready var camera_3d = $neck/head/eyes/Camera3D

# Movement vars.
var current_speed = 5.0
const walking_speed = 5.0
const sprinting_speed = 8.0
const crouching_speed = 3.0
const JUMP_VELOCITY = 7.0
var direction = Vector3.ZERO
var freelook_tilt_amount = 10

# Movement states.
var walking = false
var sprinting = false
var crouching = false
var freelooking = false
var sliding = false

# Slide vars.
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 15.0

# Head bobbing vars.
const head_bobbing_sprinting_speed = 22
const head_bobbing_walking_speed = 14
const head_bobbing_crouching_speed = 10

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

#Camera.
const mouse_sens = 0.25
var crouching_depth = -0.5
var lerp_speed = 8

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		if freelooking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Running & crouching.
	if Input.is_action_pressed("crouch") or sliding:
		current_speed = crouching_speed
		collider.shape.height = 1.2
		head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
		
		# Slide begin logic
		
		if sprinting and input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			freelooking = true
		
		walking = false
		sprinting = false
		crouching = true
	elif !ray_cast_3d.is_colliding():
		collider.shape.height = 2
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		if Input.is_action_pressed("sprint"):
			current_speed = sprinting_speed
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed = walking_speed
			walking = true
			sprinting = false
			crouching = false
	
	# Handle freelooking.
	if Input.is_action_pressed("freelooking") or sliding:
		freelooking = true
		
		if sliding:
			camera_3d.rotation.z = lerp(camera_3d.rotation.z, -deg_to_rad(4), delta * lerp_speed)
		else:
			camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * freelook_tilt_amount)
	else:
		freelooking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.y, 0.0, delta * lerp_speed)
	
	# Handle sliding.
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			slide_timer = 0.0
			freelooking = false
	
	# Handle head bob.
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
	
	if is_on_floor() and !sliding and input_dir != Vector2.ZERO:
		head_bobbing_vector.y  = sin(head_bobbing_index)
		head_bobbing_vector.x  = sin(head_bobbing_index/2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity/2.0), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.y * head_bobbing_current_intensity, delta * lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerp_speed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !ray_cast_3d.is_colliding():
		velocity.y = JUMP_VELOCITY


	# Actual movement.
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	
	if sliding:
		direction =  lerp(direction, (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized(), delta * lerp_speed)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * (slide_timer + 0.1) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.1) * slide_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
