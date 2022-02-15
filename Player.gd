extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var MAX_SPEED = 20
export var MIN_SPEED = 1
export var ACCEL = 50
export var GRAVITY = 100
export var FRICTION = 2
export var JUMP_VELOCITY = 20

var velocity: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func _physics_process(delta):
    # We create a local variable to store the input direction.
    var h_direction: Vector2 = Vector2.ZERO

    # We check for each move input and update the direction accordingly.
    if Input.is_action_pressed("move_right"):
        h_direction.x += 1
    if Input.is_action_pressed("move_left"):
        h_direction.x -= 1
    if Input.is_action_pressed("move_up"):
        h_direction.y += 1
    if Input.is_action_pressed("move_down"):
        h_direction.y -= 1
        
    h_direction = h_direction.normalized()
    
    velocity.x += h_direction.x * ACCEL * delta
    velocity.z += -h_direction.y * ACCEL * delta
    
    if Input.is_action_just_pressed("jump") and self.is_on_floor():
        velocity.y += JUMP_VELOCITY
    
    var h_velocity = Vector3(velocity.x, 0, velocity.z)
    
    if h_velocity.length() > MAX_SPEED:
        h_velocity = h_velocity.normalized() * MAX_SPEED
        velocity.x = h_velocity.x
        velocity.z = h_velocity.z
            
    # Vertical velocity
    velocity.y -= GRAVITY * delta
    # Moving the character
    velocity = move_and_slide(velocity, Vector3.UP)
    
    # surface friction
    h_velocity = Vector3(velocity.x, 0, velocity.z)
    h_velocity = h_velocity.linear_interpolate(Vector3.ZERO, FRICTION * delta)
    velocity.x = h_velocity.x
    velocity.z = h_velocity.z
    
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
