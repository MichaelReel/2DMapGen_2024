extends TileMap

const _debug_scale : Vector2 = Vector2(4.0, 4.0)

@export var _tile_generation_area := Rect2i(Vector2i(1,1), Vector2i(35, 22))
@export var _seed: int = 0
@export var _process_on_ready: bool = false
@export var _auto_process: bool = false

@onready var OptionsDraw: PackedScene = load("res://TileSetDrawn/WaveFormCollapse/OptionsDraw.tscn")
@onready var _tile_connection_mappings := _get_tile_valid_neighbours_map()
@onready var _tile_size: Vector2 = tile_set.tile_size
@onready var _tile_debug_offset := Vector2(
	_tile_generation_area.position.x * tile_set.tile_size.x,
	_tile_generation_area.position.y * tile_set.tile_size.y,
)

var _tiles: Array[Array]
var _rng: RandomNumberGenerator
var _tile_front: Dictionary  # Dictionary[String, Array[TileOptions]]
var _tile_front_display: Dictionary  # Dictionary[Vect

class TileOptions:
	var pos: Vector2i
	var options: Array
	
	func _init(p:Vector2i, o: Array) -> void:
		self.pos = p
		self.options = o


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = _seed
	
	_tiles = _get_empty_tiles_area(_tile_generation_area, _tile_connection_mappings)
	_resolve_a_random_tile(_tiles, _tile_connection_mappings, _tile_generation_area, _rng)
	
	while _process_on_ready and not _tile_front.is_empty():
		_resolve_the_lowest_option_tile(_tiles, _tile_connection_mappings, _tile_generation_area, _rng)

func _create_debug_tile_display(draw_vector_names: Array, tile_connection_mappings: Dictionary, tile_pos: Vector2i) -> Node2D:
	var test_options_draw: Node2D = OptionsDraw.instantiate()
	add_child(test_options_draw)
	var draw_vectors: Array[Vector2i] = _map_string_array_to_vector_array(draw_vector_names, tile_connection_mappings)
	test_options_draw.scale = _debug_scale
	test_options_draw.position = Vector2(tile_pos.x * _tile_size.x, tile_pos.y * _tile_size.y) + _tile_debug_offset
	test_options_draw.settings = draw_vectors
	return test_options_draw

func _map_string_array_to_vector_array(strings: Array, tile_connection_mappings: Dictionary) -> Array[Vector2i]:
	var vectors: Array[Vector2i] = []
	for str in strings:
		vectors.append(tile_connection_mappings["tiles_by_name"][str])
	return vectors

func _process(_delta: float) -> void:
	if not _tile_front.is_empty() and _auto_process:
		_resolve_the_lowest_option_tile(_tiles, _tile_connection_mappings, _tile_generation_area, _rng)

func _input(event: InputEvent) -> void:
	if _tile_front.is_empty() or _auto_process or not event is InputEventKey: return
	
	var event_key := event as InputEventKey
	if event_key.keycode != KEY_SPACE or not event_key.pressed: return
	
	_resolve_the_lowest_option_tile(_tiles, _tile_connection_mappings, _tile_generation_area, _rng)

#region COLLAPSING THE WAVE

func _resolve_a_random_tile(
	tiles: Array[Array],  # Array[Array[TileOptions]]
	tile_connection_mappings: Dictionary,
	tile_generation_area: Rect2i,
	rng: RandomNumberGenerator
) -> void:
	var y := rng.randi_range(0, len(tiles) - 1)
	var pos := Vector2i(rng.randi_range(0, len(tiles[y]) - 1), y)
	
	_tile_front = _resolve_tile_to_an_option(
		pos, tiles, tile_connection_mappings, tile_generation_area, rng
	)
	
	# Add displays to match _tile_front
	for tile_pos in _tile_front.keys():
		var tile_opts: TileOptions = _tile_front.get(tile_pos)
		var opt_disp = _create_debug_tile_display(tile_opts.options, tile_connection_mappings, tile_pos)
		_tile_front_display[tile_pos] = opt_disp

