class_name HexCoords

export var worldScale := 1.0

const e1 := Vector2(1, 0)
var e2 := e1.rotated(PI / 3)
var fromHexTransform := Transform2D(e1, e2, Vector2.ZERO)
var toHexTransform := fromHexTransform.affine_inverse()

class BoundedHexRegion:
  var qMin: Vector2
  var qMax: Vector2

  var yMin: int
  var yMax: int
  var xMin: int
  var xMax: int
  var currentY: int
  var currentX: int

  func _init(p_qMin: Vector2, p_qMax: Vector2):
    self.qMin = p_qMin
    self.qMax = p_qMax
    self.yMin = int(floor(qMin.y))
    self.yMax = int(ceil(qMax.y))

  func getXMin(y: float) -> int:
    return int(floor(qMin.x - (y - qMin.y) / 2.0))

  func getXMax(y: float) -> int:
    return int(ceil(qMax.x - (y - qMax.y) / 2.0))

  func hasPoint(point: Vector2):
    if point.y < yMin || point.y > yMax: return false
    return getXMin(point.y) <= point.x && point.x <= getXMax(point.y)

  func setCurrentY(y: int):
    currentY = y
    xMin = getXMin(y)
    xMax = getXMax(y)
    currentX = xMin

  func shouldContinue():
    return currentY <= yMax

  func _iter_init(_arg):
    setCurrentY(yMin)
    return shouldContinue()

  func _iter_next(_arg):
    currentX += 1
    if currentX > xMax:
      setCurrentY(currentY + 1)
    return shouldContinue()

  func _iter_get(_arg):
    return Vector2(currentX, currentY)

func getBoundedHexRegion(rect: Rect2) -> BoundedHexRegion:
  return BoundedHexRegion.new(self.worldToTileCoords(rect.position),
    self.worldToTileCoords(rect.end))

func fromHexCoords(coords: Vector2) -> Vector2:
  return fromHexTransform * coords

func toHexCoords(coords: Vector2) -> Vector2:
  return toHexTransform * coords

func tileToWorldCoords(tile: Vector2) -> Vector2:
  return fromHexCoords(tile) * worldScale

func worldToTileCoords(pos: Vector2) -> Vector2:
  return toHexCoords(pos) / worldScale

func getNearestTile(pos: Vector2) -> Vector2:
  var hexCoords = worldToTileCoords(pos)
  var c1 = hexCoords.floor()
  var c2 = tileToWorldCoords(c1 + Vector2(0, 1))
  var c3 = tileToWorldCoords(c1 + Vector2(1, 0))
  var c4 = tileToWorldCoords(c1 + Vector2(1, 1))
  var closest = tileToWorldCoords(c1)
  for c in [c2, c3, c4]:
    if pos.distance_squared_to(c) < pos.distance_squared_to(closest):
      closest = c
  return worldToTileCoords(closest).round()
