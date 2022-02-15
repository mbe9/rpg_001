extends Node

var TILE_SIZE = 100.0
var TILE_LOAD_RADIUS = 8
var TILE_CREATE_CYCLE_COUNT = 3
var TILE_DELETE_CYCLE_COUNT = 3

var tile_scenes: Array
var tiles: Dictionary
var player: Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
    tile_scenes.append(preload("res://tiles/tile_flat_001.tscn"))
    player = get_node("Player")

func _physics_process(delta):
    var player_pos: Vector2
    player_pos.x = player.global_transform.origin.x
    player_pos.y = -player.global_transform.origin.z
    
    # Tile creation
    for i in range(TILE_CREATE_CYCLE_COUNT):
        var random_radius: float = randf() * TILE_SIZE * TILE_LOAD_RADIUS
        var random_angle: float = randf() * PI * 2
        
        # Ununiformed distribution of points is intentional here
        var random_offset_x: float = random_radius * cos(random_angle)
        var random_offset_y: float = random_radius * sin(random_angle)
        
        var tile_x: int = int((player_pos.x + random_offset_x) / 100)
        var tile_y: int = int((player_pos.y + random_offset_y) / 100)
        
        var tile_exists: bool = tiles.has(tile_x) and tiles[tile_x].has(tile_y)
            
        if not tile_exists:
            var new_scene: PackedScene = tile_scenes[0]
            var new_node: Spatial = new_scene.instance()
            
            if not tiles.has(tile_x):
                tiles[tile_x] = {}
                
            tiles[tile_x][tile_y] = new_node
            self.add_child(new_node)
            new_node.global_transform.origin.x = tile_x * 100
            new_node.global_transform.origin.z = -tile_y * 100
            new_node.global_transform.origin.y = randf() * 2
               
    # Tile cleanup
    for i in range(TILE_DELETE_CYCLE_COUNT):
        if tiles.size() > 0:
            var random_tile_x_idx = randi() % tiles.size()
            var tile_x = tiles.keys()[random_tile_x_idx]
            
            var subdict = tiles[tile_x]
            var random_tile_y_idx = randi() % subdict.size()
            var tile_y = subdict.keys()[random_tile_y_idx]
            
            var tile_world: Vector2 = Vector2(tile_x, tile_y) * TILE_SIZE
            
            var dist_to_player_sqr = tile_world.distance_squared_to(player_pos)
            
            if dist_to_player_sqr > (TILE_LOAD_RADIUS * TILE_SIZE) * (TILE_LOAD_RADIUS * TILE_SIZE):
                var node: Node = tiles[tile_x][tile_y]
                self.remove_child(node)
                node.queue_free()
                
                tiles[tile_x].erase(tile_y)
                
                if tiles[tile_x].empty():
                    tiles.erase(tile_x)
    
    
    
    
