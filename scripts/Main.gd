extends Node2D
## The demo arena: a faint grid drawn with _draw() as a reference floor. It gives
## your eyes something to move against, so the movement, the dash and the camera
## follow are easy to feel out. Replace it with your own level.

const GRID := 64        # spacing between grid lines, in pixels
const EXTENT := 1600    # how far the grid reaches from the origin
const LINE_COLOR := Color(1, 1, 1, 0.06)


func _draw() -> void:
	for x in range(-EXTENT, EXTENT + 1, GRID):
		draw_line(Vector2(x, -EXTENT), Vector2(x, EXTENT), LINE_COLOR, 1.0)
	for y in range(-EXTENT, EXTENT + 1, GRID):
		draw_line(Vector2(-EXTENT, y), Vector2(EXTENT, y), LINE_COLOR, 1.0)
