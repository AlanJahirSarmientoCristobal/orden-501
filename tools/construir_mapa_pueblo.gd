extends SceneTree

## Convierte scenes/town/mapa_pueblo.json (generado por tools/componer_pueblo.py) en:
##   Assets/tilesets/rpg_urban.tres     TileSet del pack RPG Urban con colisiones
##   scenes/town/mapa_pueblo.tscn       Escena con dos TileMapLayer (Suelo y Objetos)
## La escena resultante se puede abrir y pintar en el editor de Godot.
##
## Uso: godot --headless --path . --script res://tools/construir_mapa_pueblo.gd

const JSON_MAPA := "res://scenes/town/mapa_pueblo.json"
const ATLAS := "res://Assets/sprites/rpg_urban/Tilemap/tilemap_packed.png"
const TILESET := "res://Assets/tilesets/rpg_urban.tres"
const ESCENA := "res://scenes/town/mapa_pueblo.tscn"

func _init() -> void:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(JSON_MAPA))
	if not datos is Dictionary:
		push_error("No se pudo leer %s" % JSON_MAPA)
		quit(1)
		return
	var columnas_atlas := int(datos["atlas_columnas"])
	var tam := int(datos["tile"])

	# Tiles sólidos: los que aparecen en alguna celda marcada como sólida.
	var celdas_solidas := {}
	for p in datos["solidos"]:
		celdas_solidas[Vector2i(int(p[0]), int(p[1]))] = true
	var ids_solidos := {}
	for capa in ["suelo", "objetos"]:
		var filas: Array = datos[capa]
		for y in range(filas.size()):
			for x in range(filas[y].size()):
				var id := int(filas[y][x])
				if id >= 0 and celdas_solidas.has(Vector2i(x, y)):
					# En la capa de suelo solo cuentan los tiles sin objeto encima o las piezas de edificio/agua.
					ids_solidos[id] = true
	# Los objetos decorativos del suelo (banqueta, pasto, calle) nunca son sólidos.
	for libre in [8, 9, 10, 35, 36, 37, 62, 63, 64, 0, 1, 2, 27, 28, 29, 54, 55, 56, 441, 442]:
		ids_solidos.erase(libre)

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(tam, tam)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)
	var fuente := TileSetAtlasSource.new()
	fuente.texture = load(ATLAS)
	fuente.texture_region_size = Vector2i(tam, tam)
	tileset.add_source(fuente, 0)
	var textura_tam: Vector2i = fuente.texture.get_size()
	var filas_atlas := textura_tam.y / tam
	var medio := tam / 2.0
	var cuadro := PackedVector2Array([Vector2(-medio, -medio), Vector2(medio, -medio), Vector2(medio, medio), Vector2(-medio, medio)])
	for fila in range(filas_atlas):
		for col in range(columnas_atlas):
			var coords := Vector2i(col, fila)
			fuente.create_tile(coords)
			if ids_solidos.has(fila * columnas_atlas + col):
				var datos_tile := fuente.get_tile_data(coords, 0)
				datos_tile.add_collision_polygon(0)
				datos_tile.set_collision_polygon_points(0, 0, cuadro)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Assets/tilesets"))
	var err := ResourceSaver.save(tileset, TILESET)
	if err != OK:
		push_error("No se pudo guardar el TileSet: %s" % error_string(err))
		quit(1)
		return
	tileset = load(TILESET)

	var raiz := Node2D.new()
	raiz.name = "MapaPueblo"
	var escala := float(datos["escala"])
	for capa in ["suelo", "objetos"]:
		var layer := TileMapLayer.new()
		layer.name = capa.capitalize()
		layer.tile_set = tileset
		layer.scale = Vector2(escala, escala)
		layer.collision_enabled = true
		var filas: Array = datos[capa]
		for y in range(filas.size()):
			for x in range(filas[y].size()):
				var id := int(filas[y][x])
				if id >= 0:
					layer.set_cell(Vector2i(x, y), 0, Vector2i(id % columnas_atlas, id / columnas_atlas))
		raiz.add_child(layer)
		layer.owner = raiz
	var escena := PackedScene.new()
	escena.pack(raiz)
	err = ResourceSaver.save(escena, ESCENA)
	if err != OK:
		push_error("No se pudo guardar la escena: %s" % error_string(err))
		quit(1)
		return
	print("Mapa del pueblo generado: %s (%d tiles sólidos)" % [ESCENA, ids_solidos.size()])
	raiz.free()
	quit(0)
