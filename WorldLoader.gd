extends Node

var HEX_RADIUS = 3.0
var TILE_SIZE = 6.0
var TILE_LOAD_RADIUS = 8
var MAX_RADIUS = TILE_LOAD_RADIUS * HEX_RADIUS * 2
var TILE_CREATE_CYCLE_COUNT = 50
var TILE_DELETE_CYCLE_COUNT = 3

var existing_hexes: Array
var tile_scenes: Array
var tiles: Dictionary
var player: Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
    tile_scenes.append(preload("res://tiles/hex_000.tscn"))
    player = get_node("Player")

func _physics_process(delta):
    var player_pos: Vector2
    player_pos.x = player.global_transform.origin.x
    player_pos.y = -player.global_transform.origin.z
    
    # Tile creation
    for i in range(TILE_CREATE_CYCLE_COUNT):
        var offset_q: int = Util.randi_range(-TILE_LOAD_RADIUS, TILE_LOAD_RADIUS)
        var range_min:int = max(-TILE_LOAD_RADIUS - offset_q, -TILE_LOAD_RADIUS)
        var range_max:int = min(TILE_LOAD_RADIUS - offset_q, TILE_LOAD_RADIUS)
        var offset_r: int = Util.randi_range(range_min, range_max)
         
        var player_hex: Hex = Util.hex_from_pt(player_pos / HEX_RADIUS)
        var hex: Hex = Hex.new(player_hex.q + offset_q, player_hex.r + offset_r)
        
        var q_found: bool = tiles.has(hex.q)
        var r_found: bool = q_found and tiles[hex.q].has(hex.r)
        
        if (not q_found) or (not r_found):
            var new_scene: PackedScene = tile_scenes[0]
            var new_node: Spatial = new_scene.instance()
                
            if not q_found:
                tiles[hex.q] = {}
                
            tiles[hex.q][hex.r] = new_node
            self.add_child(new_node)
            
            var new_pt = hex.to_pt() * HEX_RADIUS
            new_node.global_transform.origin.x = new_pt.x
            new_node.global_transform.origin.z = -new_pt.y
            new_node.global_transform.origin.y = randf() * 0.2
            
            existing_hexes.append(hex)
               
    # Tile cleanup
    for i in range(min(TILE_DELETE_CYCLE_COUNT, existing_hexes.size())):
        var rand_idx = randi() % existing_hexes.size()
        var random_hex: Hex = existing_hexes[rand_idx]
        var hex_pos: Vector2 = random_hex.to_pt() * HEX_RADIUS
        var dist_to_player_sqr: float = hex_pos.distance_squared_to(player_pos)

        if dist_to_player_sqr > MAX_RADIUS * MAX_RADIUS:
            var node: Node = tiles[random_hex.q][random_hex.r]
            self.remove_child(node)
            node.queue_free()

            tiles[random_hex.q].erase(random_hex.r)

            if tiles[random_hex.q].empty():
                tiles.erase(random_hex.q)
            
            existing_hexes.pop_at(rand_idx)

    
    
    
