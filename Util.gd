class_name Util

const SQRT_3: float = 1.732050807568877
const ONE_THIRD: float = 0.333333333333

static func world_to_2d_pos(vec: Vector3) -> Vector2:
    return Vector2(vec.x, -vec.z)

static func get_hexes_in_radius(radius: int) -> Array:
    var hexes: Array = []
    
    for dq in range(-radius, radius + 1):
        for dr in range(-radius, radius + 1):
            if abs(dq + dr) <= radius:
                hexes.append(Hex.new(dq, dr))
    return hexes            

static func get_adj_hexes(hex: Hex) -> Array:
    return [
        Hex.new(hex.q + 0, hex.r - 1),
        Hex.new(hex.q + 1, hex.r - 1),
        Hex.new(hex.q + 1, hex.r + 0),
        Hex.new(hex.q + 0, hex.r + 1),
        Hex.new(hex.q - 1, hex.r + 1),
        Hex.new(hex.q - 1, hex.r + 0),
    ]

static func randi_range(start:int, end:int) -> int:
    var range_size: int = end - start
    return randi() % (range_size + 1) + start

static func hex_from_pt(pt: Vector2) -> Hex:
    var vec_float: Vector3 = Vector3(
        2.0 * ONE_THIRD * pt.x,
        -ONE_THIRD * pt.x + SQRT_3 * ONE_THIRD * pt.y, 
        0
    )
    vec_float.z = - vec_float.x - vec_float.y

    var vec_round: Vector3 = vec_float.round()
    var vec_diff: Vector3 = (vec_round - vec_float).abs()

    if vec_diff.x > vec_diff.y and vec_diff.x > vec_diff.z:
        vec_round.x = - vec_round.y - vec_round.z
    elif vec_diff.y > vec_diff.z:
        vec_round.y = -vec_round.x - vec_round.z
    else:
        vec_round.z = -vec_round.x - vec_round.y

    return Hex.new(vec_float.x, vec_float.y)

static func get_hex_area_count(size: int) -> int:
    if size > 0:
        return 1 + 3 * (size - 1) * size
    else:
        return 0
