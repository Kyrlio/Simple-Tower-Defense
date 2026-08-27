extends Node

## Pool sizes
const POOL_SIZE_2D: int = 36
const POOL_SIZE_UI: int = 10

## Preloaded Audio Streams
const SOUND_HOVER = preload("uid://bt1nlug800p77")
const SOUND_CLICK = preload("uid://bgj8ic7y3lh3h")
const SOUND_SELECT = preload("uid://c2t8r8q3xtutk")
const SOUND_ERROR = preload("res://assets/Sounds/UI & Menus/Error.wav")
const SOUND_NOTIFICATION = preload("res://assets/Sounds/UI & Menus/Notification.wav")

const SOUND_TOWER_PLACE = preload("res://assets/Sounds/Medieval/Equip.wav")
const SOUND_TOWER_UPGRADE = preload("res://assets/Sounds/Medieval/Weapon Upgrade.wav")

const SOUND_SHOOT_ARCHER = preload("res://assets/Sounds/Medieval/Bow Shoot.wav")
const SOUND_SHOOT_CROSSBOW = preload("res://assets/Sounds/Medieval/Metal Twang.wav")
const SOUND_SHOOT_CANNON = preload("uid://v1qi8fn6o4uf")
const SOUND_EXPLOSION_CANNON = preload("uid://0wf23p1nw7b3")
const SOUND_SHOOT_ICE = preload("res://assets/Sounds/Magic/Ice Attack.wav")
const SOUND_SHOOT_POISON = preload("res://assets/Sounds/Magic/Acid Attack.wav")
const SOUND_SHOOT_LIGHTNING = preload("res://assets/Sounds/Magic/Air Attack.wav")

const SOUND_ENEMY_HIT = preload("res://assets/Sounds/Medieval/Arrow Hit.wav")
const SOUND_ENEMY_DEATH = preload("res://assets/Sounds/Medieval/Loot Gold.wav")

const SOUND_CASTLE_HIT = preload("res://assets/Sounds/Motions and Impacts/Impact Redwood.wav")
const SOUND_GAME_OVER = preload("res://assets/Sounds/Jingles & Stingers/Game Over.wav")

# Audio Players Pools
var _players_2d: Array[AudioStreamPlayer2D] = []
var _pool_idx_2d: int = 0

var _players_ui: Array[AudioStreamPlayer] = []
var _pool_idx_ui: int = 0

# Anti-spam frame rate limiters
var _last_hit_frame: int = -1
var _hits_this_frame: int = 0
const MAX_HITS_PER_FRAME: int = 4

var _last_death_frame: int = -1
var _deaths_this_frame: int = 0
const MAX_DEATHS_PER_FRAME: int = 3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_pool_2d()
	_init_pool_ui()


func _init_pool_2d() -> void:
	for i in range(POOL_SIZE_2D):
		var player := AudioStreamPlayer2D.new()
		player.name = "SpatialPlayer_%d" % i
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.max_polyphony = 1
		player.panning_strength = 1.0
		player.bus = "SFX"
		add_child(player)
		_players_2d.append(player)


func _init_pool_ui() -> void:
	for i in range(POOL_SIZE_UI):
		var player := AudioStreamPlayer.new()
		player.name = "UIPlayer_%d" % i
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.max_polyphony = 1
		player.bus = "UI"
		add_child(player)
		_players_ui.append(player)


## --- Audio Bus Management ---

