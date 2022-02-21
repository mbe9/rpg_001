extends Node

var HEX_RADIUS = 3.0
var TILE_SIZE = 6.0
var TILE_LOAD_RADIUS = 16
var MAX_RADIUS = TILE_LOAD_RADIUS * HEX_RADIUS * 2
var MIN_RADIUS = 4 * HEX_RADIUS * 2
var CREATE_FRAME_CNT = 200
var DELETE_FRAME_CNT = 20
const THREAD_CREATE_CNT = 750
const THREAD_DELETE_CNT = 500

var existing_hexes: Array
var tile_scenes: Dictionary
var tiles: Dictionary
var player: Spatial
var height_noise: OpenSimplexNoise
var hexes_to_remove: Array
var hexes_to_add: Array
var gen_thread: Thread
var cleanup_thread: Thread
var curr_add_cnt: int = 0
var curr_remove_cnt: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    height_noise = OpenSimplexNoise.new()
    height_noise.seed = randi()
    height_noise.octaves = 4
    height_noise.period = 5.0
    height_noise.persistence = 0.8

    tile_scenes = {
        "flat": preload("res://tiles/hex_flat.tscn"),
        "flat_low": preload("res://tiles/hex_flat_low.tscn"),
        "down01": preload("res://tiles/hex_slope_down01.tscn"),
        "down012": preload("res://tiles/hex_slope_down012.tscn"),
        "down0123": preload("res://tiles/hex_slope_down0123.tscn"),
        "down01234": preload("res://tiles/hex_slope_down01234.tscn"),
        "down012345": preload("res://tiles/hex_slope_down012345.tscn"),
        "down0134": preload("res://tiles/hex_slope_down0134.tscn"),
        "down03": preload("res://tiles/hex_slope_down03.tscn"),
        "down013": preload("res://tiles/hex_slope_down013.tscn"),
        "down014": preload("res://tiles/hex_slope_down014.tscn"),
    }

    player = get_node("Player")
    
    gen_thread = Thread.new()
    cleanup_thread = Thread.new()
    gen_thread.start(self, "generate_hexes", player.get_global_transform())
    cleanup_thread.start(self, "cleanup_hexes", player.get_global_transform())

func _exit_tree():
    #thread.wait_to_finish()
    pass
    
func _receive_cleanup_results():
    hexes_to_remove = cleanup_thread.wait_to_finish()

func _receive_gen_results():
    hexes_to_add = gen_thread.wait_to_finish()

func _physics_process(_delta):
    if not gen_thread.is_active() and not cleanup_thread.is_active():
        var add_cnt: int = min(hexes_to_add.size() - curr_add_cnt, CREATE_FRAME_CNT)
        
        for i in range(hexes_to_add.size()):
            var item = hexes_to_add[i]
            
            var hex: Hex = item["hex"]
                            
            var new_node: Spatial = item["scene"].instance()
            self.add_child(new_node)
            
            new_node.rotate_y(deg2rad(item["rot"] * 60.0))
            
            var new_pt: Vector3 = item["pt"]
            new_node.global_transform.origin.x = new_pt.x
            new_node.global_transform.origin.z = -new_pt.y
            new_node.global_transform.origin.y = new_pt.z
                    
            if not tiles.has(hex.q):
                tiles[hex.q] = {}  
            tiles[hex.q][hex.r] = new_node
                
        var remove_cnt: int = min(hexes_to_remove.size() - curr_remove_cnt, DELETE_FRAME_CNT)
        
        for i in range(hexes_to_remove.size()):
            var hex: Hex = hexes_to_remove[i]
            
            var node = tiles[hex.q][hex.r]
            
            tiles[hex.q].erase(hex.r)
            if tiles[hex.q].empty():
                tiles.erase(hex.q)

            self.remove_child(node)
            node.queue_free()
             
        cleanup_thread.start(self, "cleanup_hexes", player.get_global_transform())
        gen_thread.start(self, "generate_hexes", player.get_global_transform())
        
