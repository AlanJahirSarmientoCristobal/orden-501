extends SceneTree

## Genera un recurso SpriteFrames (.tres) por personaje en Assets/sprites/personajes/frames/,
## con las animaciones "down", "up" y "side" tomadas de su hoja (player.png, npc1.png...).
## Los recursos se pueden abrir y editar en el panel SpriteFrames del editor.
##
## Uso: godot --headless --path . --script res://tools/generar_frames.gd

const CARPETA := "res://Assets/sprites/personajes/frames"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARPETA))
	for clave in AssetPaths.PERSONAJES:
		var frames := AssetPaths.frames_personaje(clave)
		var ruta := "%s/%s.tres" % [CARPETA, clave]
		var err := ResourceSaver.save(frames, ruta)
		print("%s -> %s (%s)" % [clave, ruta, error_string(err)])
	quit()
