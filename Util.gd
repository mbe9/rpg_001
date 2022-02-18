class_name Util

const SQRT_3 = 1.732050807568877

static func randi_range(start:int, end:int) -> int:
    var range_size: int = end - start
    return randi() % (range_size + 1) + start

static func hex_from_pt(pt: Vector2) -> Hex:
    var q_f = 2.0/3.0 * pt.x
    var r_f = (-1.0/3.0 * pt.x + SQRT_3/3.0 * pt.y)
    
    var s_f = -q_f - r_f
    var q_r = round(q_f)
    var r_r = round(r_f)
    var s_r = round(s_f)

    var q_diff = abs(q_r - q_f)
    var r_diff = abs(r_r - r_f)
    var s_diff = abs(s_r - s_f)

    if q_diff > r_diff and q_diff > s_diff:
        q_r = -r_r - s_r
    elif r_diff > s_diff:
        r_r = -q_r - s_r
    else:
        s_r = -q_r - r_r
        
    return Hex.new(q_f, r_f)

static func get_hex_area_count(size: int) -> int:
    if size > 0:
        return 1 + 3 * (size - 1) * size
    else:
        return 0
