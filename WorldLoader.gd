extends Node

var HEX_RADIUS = 3.0
var TILE_SIZE = 6.0
var TILE_LOAD_RADIUS = 16
var MAX_RADIUS = TILE_LOAD_RADIUS * HEX_RADIUS * 2
var TILE_CREATE_CYCLE_COUNT = 50
var TILE_DELETE_CYCLE_COUNT = 3
const THREAD_CREATE_CNT = 1
const THREAD_DELETE_CNT = 1

var existing_hexes: Array
var tile_scenes: Array
var tiles: Dictionary
var player: Spatial
var height_noise: OpenSimplexNoise
var hexes_to_remove: Array
var hexes_to_add: Array
var thread: Thread
var add_mutex: Mutex
var remove_mutex: Mutex

# Called when the node enters the scene tree for the first time.
func _ready():
    height_noise = OpenSimplexNoise.new()
    height_noise.seed = randi()
    height_noise.octaves = 4
    height_noise.period = 50.0
    height_noise.persistence = 0.8
    
    tile_scenes.append(preload("res://tiles/hex_000.tscn"))
    player = get_node("Player")
    
    remove_mutex = Mutex.new()
    add_mutex = Mutex.new()
    thread = Thread.new()
    thread.start(self, "generate_hexes")
    
func _exit_tree():
    #thread.wait_to_finish()
    pass
    
func _physics_process(delta):
    add_mutex.lock()
    
    var add_count = min(TILE_CREATE_CYCLE_COUNT, hexes_to_add.size())
    
    for i in range(hexes_to_add.size()):
        var item = hexes_to_add.pop_back()
        
        var hex: Hex = item["hex"]
                       
        var new_scene: PackedScene = tile_scenes[0]
        var new_node: Spatial = new_scene.instance()
        self.add_child(new_node)
        
        var new_pt: Vector3 = item["pt"]
        new_node.global_transform.origin.x = new_pt.x
        new_node.global_transform.origin.z = -new_pt.y
        new_node.global_transform.origin.y = new_pt.z
              
        if not tiles.has(hex.q):
            tiles[hex.q] = {}  
        tiles[hex.q][hex.r] = new_node
    
    
    var remove_count = min(TILE_DELETE_CYCLE_COUNT, hexes_to_remove.size())
    
    for i in range(hexes_to_remove.size()):
        var hex: Hex = hexes_to_remove.pop_back()
        
        #if not tiles.has(hex.q) or not tiles[hex.q].has(hex.r):
        #    continue
            
        var node = tiles[hex.q][hex.r]
        
        tiles[hex.q].erase(hex.r)
        if tiles[hex.q].empty():
            tiles.erase(hex.q)
            
        self.remove_child(node)
        node.queue_free()
 
    add_mutex.unlock()
    
func generate_hexes(data):
    while true:
        var player_pos: Vector2
        player_pos.x = player.global_transform.origin.x
        player_pos.y = -player.global_transform.origin.z
        
        add_mutex.lock()
            
        # Tile creation
        for iter in range(THREAD_CREATE_CNT):
            var offset_q: int = Util.randi_range(-TILE_LOAD_RADIUS, TILE_LOAD_RADIUS)
            var range_min:int = max(-TILE_LOAD_RADIUS - offset_q, -TILE_LOAD_RADIUS)
            var range_max:int = min(TILE_LOAD_RADIUS - offset_q, TILE_LOAD_RADIUS)
            var offset_r: int = Util.randi_range(range_min, range_max)
            
            var player_hex: Hex = Util.hex_from_pt(player_pos / HEX_RADIUS)
            var hex: Hex = Hex.new(player_hex.q + offset_q, player_hex.r + offset_r)
            
            var q_found: bool = tiles.has(hex.q)
            var r_found: bool = q_found and tiles[hex.q].has(hex.r)
                  
            if not (q_found and r_found):  
                var already_in_queue: bool = false
                for i in range(hexes_to_add.size()):
                    var other_hex: Hex = hexes_to_add[i]["hex"]
                    if hex.is_equal(other_hex):
                        already_in_queue = true
                        break
                             
                if not already_in_queue:                 
                    var new_pt: Vector3
                    new_pt.x = hex.to_pt().x * HEX_RADIUS
                    new_pt.y = hex.to_pt().y * HEX_RADIUS
                    var height = height_noise.get_noise_2dv(hex.to_pt())
                    new_pt.z = round(height * 8) * 0.75
                    
                    hexes_to_add.append({
                        "hex": hex,
                        "pt": new_pt
                    })
                
        for iter in range(THREAD_DELETE_CNT):
            # Tile cleanup
            if not tiles.empty():
                var hex_q = tiles.keys()[randi() % tiles.size()]
                var hex_r = tiles[hex_q].keys()[randi() % tiles[hex_q].size()]
                
                var hex: Hex = Hex.new(hex_q, hex_r)
                var hex_pos: Vector2 = hex.to_pt() * HEX_RADIUS
                var dist_to_player_sqr: float = hex_pos.distance_squared_to(player_pos)

                if dist_to_player_sqr > MAX_RADIUS * MAX_RADIUS:
                    var already_in_queue: bool = false
                    for i in range(hexes_to_remove.size()):
                        if hex.is_equal(hexes_to_remove[i]):
                            already_in_queue = true
                            break
                            
                    if not already_in_queue:
                        hexes_to_remove.append(hex)
                        
        add_mutex.unlock()
    
    
    
