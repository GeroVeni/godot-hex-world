extends Node2D

var startDragging := false

var camera: Camera2D
var grid: Grid
var debugBounds: Polygon2D

func _init():
  randomize()

func _ready():
  camera = get_node("Camera2D")
  grid = $Grid
  debugBounds = $Polygon2D
  getCameraBounds()

func getCameraBounds():
  var viewportRect = get_viewport().get_visible_rect()
  var sz: Vector2 = viewportRect.size * camera.zoom
  debugBounds.position = camera.position
  debugBounds.scale = sz / 200.0
  grid.setBoundsRect(Rect2(camera.position - sz / 2, sz))

func _unhandled_input(event):
  if event is InputEventMouseButton:
    if event.button_index == BUTTON_RIGHT:
      startDragging = event.pressed
    elif event.button_index == BUTTON_WHEEL_UP && event.pressed:
      var amount = 1
      if (event.factor != 0): amount = event.factor
      camera.zoom *= pow(1.2, amount)
      var cameraZoom = clamp(camera.zoom.x, 0.5, 4)
      camera.zoom = Vector2(cameraZoom, cameraZoom)
      getCameraBounds()
    elif event.button_index == BUTTON_WHEEL_DOWN && event.pressed:
      var amount = -1
      if (event.factor != 0): amount = -event.factor
      camera.zoom *= pow(1.2, amount)
      var cameraZoom = clamp(camera.zoom.x, 0.25, 4)
      camera.zoom = Vector2(cameraZoom, cameraZoom)
      getCameraBounds()
  elif event is InputEventMouseMotion:
    if (startDragging):
      camera.position -= camera.zoom.x * event.relative
      getCameraBounds()
