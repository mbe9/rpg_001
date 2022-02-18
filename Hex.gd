class_name Hex

const SQRT_3 = 1.732050807568877

var q: int
var r: int

func _init(q, r):
    self.q = q
    self.r = r
    
func is_equal(other: Hex) -> bool:
    return self.q == other.q and self.r == other.r
    
func to_pt() -> Vector2:
    var x = 3.0/2.0 * self.q
    var y = SQRT_3/2.0 * self.q + SQRT_3 * self.r
    return Vector2(x, y)
    
static func random_hex(max_dist: int):
    var rnd_q = int(round(rand_range(-max_dist, max_dist)))
    
    return load("res://Hex.gd").new(rnd_q, 0)
    