func gen_hex_model(hex: Hex) -> Array:
    var hex_lvl: int = gen_hex_height_level(hex)
    var adj_hexes: Array = Util.get_adj_hexes(hex)
    var adj_hexes_lvl: Array = []
    
    var min_adj_lvl = INF
    var max_adj_lvl = -INF
    var down_1_cnt = 0
    
    for i in range(6):
        var lvl: int = gen_hex_height_level(adj_hexes[i]) - hex_lvl
        adj_hexes_lvl.append(lvl)
        if lvl == -1:
            down_1_cnt += 1
        if lvl > max_adj_lvl:
            max_adj_lvl = lvl
        if lvl < min_adj_lvl:
            min_adj_lvl = lvl
      
    if min_adj_lvl >= 0:
        return ["flat_low", 0]  
        
    match down_1_cnt:
        1:
            for i in range(6):
                if adj_hexes_lvl[i] == -1:
                    return ["down01", i]
        2: 
            for i in range(6):
                if (adj_hexes_lvl[i] == -1) and (adj_hexes_lvl[i - 1] == -1):
                    return ["down012", i]
            for i in range(6):
                if (adj_hexes_lvl[i] == -1) and (adj_hexes_lvl[i - 2] == -1):
                    if (adj_hexes_lvl[i - 1] < - 1):
                        return ["down0123", i]
                    else:
                        return ["down03", i]
            for i in range(3):
                if (adj_hexes_lvl[i] == -1) and (adj_hexes_lvl[i - 3] == -1): 
                    return ["down0134", i]
        3:
            for i in range(6):
                if (adj_hexes_lvl[i] == -1) and \
                   (adj_hexes_lvl[i - 1] == -1) and \
                   (adj_hexes_lvl[i - 2] == -1):   
                    if adj_hexes_lvl[(i + 1) % 6] == 1 and adj_hexes_lvl[i - 3] == 1:
                        return ["down01", i - 1]
                    elif adj_hexes_lvl[(i + 1) % 6] == 1:
                        return ["down012", i - 1]
                    elif adj_hexes_lvl[i - 3] == 1:
                        return ["down012", i]
                    else:
                        return ["down0123", i]
                         
                if (adj_hexes_lvl[i] == -1) and (adj_hexes_lvl[i - 1] == -1) and \
                   (adj_hexes_lvl[i - 3] == -1):
                    return ["down014", i]
                    
                if (adj_hexes_lvl[i] == -1) and (adj_hexes_lvl[i - 1] == -1) and \
                   (adj_hexes_lvl[i - 4] == -1):
                    return ["down013", i - 1]
        4:
            for i in range(6):
                if (adj_hexes_lvl[i] == -1) and \
                   (adj_hexes_lvl[i - 1] == -1) and \
                   (adj_hexes_lvl[i - 2] == -1) and \
                   (adj_hexes_lvl[i - 3] == -1):
#                    if (adj_hexes_lvl[i - 4] > 1) and (adj_hexes_lvl[i - 6] > 1):
#                        return ["down012", i]
#                    elif (adj_hexes_lvl[i - 4] > 1):
#                        return ["down0123", i]
#                    elif (adj_hexes_lvl[i - 5] > 1):
#                        return ["down0123", i - 1]
#                    else:
                    return ["down01234", i]
            for i in range(6):
                if (adj_hexes_lvl[i] != -1) and (adj_hexes_lvl[i - 3] != -1):
                    if (adj_hexes_lvl[i] < -1):
                        return ["down0123", i + 1]
                    elif (adj_hexes_lvl[i - 3] < -1):
                        return ["down0123", i + 4]
                    elif (adj_hexes_lvl[i] < -1) and (adj_hexes_lvl[i - 3] < -1):
                        return ["down012345", 0]
                    else:
                        return ["down03", i + 1]
        5:
            for i in range(6):
                if adj_hexes_lvl[i] != -1:
                    return ["down0123", i + 4]
        6:
            return ["down012345", 0]
    return ["flat", 0]
    

func gen_hex_height_level(hex: Hex) -> int:
    var height = height_noise.get_noise_2dv(hex.to_pt())
    return int(round(height * 8))
     
