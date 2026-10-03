class_name PlayerController
extends CharacterBody2D
## A top-down player: 8-direction movement, a weapon pivot that aims at the
## mouse, and a dash with i-frames, an afterimage trail and a little squash and
## stretch. Everything here is about how it feels to drive the character.

# --- Movement tuning (exported so you can feel out the numbers in the Inspector) ---
@export var move_speed: float = 180.0
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.6

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon: Node2D = $WeaponPivot

# --- Dash state ---
var _is_dashing := false
var _dash_timer := 0.0
var _dash_cd_timer := 0.0
var _dash_dir := Vector2.RIGHT
var _dash_img_timer := 0.0
# is_invincible is a plain flag so you can SEE i-frames working (the sprite tints
# blue while dashing). Have your damage code skip hits while it is true.
var is_invincible := false

# --- Juice state (no leaking tweens - bob is done procedurally with sin()) ---
var _base_sprite_scale := Vector2.ONE
var _bob_time := 0.0
var _was_moving := false


func _ready() -> void:
	# Announce ourselves so the camera / other systems can find the player.
	# The "player" group is set on the root node in Player.tscn.
	GameManager.register_player(self)
	_base_sprite_scale = sprite.scale


func _physics_process(delta: float) -> void:
	_update_aim()        # point the weapon at the mouse, flip the body
	_update_dash(delta)  # tick the cooldown, start or end a dash

	var input := Vector2.ZERO
	if _is_dashing:
		# During a dash we ignore steering: fixed speed in the locked dash dir.
		velocity = _dash_dir * dash_speed
		_emit_afterimages(delta)
	else:
		input = _get_move_input()
		velocity = input * move_speed

	move_and_slide()
	_update_body_juice(delta, input.length() > 0.1)


# Read the four named move actions into a vector, and clamp diagonals so moving
# diagonally is not faster than moving straight.
func _get_move_input() -> Vector2:
	var v := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	return v.normalized() if v.length() > 1.0 else v


# Point the weapon pivot at the mouse every frame, and flip the body to face it.
func _update_aim() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	weapon.rotation = to_mouse.angle()
	if absf(to_mouse.x) > 4.0:
		sprite.flip_h = to_mouse.x < 0.0


# --- Dash --------------------------------------------------------------
func _update_dash(delta: float) -> void:
	if _dash_cd_timer > 0.0:
		_dash_cd_timer -= delta

	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()
		return

	if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0:
		_start_dash()


func _start_dash() -> void:
	# Dash toward the movement stick if we are moving, otherwise toward the mouse.
	var input := _get_move_input()
	if input.length() > 0.1:
		_dash_dir = input.normalized()
	else:
		var to_mouse := get_global_mouse_position() - global_position
		_dash_dir = to_mouse.normalized() if to_mouse.length() > 0.01 else Vector2.RIGHT
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cd_timer = dash_cooldown
	_dash_img_timer = 0.0
	is_invincible = true  # i-frames: your damage code should ignore hits mid-dash
	sprite.modulate = Color(0.7, 0.9, 1.0)
	# Anticipation stretch + a ground ring so the dash reads with weight.
	Juice.stretch(sprite, _base_sprite_scale, 0.25, 0.16)
	Juice.ring(get_tree().current_scene, global_position, Color(0.7, 0.9, 1.0, 0.7), 26.0, 0.3)


func _end_dash() -> void:
	_is_dashing = false
	is_invincible = false
	sprite.modulate = Color.WHITE
	Juice.squash(sprite, _base_sprite_scale, 0.2, 0.22)  # plant the landing


# Drop fading ghost copies along the dash path for a motion trail.
func _emit_afterimages(delta: float) -> void:
	_dash_img_timer -= delta
	if _dash_img_timer <= 0.0:
		_dash_img_timer = 0.025
		Juice.afterimage(get_tree().current_scene, sprite, Color(0.6, 0.85, 1.0, 0.45), 0.22)


func get_dash_ratio() -> float:
	# 1.0 = ready, 0.0 = just used. Handy for a cooldown bar later.
	if dash_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - _dash_cd_timer / dash_cooldown, 0.0, 1.0)


# Walk/idle bob and a squash when you stop. Pure sprite-local motion, no tweens.
func _update_body_juice(delta: float, moving: bool) -> void:
	if _is_dashing:
		return
	var freq := 13.0 if moving else 3.0
	var amp := 1.6 if moving else 0.8
	_bob_time += delta * freq
	sprite.position.y = sin(_bob_time) * amp
	if _was_moving and not moving:
		Juice.squash(sprite, _base_sprite_scale, 0.18, 0.2)
	_was_moving = moving
