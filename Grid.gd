tool

extends Node2D
class_name Grid

export var defaultTileColor : Color setget defaultTileColorSet
func defaultTileColorSet(value):
  defaultTileColor = value
  if Engine.editor_hint: drawTiles()

export var highlightTileColor : Color setget highlightTileColorSet
func highlightTileColorSet(value):
  highlightTileColor = value
  if Engine.editor_hint: drawTiles()

export var groundColor : Color setget groundColorSet
func groundColorSet(value):
  groundColor = value
  if Engine.editor_hint: drawTiles()

export var mountainColor : Color setget mountainColorSet
func mountainColorSet(value):
  mountainColor = value
  if Engine.editor_hint: drawTiles()

export var shallowSeaTileColor : Color setget shallowSeaTileColorSet
func shallowSeaTileColorSet(value):
  shallowSeaTileColor = value
  if Engine.editor_hint: drawTiles()

export var deepSeaTileColor : Color setget deepSeaTileColorSet
func deepSeaTileColorSet(value):
  deepSeaTileColor = value
  if Engine.editor_hint: drawTiles()

export var maxRadius : int setget maxRadiusSet
func maxRadiusSet(value):
  maxRadius = value
  if Engine.editor_hint: reset()

export var curve: Curve setget curveSet
func curveSet(value):
  curve = value
  if Engine.editor_hint: drawTiles()

export var size: float setget sizeSet
func sizeSet(value):
  size = value
  if Engine.editor_hint: reset()

export var spacing: float setget spacingSet
func spacingSet(value):
  spacing = value
  if Engine.editor_hint: reset()

export var noiseSeed: int setget noiseSeedSet
func noiseSeedSet(value):
  noiseSeed = value
  if Engine.editor_hint: drawTiles()

export var octaves: int = 4 setget octavesSet
func octavesSet(value):
  octaves = value
  if Engine.editor_hint: drawTiles()

export var period: float = 20 setget periodSet
func periodSet(value):
  period = value
  if Engine.editor_hint: drawTiles()

export var persistence: float = 0.8 setget persistenceSet
func persistenceSet(value):
  persistence = value
  if Engine.editor_hint: drawTiles()

export var lacunarity: float = 2 setget lacunaritySet
func lacunaritySet(value):
  lacunarity = value
  if Engine.editor_hint: drawTiles()

var noise : OpenSimplexNoise = OpenSimplexNoise.new()

var tiles : Dictionary
var highlightedTiles: Array
var tilePool: Array
# var maxTilePoolSize := 360
var maxTilePoolSize := 1500

const tileHeight = 2 * 86.60255;

const Tile = preload("res://PolyTile.tscn")
var hc := HexCoords.new()

# Returns the color of the tile based on its `altitude`, which can be a value in
# the range `[-1, 1]`, `-1` representing the deepest part and `1` representing
# the highest.
func getTileColor(altitude: float) -> Color:
  var seaThreshold = 0.0
  if (altitude <= seaThreshold):
    return shallowSeaTileColor.linear_interpolate(deepSeaTileColor, -altitude)
  return groundColor.linear_interpolate(mountainColor, altitude)

func drawTile(tile: Vector2):
  var altitude = noise.get_noise_2dv(hc.fromHexCoords(tile))
  if curve && curve.has_method("interpolate"):
    tiles[tile].self_modulate = getTileColor(curve.interpolate(altitude * 0.5 + 0.5))
  else:
    tiles[tile].self_modulate = getTileColor(altitude)

func instantiateTile():
  var tile := Tile.instance()
  var spriteScale := size / tileHeight;
  tile.set_rotation(PI / 2)
  tile.scale = Vector2(spriteScale, spriteScale)
  return tile

func spawnTile(tilePos: Vector2):
  var pos = hc.tileToWorldCoords(tilePos)
  var tile = tilePool.pop_back()
  if tile == null:
    print("spawning new tile, total: %d" % tiles.size())
    tile = instantiateTile()
  tile.position = pos
  add_child(tile)
  tiles[tilePos] = tile
  drawTile(tilePos)

func despawnTile(tile: Vector2):
  remove_child(tiles[tile])
  tilePool.push_back(tiles[tile])
  tiles.erase(tile)

func _ready():
  resetNoise()
  hc.worldScale = size + spacing
  for i in maxTilePoolSize:
    tilePool.push_back(instantiateTile())
  reset()

func _unhandled_input(event):
  if Engine.editor_hint: return
  if event is InputEventMouseMotion:
    var mousePos = get_local_mouse_position()
    var tile = hc.getNearestTile(mousePos)
    resetHighlightedTiles()
    if inBounds(tile):
      highlightedTiles = [tile]
    else:
      highlightedTiles = []
    highlightTiles()

var boundsRect: Rect2
func setBoundsRect(rect: Rect2):
  boundsRect = rect
  despawnOutOfBoundTiles()
  spawnInBoundTiles()

func despawnOutOfBoundTiles():
  for tile in tiles.keys():
    if !boundsRect.has_point(hc.tileToWorldCoords(tile)):
      despawnTile(tile)

func spawnInBoundTiles():
  for tile in hc.getBoundedHexRegion(boundsRect):
    if !tiles.has(tile):
      spawnTile(tile)

func inBounds(tile: Vector2) -> bool:
  if boundsRect.has_no_area(): return false
  return boundsRect.has_point(hc.tileToWorldCoords(tile))

func highlightTiles():
  for tile in highlightedTiles:
    if !inBounds(tile) || !tiles.has(tile): continue
    var t = tiles[tile]
    t.self_modulate = t.self_modulate.linear_interpolate(Color.white, 0.2)

func resetHighlightedTiles():
  for tile in highlightedTiles:
    if !inBounds(tile) || !tiles.has(tile): continue
    drawTile(tile)

func resetNoise():
  noise.seed = noiseSeed
  if !Engine.editor_hint: noise.seed = randi()
  noise.octaves = octaves
  noise.persistence = persistence
  noise.period = period
  noise.lacunarity = lacunarity

func reset():
  for tile in tiles.keys():
    despawnTile(tile)

  for i in range(-maxRadius + 1, maxRadius):
    for j in range(-maxRadius + 1, maxRadius):
      if (abs(i + j) >= maxRadius):
        continue
      spawnTile(Vector2(i, j))

  print("spawned tiles")

func drawTiles():
  resetNoise()
  for i in range(-maxRadius + 1, maxRadius):
    for j in range(-maxRadius + 1, maxRadius):
      if (abs(i + j) >= maxRadius):
        continue
      drawTile(Vector2(i, j))
