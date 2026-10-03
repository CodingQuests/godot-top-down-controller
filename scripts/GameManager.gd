extends Node
## GameManager (autoload singleton).
##
## The "glue" every system reaches by name. Here it does two jobs: remember who
## the player and camera are, and forward a screen-shake request to the camera,
## so any script can call GameManager.shake_camera(0.4) without holding a
## reference to the camera. Grow it with whatever your game needs globally.

var player: Node = null
var camera: Node = null

## Called by the player in _ready() so any system can find it later.
func register_player(p: Node) -> void:
	player = p

## Called by the camera in _ready() so shake requests have somewhere to go.
func register_camera(c: Node) -> void:
	camera = c

## Shake the screen. `trauma` 0..1 - small taps barely wobble, big hits kick.
func shake_camera(trauma: float) -> void:
	if camera and is_instance_valid(camera) and camera.has_method("add_trauma"):
		camera.add_trauma(trauma)
