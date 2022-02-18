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
var camera_pivot: Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
    camera_pivot = $Camera
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
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
    
    var move_dir_3d = Vector3()
    move_dir_3d += self.global_transform.basis.x * h_direction.x
    move_dir_3d += -self.global_transform.basis.z * h_direction.y
    move_dir_3d.y = 0
    move_dir_3d = move_dir_3d.normalized()
    
    var move_dir = Vector2(move_dir_3d.x, -move_dir_3d.z)
    
    velocity.x += move_dir.x * ACCEL * delta
    velocity.z += -move_dir.y * ACCEL * delta
    
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
    
func _input(event):
    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
            
    if event is InputEventMouseMotion:
        var h_movement: float = (event as InputEventMouseMotion).relative.x;
        var clamped = clamp(h_movement, -10, 10)
        var rot_rad = -deg2rad(h_movement)
        self.rotate_y(rot_rad)
        
        var v_mov: float = (event as InputEventMouseMotion).relative.y;
        var clamped_v = clamp(v_mov, -10, 10)
        var rot_rad_v = -deg2rad(v_mov)
        camera_pivot.rotate_x(rot_rad_v)
        camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, -80, 80)
