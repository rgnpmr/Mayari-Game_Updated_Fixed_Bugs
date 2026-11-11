extends Node

const PLAYER = preload("res://player/Sprites/player2.tscn")
const INVENTORY_DATA : InventoryData = preload("res://GUI/pause_menu/inventory/player_inventory.tres")

signal camera_shook( trauma : float )
signal interact_pressed
signal player_leveled_up

var interact_handled : bool = true
var player : Player
var player_spawned : bool = false
var pending_new_game_spawn : bool = false 

var level_requirements = [ 0, 100, 200, 400, 500]

func add_player_instance() -> void:
	if player != null:
		return
	player = PLAYER.instantiate()
	add_child( player )
	player.visible = false   # NEW - stay hidden until placed into a real scene
	player_spawned = true
	pass

func set_health( hp: int, max_hp : int ) -> void:
	player.max_hp = max_hp
	player.hp = hp
	player.update_hp( 0 )

func reward_xp(_xp : int ) -> void:
	player.xp += _xp
	check_forlevel_advance()

func check_forlevel_advance() -> void:
	if player.level >= level_requirements.size():
		return
	if player.xp >= level_requirements[ player.level ]:
		player.level += 1
		player.attack += 1
		player.defense += 1
		player_leveled_up.emit()
		check_forlevel_advance()
	pass

func set_player_position( _new_pos : Vector2 ) -> void:
	player.global_position = _new_pos
	pass

func set_as_parent( _p : Node2D ) -> void:
	if player == null:
		add_player_instance()
	if player.get_parent():
		player.get_parent().remove_child( player )
	_p.add_child( player )
	player.visible = true   # NEW - now safe to show, it's in a real level

func unparent_player( _p : Node2D ) -> void:
	_p.remove_child( player )

func interact() -> void:
	interact_handled = false
	interact_pressed.emit()

func shake_camera( trauma : float ) -> void:
	camera_shook.emit( trauma )
