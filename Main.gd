extends Spatial

onready var player: KinematicBody = $WorldLoader/Player

# Called when the node enters the scene tree for the first time.
func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
    $DebugInfo.text = "Debug info:\n x: %f\n y: %f\n z: %f" \
    % [
        player.global_transform.origin.x, 
        player.global_transform.origin.y,
        player.global_transform.origin.z
    ]
    

func _input(event):
    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            get_tree().paused = true
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
            get_tree().paused = false
            
