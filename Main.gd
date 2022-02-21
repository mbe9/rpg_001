extends Spatial

onready var world_loader = $WorldLoader
onready var player: KinematicBody = $WorldLoader/Player
onready var debug_text = $TabContainer/DebugInfo
onready var debug_height_map = $TabContainer/HeightMap

# Called when the node enters the scene tree for the first time.
func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    debug_height_map.set_hex_size(10)

func _process(delta):
    debug_text.text = "x: %f\n y: %f\n z: %f" \
    % [
        player.global_transform.origin.x, 
        player.global_transform.origin.y,
        player.global_transform.origin.z
    ]
    debug_text.text += "\nhex count: %d" % ($WorldLoader.get_child_count() - 1)
    
    var player_pos: Vector2 = Vector2(
        player.global_transform.origin.x, 
        -player.global_transform.origin.z) / world_loader.HEX_RADIUS
        
    var player_hex: Hex = Util.hex_from_pt(player_pos)
    var hexes = Util.get_hexes_in_radius(16)
    
    var height_map: Array = []
    for hex in hexes:
        var world_hex: Hex = Hex.new(hex.q + player_hex.q, hex.r + player_hex.r)
        var lvl: int = world_loader.gen_hex_height_level(world_hex)
        var color
        if lvl >= 0:      
            color = Color.green.linear_interpolate(Color.brown, lvl * 0.1)
        else:
            color = Color.green.linear_interpolate(Color.blue, - lvl * 0.1)
        
        var item = {
            "hex": hex,
            "color": color
        }
        height_map.append(item)
        
    debug_height_map.set_center_pos(-player_pos + player_hex.to_pt())
    debug_height_map.set_hexes(height_map)
    debug_height_map.set_map_rotation($WorldLoader/Player.rotation_degrees.y)
        
    
func _input(event):
    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            get_tree().paused = true
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
            get_tree().paused = false
            
