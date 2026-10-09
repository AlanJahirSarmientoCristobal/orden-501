extends SceneTree

const CARPETA := "res://Assets/sprites/personajes/frames"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARPETA))
	for clave in AssetPaths.PERSONAJES:
		var frames := AssetPaths.frames_personaje(clave)
		var ruta := "%s/%s.tres" % [CARPETA, clave]
		var err := ResourceSaver.save(frames, ruta)
		print("%s -> %s (%s)" % [clave, ruta, error_string(err)])
	quit()