func _resolve_the_lowest_option_tile(
	tiles: Array[Array],  # Array[Array[TileOptions]]
	tile_connection_mappings: Dictionary,
	tile_generation_area: Rect2i,
	rng: RandomNumberGenerator
) -> void:
	"""Pick a tile with the lowest options for selection and pick a random option"""
	# Order the tile front by available options per tile
	var tile_front_positions := _tile_front.keys()
	tile_front_positions.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool: return len(_tile_front[a].options) < len(_tile_front[b].options)
	)
	
	# Pick the first tile and collapse the waveform
	var pos: Vector2i = tile_front_positions.front()
	var tile_front_new := _resolve_tile_to_an_option(pos, tiles, tile_connection_mappings, tile_generation_area, rng)
	
	# Add any new tiles to the tile front
	for front_tile in tile_front_new.keys():
		if not _tile_front.has(front_tile):
			_tile_front[front_tile] = tile_front_new[front_tile]
	
	# Tidy up display to match _tile_front
	for tile_pos in _tile_front.keys():
		var tile_opts: TileOptions = _tile_front.get(tile_pos)
		var opt_disp: Node2D = _tile_front_display.get(tile_pos)
		
		if not opt_disp:
			opt_disp = _create_debug_tile_display(tile_opts.options, tile_connection_mappings, tile_pos)
			_tile_front_display[tile_pos] = opt_disp
		else:
			opt_disp.settings = _map_string_array_to_vector_array(tile_opts.options, tile_connection_mappings)
	
	# Remove the picked tile from the _tile_front
	if _tile_front.erase(pos) and pos in _tile_front_display:
		remove_child(_tile_front_display[pos])
		_tile_front_display.erase(pos)
	

func _resolve_tile_to_an_option(
	pos: Vector2i,
	tiles: Array[Array],  # Array[Array[TileOptions]]
	tile_connection_mappings: Dictionary,
	tile_generation_area: Rect2i,
	rng: RandomNumberGenerator
) -> Dictionary:  # Dictionary[Vector2i, TileOptions]:
	var tile_options: TileOptions = tiles[pos.y][pos.x]
	var available_options: Array = tile_options.options
	var num_options: int = len(available_options)
	if num_options <= 0:
		printerr("No options available for tile ", pos, "!")
		return {}
	var option: String = available_options[rng.randi_range(0, len(available_options) - 1)]
	
	print("collapsing ", pos, " to ", option)
	
	return _collapse_wave_on_tile(
		pos, option, tiles, tile_connection_mappings, tile_generation_area
	)

func _collapse_wave_on_tile(
	pos: Vector2i,
	option: String,
	tiles: Array[Array],
	tile_connection_mappings: Dictionary,
	tile_generation_area: Rect2i,
) -> Dictionary:  # Dictionary[Vector2i, TileOptions]
	"""
	Collapse the tile at pos to the choosen option, update neighbours and 
	return neighbours updated indexed by remaining options
	
	For some tile sets it's not enough just to reduce the options of the adjacent tiles,
	but we should also adjust the options on the onward tiles to be what can be allowed in the 
	"""
	var updates: Dictionary = {}
	
	# Set the tile to the correct tile from the tile atlas
	var tile_set_coord: Vector2i = tile_connection_mappings["tiles_by_name"][option]
	var tile_options: TileOptions = tiles[pos.y][pos.x]
	set_cell(0, tile_options.pos, 0, tile_set_coord)
	
	updates.merge(_propagate_waveform_collapse_to_neighbours(pos, [option], tiles, tile_connection_mappings, tile_generation_area))
	
	# Reduce the options on this tile to none
	tile_options.options = []
	
	return updates

func _propagate_waveform_collapse_to_neighbours(
	pos: Vector2i,
	options: Array,  # Array[String]
	tiles: Array[Array],
	tile_connection_mappings: Dictionary,
	tile_generation_area: Rect2i,
) -> Dictionary:  # Dictionary[Vector2i, TileOptions]
	var updates: Dictionary = {}
	
	# Update the nearby tiles to reduce options
	var viable_link_map: Dictionary = {}
	for option in options:
		viable_link_map.merge(tile_connection_mappings["valid_neighbours"][option])
	
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var neighbour: Object = _update_options_in_dir(pos, dir, tiles, tile_generation_area, viable_link_map)
		if neighbour:
			var neighbour_pos: Vector2i = pos + dir
			updates[neighbour_pos] = neighbour
			
			#var neighbour_tile_options: TileOptions = tiles[neighbour_pos.y][neighbour_pos.x]
			#updates.merge(
				#_propagate_waveform_collapse_to_neighbours(
					#neighbour_pos, neighbour_tile_options.options, tiles, tile_connection_mappings, tile_generation_area
				#)
			#)
	
	return updates

