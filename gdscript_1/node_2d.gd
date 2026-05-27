extends Node

# ─────────────────────────────────────────────
#  CONSTANTS
# ─────────────────────────────────────────────
const LANE_WIDTH     : float = 3.0
const GRAVITY        : float = -20.0
const JUMP_FORCE     : float = 10.0
const INITIAL_SPEED  : float = 10.0
const SPEED_INCREMENT: float = 0.5
const TILE_LENGTH    : float = 20.0
const TILE_COUNT     : int   = 6
const SPAWN_INTERVAL : float = 2.2

# ─────────────────────────────────────────────
#  VARIABLES
# ─────────────────────────────────────────────
var velocity     : Vector3 = Vector3.ZERO
var current_lane : int     = 0
var run_speed    : float   = INITIAL_SPEED
var score        : int     = 0
var is_alive     : bool    = true
var speed_timer  : float   = 0.0
var spawn_timer  : float   = 0.0

var tiles     : Array = []
var obstacles : Array = []

@onready var player_mesh  = $PlayerMesh
@onready var score_label  = $HUD/ScoreLabel
@onready var speed_label  = $HUD/SpeedLabel

# ─────────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────────
func _ready() -> void:
	translation = Vector3(lane_to_x(current_lane), 1.0, 0.0)
	build_track()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	handle_input()
	apply_gravity(delta)
	move_forward(delta)
	accumulate_score(delta)
	increase_speed(delta)
	scroll_world(delta)
	tick_spawner(delta)
	update_hud()

# ─────────────────────────────────────────────
#  PLAYER FUNCTIONS
# ─────────────────────────────────────────────

# Converts lane index (-1, 0, 1) to world X position
func lane_to_x(lane: int) -> float:
	return lane * LANE_WIDTH


# Reads input and triggers lane changes or jump
func handle_input() -> void:
	if Input.is_action_just_pressed("ui_left"):
		change_lane(-1)
	elif Input.is_action_just_pressed("ui_right"):
		change_lane(1)
	elif Input.is_action_just_pressed("ui_accept") and is_on_floor():
		jump()


# Shifts player one lane in the given direction and tilts the mesh
func change_lane(direction: int) -> void:
	current_lane = clamp(current_lane + direction, -1, 1)
	translation.x = lane_to_x(current_lane)
	player_mesh.rotation_degrees.z = -direction * 15.0


# Gives the player an upward velocity impulse
func jump() -> void:
	velocity.y = JUMP_FORCE
	player_mesh.rotation_degrees.x = -20.0


# Pulls the player down and resets mesh tilt once grounded
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
		player_mesh.rotation_degrees.x = lerp(player_mesh.rotation_degrees.x, 0.0, 0.15)
		player_mesh.rotation_degrees.z = lerp(player_mesh.rotation_degrees.z, 0.0, 0.15)


# Propels the player forward and applies accumulated velocity
func move_forward(delta: float) -> void:
	var motion : Vector3 = Vector3(0.0, velocity.y, -run_speed)
	velocity = move_and_slide(motion, Vector3.UP)


# Adds points each frame based on current speed
func accumulate_score(delta: float) -> void:
	score += int(run_speed * delta)


# Raises run speed every 5 seconds
func increase_speed(delta: float) -> void:
	speed_timer += delta
	if speed_timer >= 5.0:
		speed_timer = 0.0
		run_speed += SPEED_INCREMENT


# Writes score and speed to the HUD
func update_hud() -> void:
	score_label.text = "Score: %d" % score
	speed_label.text = "Speed: %.1f" % run_speed


# Stops movement and spins the mesh to signal death
func die() -> void:
	if not is_alive:
		return
	is_alive  = false
	run_speed = 0.0
	score_label.text = "GAME OVER  |  Score: %d" % score
	spin_on_death()


# Rotates the player mesh 360° on Y when the player dies
func spin_on_death() -> void:
	var tween : Tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(
		player_mesh, "rotation_degrees:y",
		0.0, 360.0, 0.6,
		Tween.TRANS_BACK, Tween.EASE_OUT
	)
	tween.start()

# ─────────────────────────────────────────────
#  TRACK FUNCTIONS
# ─────────────────────────────────────────────

# Spawns the initial pool of track tiles lined up ahead of the player
func build_track() -> void:
	for i in range(TILE_COUNT):
		var tile        : CSGBox  = CSGBox.new()
		tile.width      = LANE_WIDTH * 3.0
		tile.height     = 0.3
		tile.depth      = TILE_LENGTH
		tile.translation = Vector3(0.0, -0.15, -i * TILE_LENGTH)
		add_child(tile)
		tiles.append(tile)


# Scrolls all tiles and obstacles forward; recycles tiles that pass the camera
func scroll_world(delta: float) -> void:
	var step : float = run_speed * delta

	for tile in tiles:
		tile.translation.z += step
		if tile.translation.z > TILE_LENGTH:
			tile.translation.z = find_last_tile_z() - TILE_LENGTH

	for obs in obstacles:
		obs.translation.z += step
		obs.rotation_degrees.y += 90.0 * delta   # spin for visual flair


# Returns the smallest (farthest ahead) Z among all track tiles
func find_last_tile_z() -> float:
	var min_z : float = 0.0
	for tile in tiles:
		if tile.translation.z < min_z:
			min_z = tile.translation.z
	return min_z

# ─────────────────────────────────────────────
#  OBSTACLE FUNCTIONS
# ─────────────────────────────────────────────

# Counts down and spawns a new obstacle when the interval elapses
func tick_spawner(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		spawn_obstacle()


# Instances a CSGBox obstacle at a random lane far ahead of the player
func spawn_obstacle() -> void:
	var lane : int   = int(rand_range(-1, 2))
	var obs  : CSGBox = CSGBox.new()
	obs.width        = 1.5
	obs.height       = 1.5
	obs.depth        = 1.5
	obs.translation  = Vector3(lane_to_x(lane), 0.75, -60.0)
	add_child(obs)
	obstacles.append(obs)
	check_collisions()


# Checks every obstacle against the player and calls die() on overlap
func check_collisions() -> void:
	var dead_obs : Array = []
	for obs in obstacles:
		if obs.translation.z > 2.0:
			dead_obs.append(obs)
			continue
		var dist : float = (obs.translation - translation).length()
		if dist < 1.5:
			die()
	for obs in dead_obs:
		obstacles.erase(obs)
		obs.queue_free()