func set_bus_volume(bus_name: String, linear_val: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		if linear_val <= 0.001:
			AudioServer.set_bus_mute(idx, true)
		else:
			AudioServer.set_bus_mute(idx, false)
			AudioServer.set_bus_volume_db(idx, linear_to_db(linear_val))


func get_bus_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		if AudioServer.is_bus_mute(idx):
			return 0.0
		return db_to_linear(AudioServer.get_bus_volume_db(idx))
	return 1.0


func _get_player_2d() -> AudioStreamPlayer2D:
	# Check for available (not playing) player first
	for player in _players_2d:
		if not player.playing:
			return player
	
	# Fallback to round-robin recycling if all are busy
	var player = _players_2d[_pool_idx_2d]
	_pool_idx_2d = (_pool_idx_2d + 1) % POOL_SIZE_2D
	return player


func _get_player_ui() -> AudioStreamPlayer:
	for player in _players_ui:
		if not player.playing:
			return player
	
	var player = _players_ui[_pool_idx_ui]
	_pool_idx_ui = (_pool_idx_ui + 1) % POOL_SIZE_UI
	return player


## --- Generic Play Functions ---

func play_spatial(
	stream: AudioStream,
	global_pos: Vector2,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0,
	max_distance: float = 350.0,
	attenuation: float = 2.0
) -> void:
	if not stream:
		return
		
	var player := _get_player_2d()
	player.stream = stream
	player.global_position = global_pos
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = max_distance
	player.attenuation = attenuation
	player.play()


func play_ui(
	stream: AudioStream,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0
) -> void:
	if not stream:
		return
		
	var player := _get_player_ui()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


## --- Specialized Gameplay Sounds ---

## Hit sound is very frequent: low volume, strong attenuation, random pitch, frame throttled.
func play_hit(global_pos: Vector2) -> void:
	var cur_frame := Engine.get_process_frames()
	if cur_frame == _last_hit_frame:
		_hits_this_frame += 1
		if _hits_this_frame > MAX_HITS_PER_FRAME:
			return
	else:
		_last_hit_frame = cur_frame
		_hits_this_frame = 1
	
	var pitch := randf_range(0.88, 1.15)
	# Very subtle volume (-15 dB), max_distance 240px (close to viewport center)
	play_spatial(SOUND_ENEMY_HIT, global_pos, -15.0, pitch, 240.0, 2.2)


func play_enemy_death(global_pos: Vector2) -> void:
	var cur_frame := Engine.get_process_frames()
	if cur_frame == _last_death_frame:
		_deaths_this_frame += 1
		if _deaths_this_frame > MAX_DEATHS_PER_FRAME:
			return
	else:
		_last_death_frame = cur_frame
		_deaths_this_frame = 1
		
	var pitch := randf_range(0.95, 1.15)
	play_spatial(SOUND_ENEMY_DEATH, global_pos, -10.0, pitch, 300.0, 1.8)


func play_shoot(tower_type: String, global_pos: Vector2) -> void:
	match tower_type:
		"archer":
			play_spatial(SOUND_SHOOT_ARCHER, global_pos, -8.0, randf_range(0.94, 1.08), 340.0, 1.8)
		"crossbow":
			play_spatial(SOUND_SHOOT_CROSSBOW, global_pos, -7.0, randf_range(0.92, 1.08), 340.0, 1.8)
		"cannon":
			play_spatial(SOUND_SHOOT_CANNON, global_pos, -6.0, randf_range(0.95, 1.05), 380.0, 1.6)
		"ice_wizard":
			play_spatial(SOUND_SHOOT_ICE, global_pos, -7.5, randf_range(0.94, 1.08), 340.0, 1.8)
		"poison_wizard":
			play_spatial(SOUND_SHOOT_POISON, global_pos, -7.5, randf_range(0.94, 1.08), 340.0, 1.8)
		"lightning":
			play_spatial(SOUND_SHOOT_LIGHTNING, global_pos, -8.0, randf_range(0.95, 1.12), 350.0, 1.8)
		_:
			play_spatial(SOUND_SHOOT_ARCHER, global_pos, -8.0, randf_range(0.95, 1.05), 340.0, 1.8)


func play_explosion(global_pos: Vector2) -> void:
	play_spatial(SOUND_EXPLOSION_CANNON, global_pos, -8.0, randf_range(0.90, 1.10), 420.0, 1.6)


func play_tower_placed(global_pos: Vector2) -> void:
	play_spatial(SOUND_TOWER_PLACE, global_pos, -5.0, randf_range(0.96, 1.04), 400.0, 1.5)


func play_tower_upgraded(global_pos: Vector2) -> void:
	play_spatial(SOUND_TOWER_UPGRADE, global_pos, -4.0, randf_range(0.8, 1.1), 400.0, 1.5)


func play_castle_hit(global_pos: Vector2) -> void:
	play_spatial(SOUND_CASTLE_HIT, global_pos, -4.0, randf_range(0.94, 1.06), 500.0, 1.4)


func play_game_over() -> void:
	play_ui(SOUND_GAME_OVER, -3.0, 1.0)


func play_wave_warning() -> void:
	play_ui(SOUND_NOTIFICATION, -5.0, 1.0)


## --- UI Sounds ---

func play_ui_hover() -> void:
	play_ui(SOUND_HOVER, -12.0, randf_range(0.9, 1.05))


func play_ui_click() -> void:
	play_ui(SOUND_CLICK, -12.0, randf_range(0.9, 1.04))


func play_ui_select() -> void:
	play_ui(SOUND_SELECT, -12.0, randf_range(0.9, 1.05))


func play_ui_error() -> void:
	play_ui(SOUND_ERROR, -6.0, 1.0)