func _update_options_in_dir(
	pos: Vector2i,
	dir: Vector2i,
	tiles: Array[Array],
	tile_generation_area: Rect2i,
	viable_link_map: Dictionary,
) -> Object:  # TileOptions | null
	"""
	Check the tile options in the given dir and intersect them with the options
	allowed by the current tile and the newly updated pos 
	"""
	var neighbour := pos + dir
	# Check we have the neighbour in the tile
	if neighbour.y < 0 or neighbour.x < 0 or neighbour.y >= len(tiles) or neighbour.x >= len(tiles[neighbour.y]):
		return null
	
	var neighbour_tile_options: TileOptions = tiles[neighbour.y][neighbour.x]
	
	if neighbour_tile_options.options.is_empty():
		return null
	
	# Limit the tile options and add to the updates list
	var current_options: Array = neighbour_tile_options.options
	var viable_links: Array = viable_link_map.get(dir, [])
	var new_options: Array = current_options.filter(func(t: String) -> bool: return viable_links.has(t))
	if len(new_options) == len(current_options):
		return null
	
	neighbour_tile_options.options = current_options.filter(func(t: String) -> bool: return viable_links.has(t))
	
	return neighbour_tile_options

#endregion

#region TILE AREA SETUP

func _get_empty_tiles_area(tile_generation_area: Rect2i, tile_connection_mappings: Dictionary) -> Array[Array]:
	"""Setup the tiles with nothing defined, all tiles have all possibilities"""
	
	# Get all_the_options for each tile
	var name_to_tile_map: Dictionary = tile_connection_mappings["tiles_by_name"]
	var all_options: Array = name_to_tile_map.keys()
	
	# Setup a grid with all options in each cell
	var tiles: Array[Array] = []
	for y in range(tile_generation_area.position.y, tile_generation_area.end.y + 1):
		var tile_row : Array[TileOptions] = []
		for x in range(tile_generation_area.position.x, tile_generation_area.end.x + 1):
			var tile_options: TileOptions = TileOptions.new(Vector2i(x, y), all_options.duplicate())
			tile_row.append(tile_options)
		tiles.append(tile_row)
	
	return tiles

#endregion

#region TILE WAVE PROPERTIES

# Hard coded tile connections
# Could instead be created using the waveform collapse plugin

func _get_tile_valid_neighbours_map() -> Dictionary:
	# Give the tiles a name, just to make the referencing easier
	var tiles_by_name: Dictionary = {
		# Where directions are given, assume pointing in the ascending direction
		"ext_corner_BR": Vector2i(0, 0),
		"ascent_B": Vector2i(1, 0),
		"ext_corner_BL": Vector2i(2, 0),
		"int_corner_TL": Vector2i(3, 0),
		"wall_T": Vector2i(4, 0),
		"int_corner_TR": Vector2i(5, 0),
		
		"ascent_R": Vector2i(0, 1),
		"upper_cobbles": Vector2i(1, 1),
		"ascent_L": Vector2i(2, 1),
		"wall_L": Vector2i(3, 1),
		"lower_cobbles": Vector2i(4, 1),
		"wall_R": Vector2i(5, 1),
		
		"ext_corner_TR": Vector2i(0, 2),
		"ascent_T": Vector2i(1, 2),
		"ext_corner_TL": Vector2i(2, 2),
		"int_corner_BL": Vector2i(3, 2),
		"wall_B": Vector2i(4, 2),
		"int_corner_BR": Vector2i(5, 2),
		
		"track_TB": Vector2i(1, 3),
		"track_TBLR": Vector2i(2, 3),
		"track_LR": Vector2i(3, 3),
		"track_BLR": Vector2i(0, 4),
		"track_TLR": Vector2i(1, 4),
		"track_TBL": Vector2i(2, 4),
		"track_TBR": Vector2i(3, 4),
		"track_TR": Vector2i(0, 5),
		"track_TL": Vector2i(1, 5),
		"track_BR": Vector2i(2, 5),
		"track_BL": Vector2i(3, 5),
		"track_T": Vector2i(0, 6),
		"track_L": Vector2i(1, 6),
		"track_R": Vector2i(2, 6),
		"track_B": Vector2i(3, 6),
	}
	
	var left_up_face_tiles := ["wall_T", "int_corner_TL", "ext_corner_TR"]
	var right_up_face_tiles := ["wall_T", "int_corner_TR", "ext_corner_TL"]
	var left_down_face_tiles := ["wall_B", "int_corner_BL", "ext_corner_BR"]
	var right_down_face_tiles := ["wall_B", "int_corner_BR", "ext_corner_BL"]
	var up_left_face_tiles := ["wall_L", "int_corner_TL", "ext_corner_BL"]
	var down_left_face_tiles := ["wall_L", "int_corner_BL", "ext_corner_TL"]
	var up_right_face_tiles := ["wall_R", "int_corner_TR", "ext_corner_BR"]
	var down_right_face_tiles := ["wall_R", "int_corner_BR", "ext_corner_TR"]
	
	# Define lists of tiles that can (and can't) be connected to from below (B)
	var up_tracks := ["ascent_T", "track_TB", "track_TBLR", "track_BLR", "track_TBL", "track_TBR", "track_BR", "track_BL", "track_B"]
	var non_up_tracks := ["lower_cobbles", "track_LR", "track_TLR", "track_TR", "track_TL", "track_T", "track_L", "track_R"]
	
	# Define lists of tiles that can (and can't) be connected to from above (T)
	var down_tracks := ["ascent_B", "track_TB", "track_TBLR", "track_TLR", "track_TBL", "track_TBR", "track_TR", "track_TL", "track_T"]
	var non_down_tracks := ["lower_cobbles", "track_LR", "track_BLR", "track_BR", "track_BL", "track_L", "track_R", "track_B"]
	
	# Define lists of tiles that can (and can't) be connected to from the right (R)
	var left_tracks := ["ascent_L", "track_TBLR", "track_LR", "track_BLR", "track_TLR", "track_TBR", "track_TR", "track_BR", "track_R"]
	var non_left_tracks := ["lower_cobbles", "track_TB", "track_TBL", "track_TL", "track_BL", "track_T", "track_L", "track_B"]
	
	# Define lists of tiles that can (and can't) be connected to from the left (L)
	var right_tracks := ["ascent_R", "track_TBLR", "track_LR", "track_BLR", "track_TLR", "track_TBL", "track_TL", "track_BL", "track_L"]
	var non_right_tracks := ["lower_cobbles", "track_TB", "track_TBR", "track_TR", "track_BR", "track_T", "track_R", "track_B"]

	var top_precipice_tiles := ["upper_cobbles", "wall_B", "int_corner_BR", "int_corner_BL"]
	var bottom_precipice_tiles := ["upper_cobbles", "wall_T", "int_corner_TR", "int_corner_TL"]
	var left_precipice_tiles := ["upper_cobbles", "wall_R", "int_corner_TR", "int_corner_BR"]
	var right_precipice_tiles := ["upper_cobbles", "wall_L", "int_corner_TL", "int_corner_BL"]
	
	var top_blocking_tiles := non_up_tracks + ["wall_T", "ext_corner_TR", "ext_corner_TL"]
	var bottom_blocking_tiles := non_down_tracks + ["wall_B", "ext_corner_BR", "ext_corner_BL"]
	var left_blocking_tiles := non_left_tracks + ["wall_L", "ext_corner_TL", "ext_corner_BL"]
	var right_blocking_tiles := non_right_tracks + ["wall_R", "ext_corner_TR", "ext_corner_BR"]

	# Define and return the valid neighbours 
	return {
		"tiles_by_name": tiles_by_name,
		"valid_neighbours": {
			"ext_corner_BR": {
				Vector2i.UP: top_blocking_tiles,
				Vector2i.DOWN: ["ascent_R"] + down_right_face_tiles,
				Vector2i.LEFT: left_blocking_tiles,
				Vector2i.RIGHT: ["ascent_B"] + right_down_face_tiles,
			},
			"ascent_B": {
				Vector2i.UP: up_tracks + ["ascent_T"],
				Vector2i.DOWN: ["upper_cobbles", "ascent_T"],
				Vector2i.LEFT: left_down_face_tiles,
				Vector2i.RIGHT: right_down_face_tiles,
			},
			"ext_corner_BL": {
				Vector2i.UP: top_blocking_tiles,
				Vector2i.DOWN: ["ascent_L"] + down_left_face_tiles,
				Vector2i.LEFT: ["ascent_B"] + left_down_face_tiles,
				Vector2i.RIGHT: right_blocking_tiles,
			},
			"int_corner_TL": {
				Vector2i.UP: top_precipice_tiles,
				Vector2i.DOWN: ["ascent_L"] + down_left_face_tiles,
				Vector2i.LEFT: left_precipice_tiles,
				Vector2i.RIGHT: ["ascent_T"] + right_up_face_tiles,
			},
			"wall_T": {
				Vector2i.UP: top_precipice_tiles,
				Vector2i.DOWN: bottom_blocking_tiles,
				Vector2i.LEFT: ["ascent_T"] + left_up_face_tiles,
				Vector2i.RIGHT: ["ascent_T"] + right_up_face_tiles,
			},
			"int_corner_TR": {
				Vector2i.UP: top_precipice_tiles,
				Vector2i.DOWN: ["ascent_R"] + down_right_face_tiles,
				Vector2i.LEFT: ["ascent_T"] + left_up_face_tiles,
				Vector2i.RIGHT: right_precipice_tiles,
			},
			"ascent_R": {
				Vector2i.UP: up_right_face_tiles,
				Vector2i.DOWN: down_right_face_tiles,
				Vector2i.LEFT: left_tracks + ["ascent_L"],
				Vector2i.RIGHT: ["upper_cobbles", "ascent_L"],
			},
			"upper_cobbles": {
				Vector2i.UP: ["ascent_B"] + top_precipice_tiles,
				Vector2i.DOWN: ["ascent_T"] + bottom_precipice_tiles,
				Vector2i.LEFT: ["ascent_R"] + left_precipice_tiles,
				Vector2i.RIGHT: ["ascent_L"] + right_precipice_tiles,
			},
			"ascent_L": {
				Vector2i.UP: up_left_face_tiles,
				Vector2i.DOWN: down_left_face_tiles,
				Vector2i.LEFT: ["upper_cobbles", "ascent_R"],
				Vector2i.RIGHT: right_tracks + ["ascent_R"],
			},
			"wall_L": {
				Vector2i.UP: ["ascent_L"] + up_left_face_tiles,
				Vector2i.DOWN: ["ascent_L"] + down_left_face_tiles,
				Vector2i.LEFT: left_precipice_tiles,
				Vector2i.RIGHT: right_blocking_tiles,
			},
			"lower_cobbles": {
				Vector2i.UP: ["ascent_T"] + top_blocking_tiles,
				Vector2i.DOWN: ["ascent_B"] + bottom_blocking_tiles,
				Vector2i.LEFT: ["ascent_L"] + left_blocking_tiles,
				Vector2i.RIGHT: ["ascent_R"] + right_blocking_tiles,
			},
			"wall_R": {
				Vector2i.UP: ["ascent_R"] + up_right_face_tiles,
				Vector2i.DOWN: ["ascent_R"] + down_right_face_tiles,
				Vector2i.LEFT: left_blocking_tiles,
				Vector2i.RIGHT: right_precipice_tiles,
			},
			"ext_corner_TR": {
				Vector2i.UP: ["ascent_R"] + up_right_face_tiles,
				Vector2i.DOWN: bottom_blocking_tiles,
				Vector2i.LEFT: left_blocking_tiles,
				Vector2i.RIGHT: ["ascent_T"] + right_up_face_tiles,
			},
			"ascent_T": {
				Vector2i.UP: ["upper_cobbles", "ascent_B"],
				Vector2i.DOWN: down_tracks + ["ascent_B"],
				Vector2i.LEFT: left_up_face_tiles,
				Vector2i.RIGHT: right_up_face_tiles,
			},
			"ext_corner_TL": {
				Vector2i.UP: ["ascent_L"] + up_left_face_tiles,
				Vector2i.DOWN: bottom_blocking_tiles,
				Vector2i.LEFT: ["ascent_T"] + left_up_face_tiles,
				Vector2i.RIGHT: right_blocking_tiles,
			},
			"int_corner_BL": {
				Vector2i.UP: ["ascent_L"] + up_left_face_tiles,
				Vector2i.DOWN: bottom_precipice_tiles,
				Vector2i.LEFT: left_precipice_tiles,
				Vector2i.RIGHT: ["ascent_B"] + right_down_face_tiles,
			},
			"wall_B": {
				Vector2i.UP: top_blocking_tiles,
				Vector2i.DOWN: bottom_precipice_tiles,
				Vector2i.LEFT: ["ascent_B"] + left_down_face_tiles,
				Vector2i.RIGHT: ["ascent_B"] + right_down_face_tiles,
			},
			"int_corner_BR": {
				Vector2i.UP: ["ascent_R"] + up_right_face_tiles,
				Vector2i.DOWN: bottom_precipice_tiles,
				Vector2i.LEFT: ["ascent_B"] + left_down_face_tiles,
				Vector2i.RIGHT: right_precipice_tiles,
			},
			"track_TB": {
				Vector2i.UP: up_tracks,
				Vector2i.DOWN: down_tracks,
				Vector2i.LEFT: non_left_tracks,
				Vector2i.RIGHT: non_right_tracks,
			},
			"track_TBLR": {
				Vector2i.UP: up_tracks,
				Vector2i.DOWN: down_tracks,
				Vector2i.LEFT: left_tracks,
				Vector2i.RIGHT: right_tracks,
			},
			"track_LR": {
				Vector2i.UP: non_up_tracks,
				Vector2i.DOWN: non_down_tracks,
				Vector2i.LEFT: left_tracks,
				Vector2i.RIGHT: right_tracks,
			},
			"track_BLR": {
				Vector2i.UP: non_up_tracks,
				Vector2i.DOWN: down_tracks,
				Vector2i.LEFT: left_tracks,
				Vector2i.RIGHT: right_tracks,
			},
			"track_TLR": {
				Vector2i.UP: up_tracks,
				Vector2i.DOWN: non_down_tracks,
				Vector2i.LEFT: left_tracks,
				Vector2i.RIGHT: right_tracks,
			},
			"track_TBL": {
				Vector2i.UP: up_tracks,
				Vector2i.DOWN: down_tracks,
				Vector2i.LEFT: left_tracks,
				Vector2i.RIGHT: non_right_tracks,
			},
			"track_TBR": {
				Vector2i.UP: up_tracks,
				Vector2i.DOWN: down_tracks,
				Vector2i.LEFT: non_left_tracks,
				Vector2i.RIGHT: right_tracks,
			},
			"track_TR": {
				Vector2i.UP: up_tracks,
				Vector2i.DOWN: non_down_tracks,
				Vector2i.LEFT: non_left_tracks,
				Vector2i.RIGHT: right_tracks,
			},
			"track_TL": {
				Vector2i.UP: up_tracks,
				Vector2i.DOWN: non_down_tracks,
				Vector2i.LEFT: left_tracks,
				Vector2i.RIGHT: non_right_tracks,
			},
			"track_BR": {
				Vector2i.UP: non_up_tracks,
				Vector2i.DOWN: down_tracks,
				Vector2i.LEFT: non_left_tracks,
				Vector2i.RIGHT: right_tracks,
			},
			"track_BL": {
				Vector2i.UP: non_up_tracks,
				Vector2i.DOWN: down_tracks,
				Vector2i.LEFT: left_tracks,
				Vector2i.RIGHT: non_right_tracks,
			},
			"track_T": {
				Vector2i.UP: up_tracks,
				Vector2i.DOWN: non_down_tracks,
				Vector2i.LEFT: non_left_tracks,
				Vector2i.RIGHT: non_right_tracks,
			},
			"track_L": {
				Vector2i.UP: non_up_tracks,
				Vector2i.DOWN: non_down_tracks,
				Vector2i.LEFT: left_tracks,
				Vector2i.RIGHT: non_right_tracks,
			},
			"track_R": {
				Vector2i.UP: non_up_tracks,
				Vector2i.DOWN: non_down_tracks,
				Vector2i.LEFT: non_left_tracks,
				Vector2i.RIGHT: right_tracks,
			},
			"track_B": {
				Vector2i.UP: non_up_tracks,
				Vector2i.DOWN: down_tracks,
				Vector2i.LEFT: non_left_tracks,
				Vector2i.RIGHT: non_right_tracks,
			},
		}
	}
	
#endregion
