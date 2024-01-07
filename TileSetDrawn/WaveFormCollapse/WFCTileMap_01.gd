extends TileMap


@export var _tile_generation_area := Rect2i(Vector2i(1,1), Vector2i(35, 22))
@export var _seed : int = 0

@onready var _tile_connection_mappings := _get_tile_valid_neighbours_map()

var _tiles: Array[Array]
var _rng: RandomNumberGenerator
var _tile_front: Dictionary  # Dictionary[String, Array[TileOptions]]

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
	while not _tile_front.is_empty():
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
	
	# Remove the picked tile from the _tile_front
	_tile_front.erase(pos)

func _resolve_tile_to_an_option(
	pos: Vector2i,
	tiles: Array[Array],  # Array[Array[TileOptions]]
	tile_connection_mappings: Dictionary,
	tile_generation_area: Rect2i,
	rng: RandomNumberGenerator
) -> Dictionary:  # Dictionary[Vector2i, TileOptions]:
	var tile_options: TileOptions = tiles[pos.y][pos.x]
	var available_options: Array = tile_options.options
	var option: String = available_options[rng.randi_range(0, len(available_options) - 1)]
	
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
	"""
	var updates: Dictionary = {}
	
	# Set the tile to the correct tile from the tile atlas
	var tile_set_coord: Vector2i = tile_connection_mappings["tiles_by_name"][option]
	var tile_options: TileOptions = tiles[pos.y][pos.x]
	set_cell(0, tile_options.pos, 0, tile_set_coord)
	
	# Update the nearby tiles to reduce options and add to the return list
	var viable_link_map: Dictionary = tile_connection_mappings["valid_neighbours"][option]
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var neighbour: Object = _update_options_in_dir(pos, dir, tiles, tile_generation_area, viable_link_map)
		if neighbour:
			updates[pos + dir] = neighbour
	
	# Reduce the options on this tile to none
	tile_options.options = []
	
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
	
	# The following *should* be covered by the check in the tiles table above:
	#if not tile_generation_area.has_point(neighbour_tile_options.pos):
		#return null
	
	if neighbour_tile_options.options.is_empty():
		return null
	
	# Limit the tile options and add to the updates list
	var current_options: Array = neighbour_tile_options.options
	var viable_links: Array = viable_link_map[dir]
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
		"grass": Vector2i(0, 0),
		"track_TB": Vector2i(1, 0),
		"track_TBLR": Vector2i(2, 0),
		"track_LR": Vector2i(3, 0),
		"track_BLR": Vector2i(0, 1),
		"track_TLR": Vector2i(1, 1),
		"track_TBL": Vector2i(2, 1),
		"track_TBR": Vector2i(3, 1),
		"track_TR": Vector2i(0, 2),
		"track_TL": Vector2i(1, 2),
		"track_BR": Vector2i(2, 2),
		"track_BL": Vector2i(3, 2),
		"track_T": Vector2i(0, 3),
		"track_L": Vector2i(1, 3),
		"track_R": Vector2i(2, 3),
		"track_B": Vector2i(3, 3),
	}
	
	# Define lists of tiles that can (and can't) be connected to from below (B)
	var up_tracks := ["track_TB", "track_TBLR", "track_BLR", "track_TBL", "track_TBR", "track_BR", "track_BL", "track_B"]
	var non_up_tracks := ["grass", "track_LR", "track_TLR", "track_TR", "track_TL", "track_T", "track_L", "track_R"]
	
	# Define lists of tiles that can (and can't) be connected to from above (T)
	var down_tracks := ["track_TB", "track_TBLR", "track_TLR", "track_TBL", "track_TBR", "track_TR", "track_TL", "track_T"]
	var non_down_tracks := ["grass", "track_LR", "track_BLR", "track_BR", "track_BL", "track_L", "track_R", "track_B"]
	
	# Define lists of tiles that can (and can't) be connected to from the right (R)
	var left_tracks := ["track_TBLR", "track_LR", "track_BLR", "track_TLR", "track_TBR", "track_TR", "track_BR", "track_R"]
	var non_left_tracks := ["grass", "track_TB", "track_TBL", "track_TL", "track_BL", "track_T", "track_L", "track_B"]
	
	# Define lists of tiles that can (and can't) be connected to from the left (L)
	var right_tracks := ["track_TBLR", "track_LR", "track_BLR", "track_TLR", "track_TBL", "track_TL", "track_BL", "track_L"]
	var non_right_tracks := ["grass", "track_TB", "track_TBR", "track_TR", "track_BR", "track_T", "track_R", "track_B"]
	
	# Define and return the valid neighbours 
	return {
		"tiles_by_name": tiles_by_name,
		"valid_neighbours": {
			"grass": {
				Vector2i.UP: non_up_tracks,
				Vector2i.DOWN: non_down_tracks,
				Vector2i.LEFT: non_left_tracks,
				Vector2i.RIGHT: non_right_tracks,
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
