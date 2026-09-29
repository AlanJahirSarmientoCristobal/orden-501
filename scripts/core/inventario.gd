extends RefCounted
class_name Inventario

## Almacén de insumos organizado por lotes. Cada lote recuerda el día en que se compró
## para calcular la caducidad; el consumo es FIFO (primero se usa lo más viejo).

var lotes: Array[Dictionary] = []   # {"insumo": String, "cantidad": int, "dia": int}

func agregar(insumo: String, cantidad: int, dia: int) -> void:
	if cantidad <= 0:
		return
	for lote in lotes:
		if lote["insumo"] == insumo and int(lote["dia"]) == dia:
			lote["cantidad"] = int(lote["cantidad"]) + cantidad
			return
	lotes.append({"insumo": insumo, "cantidad": cantidad, "dia": dia})

func total(insumo: String) -> int:
	var suma := 0
	for lote in lotes:
		if lote["insumo"] == insumo:
			suma += int(lote["cantidad"])
	return suma

func total_unidades() -> int:
	var suma := 0
	for lote in lotes:
		suma += int(lote["cantidad"])
	return suma

## porciones: cuántas veces se prepara la receta (un grupo de 4 pide 4 porciones).
func faltantes(platillo: String, porciones: int = 1) -> Dictionary:
	var resultado := {}
	var receta := Catalogo.receta(platillo)
	for insumo in receta:
		var falta := int(receta[insumo]) * porciones - total(insumo)
		if falta > 0:
			resultado[insumo] = falta
	return resultado

func puede_preparar(platillo: String, porciones: int = 1) -> bool:
	return faltantes(platillo, porciones).is_empty()

func consumir_receta(platillo: String, porciones: int = 1) -> bool:
	if not puede_preparar(platillo, porciones):
		return false
	var receta := Catalogo.receta(platillo)
	for insumo in receta:
		_retirar(insumo, int(receta[insumo]) * porciones)
	return true

func _retirar(insumo: String, cantidad: int) -> void:
	var pendiente := cantidad
	var ordenados := lotes.filter(func(l): return l["insumo"] == insumo)
	ordenados.sort_custom(func(a, b): return int(a["dia"]) < int(b["dia"]))
	for lote in ordenados:
		if pendiente <= 0:
			break
		var usar := mini(pendiente, int(lote["cantidad"]))
		lote["cantidad"] = int(lote["cantidad"]) - usar
		pendiente -= usar
	lotes = lotes.filter(func(l): return int(l["cantidad"]) > 0)

## Retira los lotes perecederos vencidos. Devuelve {insumo: unidades perdidas}.
func retirar_caducados(dia_actual: int, dias_caducidad: int) -> Dictionary:
	var merma := {}
	var vigentes: Array[Dictionary] = []
	for lote in lotes:
		var perecedero := bool(Catalogo.INSUMOS.get(lote["insumo"], {}).get("perecedero", false))
		if perecedero and dia_actual - int(lote["dia"]) >= dias_caducidad:
			merma[lote["insumo"]] = int(merma.get(lote["insumo"], 0)) + int(lote["cantidad"])
		else:
			vigentes.append(lote)
	lotes = vigentes
	return merma

## Días que le quedan al lote más viejo de un insumo (-1 si no caduca o no hay existencias).
func dias_restantes(insumo: String, dia_actual: int, dias_caducidad: int) -> int:
	if not bool(Catalogo.INSUMOS.get(insumo, {}).get("perecedero", false)):
		return -1
	var minimo := -1
	for lote in lotes:
		if lote["insumo"] == insumo:
			var restantes := dias_caducidad - (dia_actual - int(lote["dia"]))
			if minimo == -1 or restantes < minimo:
				minimo = restantes
	return minimo

func a_datos() -> Array:
	return lotes.duplicate(true)

func desde_datos(datos: Array) -> void:
	lotes = []
	for lote in datos:
		if lote is Dictionary and Catalogo.INSUMOS.has(str(lote.get("insumo", ""))):
			lotes.append({"insumo": str(lote["insumo"]), "cantidad": int(lote.get("cantidad", 0)), "dia": int(lote.get("dia", 1))})

func copia() -> Inventario:
	var nuevo := Inventario.new()
	nuevo.desde_datos(a_datos())
	return nuevo