func generate_hexes(trafo: Transform) -> Array:
    var _hexes_to_add: Array = []

    # TODO: for some reason assigning these values in other places
    # causes huge lag spikes. Investigate further
    #var trafo: Transform = player.get_global_transform()
    #var loc_trafo: Transform = player.get_transform()
    var player_pos: Vector2 = Vector2(trafo.origin.x, -trafo.origin.z)
    #var player_dir := Vector2(loc_trafo.basis.z.x, -loc_trafo.basis.z.z).normalized()
       
    # Tile creation
    for _iter in range(THREAD_CREATE_CNT):
        #var offset_q: int = Util.randi_range(-TILE_LOAD_RADIUS, TILE_LOAD_RADIUS)
        #var range_min := max(-TILE_LOAD_RADIUS - offset_q, -TILE_LOAD_RADIUS) as int
        #var range_max := min(TILE_LOAD_RADIUS - offset_q, TILE_LOAD_RADIUS) as int
        #var offset_r: int = Util.randi_range(range_min, range_max)
        var offset_radius: float = rand_range(0, TILE_LOAD_RADIUS * 2)
        var offset_angle: float = randf() * PI * 2
        var offset_hex: Hex = Util.hex_from_pt(Vector2(
            offset_radius * cos(offset_angle),
            offset_radius * sin(offset_angle)
        ))
        
        var player_hex: Hex = Util.hex_from_pt(player_pos / HEX_RADIUS)
        var hex: Hex = Hex.new(player_hex.q + offset_hex.q, player_hex.r + offset_hex.r)
        
        var q_found: bool = tiles.has(hex.q)
        var r_found: bool = q_found and tiles[hex.q].has(hex.r)
        
#            var hex_pos: Vector2 = hex.to_pt() * HEX_RADIUS
#            var dist_to_player_sqr: float = hex_pos.distance_squared_to(player_pos)
#            var hex_dir := hex_pos - player_pos
#            var dot_prod := hex_dir.dot(player_dir)
#
        if not (q_found and r_found):# \
            #and not ((dist_to_player_sqr > MIN_RADIUS * MIN_RADIUS) and dot_prod > 0):
            var already_in_queue: bool = false
            for i in range(_hexes_to_add.size()):
                var other_hex: Hex = _hexes_to_add[i]["hex"]
                if hex.is_equal(other_hex):
                    already_in_queue = true
                    break
                            
            if not already_in_queue:                 
                var new_pt: Vector3
                new_pt.x = hex.to_pt().x * HEX_RADIUS
                new_pt.y = hex.to_pt().y * HEX_RADIUS
                new_pt.z = gen_hex_height_level(hex) * 0.75
                
                var hex_model: Array = gen_hex_model(hex)
                var new_scene: PackedScene = tile_scenes[hex_model[0]]
                var rotation: int = hex_model[1]
                
                _hexes_to_add.append({
                    "hex": hex,
                    "pt": new_pt,
                    "scene": new_scene,
                    "rot": rotation,
                })
                                    
    call_deferred("_receive_gen_results")
    return _hexes_to_add
   
 
func cleanup_hexes(trafo: Transform) -> Array:
    var _hexes_to_remove: Array = []
    var player_pos: Vector2 = Vector2(trafo.origin.x, -trafo.origin.z)
        
    for _iter in range(THREAD_DELETE_CNT):
        # Tile cleanup
        if not tiles.empty():
            var hex_q = tiles.keys()[randi() % tiles.size()]
            var hex_r = tiles[hex_q].keys()[randi() % tiles[hex_q].size()]
            
            var hex: Hex = Hex.new(hex_q, hex_r)
            var hex_pos: Vector2 = hex.to_pt() * HEX_RADIUS
            var dist_to_player_sqr: float = hex_pos.distance_squared_to(player_pos)
            
            #var hex_dir := hex_pos - player_pos
            #var dot_prod := hex_dir.dot(player_dir)

            if (dist_to_player_sqr > MAX_RADIUS * MAX_RADIUS): #or \
                #((dist_to_player_sqr > MIN_RADIUS * MIN_RADIUS) and dot_prod > 0):
                var already_in_queue: bool = false
                for i in range(_hexes_to_remove.size()):
                    if hex.is_equal(_hexes_to_remove[i]):
                        already_in_queue = true
                        break
                        
                if not already_in_queue:
                    _hexes_to_remove.append(hex)
                    
    call_deferred("_receive_cleanup_results")
    return _hexes_to_remove
