extends Control

onready var hex_array: Array = []
onready var hex_size: float = 1 setget set_hex_size
onready var center_pos := Vector2() setget set_center_pos
onready var rotation: float = 0 setget set_map_rotation

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func set_hex_size(size: float):
    hex_size = size
    update()
    
func set_center_pos(pos: Vector2):
    center_pos = pos
    update()
    
func set_map_rotation(rot: float):
    rotation = rot
    update()
    
func set_hexes(array: Array):
    hex_array = array
    update()

func draw_hex(hex: Hex, color: Color):
    var nb_points = 32
    var points_arc = PoolVector2Array()
    var colors = PoolColorArray([color])
    var hex_center := (center_pos + hex.to_pt()) * hex_size

    for i in range(6):
        var ang = deg2rad(60 * i)
        var pos = hex_center + Vector2(cos(ang), sin(ang)) * hex_size
        pos.y = -pos.y
        pos = pos.rotated(deg2rad(rotation))
        pos += rect_size / 2
        points_arc.push_back(pos)
        
    draw_polygon(points_arc, colors)    

func draw_pointer(color: Color):
    var points_arc = PoolVector2Array()
    var colors = PoolColorArray([color])

    points_arc.push_back(rect_size / 2 + Vector2(-3, 0))
    points_arc.push_back(rect_size / 2 + Vector2(3, 0))
    points_arc.push_back(rect_size / 2 + Vector2(0, -7))
        
    draw_polygon(points_arc, colors) 
    
func _draw():
    for item in hex_array:
        draw_hex(item["hex"], item["color"])
    
    draw_pointer(Color.red)
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass
