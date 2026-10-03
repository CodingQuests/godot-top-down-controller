class_name Juice
extends RefCounted
## Small static helpers for "game feel": squash and stretch, afterimages and
## rings. Static, so any script can call Juice.squash(...) without a node in the
## scene, and every effect cleans itself up when it finishes.


## Quick impact squash: snaps `node` to a wider, shorter scale, then springs back
## to `base_scale`. Reads as a recoil or an impact deformation on a hit or a stop.
static func squash(node: Node2D, base_scale: Vector2, amount: float = 0.35, duration: float = 0.22) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.scale = Vector2(base_scale.x * (1.0 + amount), base_scale.y * (1.0 - amount))
	var tw := node.create_tween()
	tw.tween_property(node, "scale", base_scale, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Stretch the other way (taller and thinner) before springing back. Good for a
## launch or dash anticipation.
static func stretch(node: Node2D, base_scale: Vector2, amount: float = 0.3, duration: float = 0.2) -> void:
	squash(node, base_scale, -amount, duration)


## Drop a fading ghost copy of `sprite` at its current transform. String several
## together along a dash for a motion trail.
static func afterimage(world: Node, sprite: Sprite2D, tint: Color = Color(0.7, 0.9, 1.0, 0.5), duration: float = 0.25) -> void:
	if world == null or not is_instance_valid(world) or sprite == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	ghost.global_scale = sprite.global_scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = tint
	ghost.z_index = sprite.z_index - 1
	world.add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, duration)
	tw.tween_callback(ghost.queue_free)


## Expanding, fading ring outline. Good for a dash launch, a spawn telegraph or a
## big impact.
##
## The ring grows by rebuilding its points, not by scaling the node: scaling a
## Line2D scales its width too, and a 2px line scaled 26x is a filled disc.
static func ring(world: Node, pos: Vector2, color: Color = Color.WHITE, radius: float = 28.0, duration: float = 0.35, width: float = 2.0) -> void:
	if world == null or not is_instance_valid(world):
		return
	var line := Line2D.new()
	line.closed = true
	line.points = _circle_points(radius * 0.35, 24)
	line.width = width
	line.default_color = color
	line.global_position = pos
	line.z_index = 6
	world.add_child(line)
	var grow := func(r: float) -> void:
		line.points = _circle_points(r, 24)
	var tw := line.create_tween()
	tw.set_parallel(true)
	tw.tween_method(grow, radius * 0.35, radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(line, "modulate:a", 0.0, duration)
	tw.chain().tween_callback(line.queue_free)


# Points of a circle (radius `r`) as a PackedVector2Array, used by ring().
static func _circle_points(r: float, steps: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := TAU * float(i) / steps
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts
