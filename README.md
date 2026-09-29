# ORDEN 501

Videojuego 2D de gestión en vista cenital (top-down), hecho con **Godot 4.7** para la asignatura Optativa 1: Creación de Videojuegos. Está inspirado en los problemas operativos del restaurante deportivo **La 501** (Huejutla de Reyes, Hidalgo) y se basa en el documento de diseño `ORDEN_501_Actividad1.docx`.

**Equipo:** Alan Jahir Sarmiento Cristóbal · Luis Ángel Hernández Hernández

## De qué trata

Dani, el nuevo gerente de La 501, debe poner en orden el negocio durante la temporada. Cada día tiene dos fases:

1. **Mañana (pueblo):** recorre el pueblo (avenidas, plaza, parque, cancha y vecinos que dan consejos, con minimapa) y entra a las tiendas. Las tiendas están decoradas con sus productos y para comprar se habla con el vendedor de la caja, que abre un **menú al estilo de Pokémon Rojo Fuego** (lista con cursor, "¿Cuántos quieres?" y confirmación Sí / No). En el **Mercado** se ve cada producto en su mueble: carnicería, pollería, panadería, costales de papas y puesto de verduras. En la **Cervecería** hay refrigeradores de cerveza y de refresco, un congelador de hielo y el exhibidor de **Monster**. El dinero y el almacén son limitados, y algunos insumos caducan.
2. **Jornada (restaurante):** atiende las mesas durante el partido. Hay que tomar pedidos, recoger en el pase de cocina o la barra, servir y limpiar mesas antes de que se agote la paciencia de los clientes. En el medio tiempo llega una ola de aficionados y cada gol provoca una ronda de bebidas.

Si un insumo se acaba, eliges entre **marcar el platillo como agotado**, hacer un **pedido urgente** por teléfono (más caro y tarda en llegar) u **ofrecer un sustituto** (menos propina). Al cerrar el día aparece el **reporte de cierre**, con ventas, merma, reservaciones y reputación, y ahí se compran **mejoras**.

### Niveles

| Nivel | Condición para avanzar |
|---|---|
| 1. Jornada Regular | Terminar sin quedarse sin stock y perdiendo máximo 3 clientes. |
| 2. Liguilla | Cero reservaciones duplicadas y alcanzar la meta de ventas. Llegan clientes VIP. |
| 3. Gran Final | Terminar con la reputación igual o mayor a la meta de la dificultad. |

Al ganar la Gran Final se desbloquea la **terraza** (2 mesas más) y se muestra el reporte de la temporada. Si la reputación llega a 0 % se pierde la jornada. "Reiniciar jornada" repite el día desde la mañana con el dinero e inventario que tenías al inicio.

### Dificultad

| Factor | Fácil | Normal | Difícil |
|---|---|---|---|
| Paciencia del cliente | 60 s | 40 s | 25 s |
| Tiempo de cocinado | ×0.8 | ×1.0 | ×1.3 |
| Llegada de clientes | cada 12 s | cada 8 s | cada 5 s |
| Parejas / familias de 4 | — | 25 % / 15 % | 35 % / 30 % |
| Clientes VIP | 10 % | 25 % | 40 % |
| Mesas se ensucian (tiempo para limpiar) | Lento | Normal | Rápido |
| Dinero inicial | $1,500 | $1,000 | $700 |
| Pedido urgente (costo / demora) | ×1.5 / 15 s | ×2 / 25 s | ×3 / 40 s |
| Caducidad de insumos | 3 días | 2 días | 1 día |
| Tiempo en el pueblo | Sin límite | 3 min | 2 min |
| Reputación mínima para ganar | 50 % | 70 % | 85 % |

## Controles

| Tecla | Acción |
|---|---|
| W A S D / Flechas | Moverse por el pueblo y el restaurante |
| Shift | Correr (gasta estamina; si se agota hay que esperar a recuperar un poco) |
| Espacio | Interactuar: tiendas, tomar pedidos, recoger y servir, limpiar mesas (mantener) |
| E | Tablet: stock, cola de cocina, reservaciones y avisos del partido |
| Q | Pedido urgente al proveedor |
| R | Asignar reservaciones a mesas |
| I | Inventario (en el pueblo) |
| Esc | Pausa (o cerrar ventana) |

## Ejecutar

1. Abre `project.godot` con Godot 4.7 (o una versión compatible de Godot 4).
2. Presiona `F5` para iniciar desde el menú principal.

## Pruebas

Las pruebas corren sin ventana:

```powershell
godot --headless --path . res://tests/test_nucleo.tscn       # dificultad, inventario, compras, reservaciones, cierre y guardado
godot --headless --path . res://tests/test_restaurante.tscn  # clientes, faltantes, urgentes, VIP, reservaciones y goles
godot --headless --path . res://tests/test_flujo_dia.tscn    # un bot juega un día completo (pueblo → partido → reporte)
```

`tests/captura_pantallas.tscn` es una herramienta de desarrollo que abre cada pantalla y guarda capturas PNG. Debe ejecutarse **con** ventana:

```powershell
godot --path . res://tests/captura_pantallas.tscn -- C:/ruta/de/salida
```

## Estructura

```
scripts/
  autoload/     GameState (partida, economía, reservaciones, guardado) y AudioManager
  core/         ConfiguracionDificultad, Catalogo, Inventario, AssetPaths, UIKit
  customers/    Cliente (base) → ClienteHabitual, ClienteVIP, ClienteReservacion
  entities/     Dani, Interactuable, PuntoInteraccion
  restaurant/   Controlador del restaurante, Mesa y Estacion (cocina / barra)
  town/         Fase de mañana: base común, pueblo, interior de tiendas, peatones y minimapa
  ui/           Menú, tablet, tiendas, pedido urgente, diálogos, reporte, victoria
scenes/         Escenas de cada pantalla (menu, town, restaurant, ui)
tests/          Pruebas headless
tools/          recortar_monster.py, componer_pueblo.py, construir_mapa_pueblo.gd y generar_sprites_restaurante.py
```

El detalle de cómo se implementó cada mecánica del documento está en `DISENO.md`.

## Cambiar los assets

**Monster:** es un solo producto con 7 diseños; cada vez que se muestra usa el siguiente. Guarda la hoja completa en `Assets/sprites/monster/monster_hoja.png` y ejecuta:

```powershell
python tools/recortar_monster.py
```

El script genera `monster_1.png` … `monster_7.png` sin el fondo. La hoja debe ser un PNG real (si es JPEG, conviértelo a PNG antes de copiarla). Mientras no existan esos archivos, el juego dibuja 7 latas provisionales con los mismos colores.

Todos los gráficos y sonidos se referencian desde **`scripts/core/asset_paths.gd`**:

- `TEXTURAS`: íconos de insumos y platillos, y decoración. Cambia la ruta por tu imagen.
- `PERSONAJES`: sprites de Dani, el Chef, los clientes y los vendedores. Hoy se toman del tileset RPG Urban (tres cuadros por dirección). Para usar hojas propias, cambia `frames_personaje()` por un `SpriteFrames` que armes en el editor.
- `AUDIO`: si guardas en `Assets/audio/` un archivo con el nombre indicado (por ejemplo `musica_jornada.ogg` o `gol.ogg`), el juego lo usa en lugar del sonido generado por código.

### Mapa del pueblo (TileMap)

El pueblo se arma con tiles de Kenney RPG Urban, en el mismo estilo que `Assets/sprites/rpg_urban/Sample.png`:

- `scenes/town/mapa_pueblo.tscn`: dos `TileMapLayer` (Suelo y Objetos) con el TileSet `Assets/tilesets/rpg_urban.tres`, que ya incluye las colisiones. **Se puede abrir y pintar en el editor de Godot.**
- `scenes/town/mapa_pueblo.json`: la ubicación de las puertas, el parque, la plaza y la cancha, que usa `town.gd`.

Para regenerar el mapa desde cero (esto sobrescribe los cambios hechos a mano en la escena):

```powershell
python tools/componer_pueblo.py vista_previa.png
godot --headless --path . --script res://tools/construir_mapa_pueblo.gd
```

Si cambias en el editor dónde están las puertas, actualiza también sus coordenadas en `mapa_pueblo.json`.

### Interiores (tiendas y restaurante)

El Mercado, la Cervecería y el restaurante se arman con tiles de **Kenney Roguelike RPG Pack** y **Roguelike Indoors** (`Assets/sprites/interiores/`), usando la clase `scripts/core/interior.gd`:

- `cuarto()` arma las paredes, el piso y la puerta.
- `poner()`, `fila()` y `columna()` colocan muebles por número de tile.
- `solido()` agrega la colisión.

Las pantallas del partido y el letrero de neón son pixel art propio generado por `tools/generar_sprites_restaurante.py` (`Assets/sprites/restaurante/`): la cancha alterna dos cuadros, muestra "GOL!" en cada gol y el neón parpadea. Se pueden reemplazar desde `AssetPaths` (claves `tv_1`, `tv_2`, `tv_gol`, `neon_on` y `neon_off`).

La distribución de cada tienda está en `store.gd` (`_amueblar_mercado` y `_amueblar_cerveceria`) y la del restaurante en `restaurant.gd` (`_construir_escenario`).

Los gráficos temporales son de Kenney (CC0). Consulta `THIRD_PARTY_LICENSES.md`.

## Guardado

La partida se guarda en `user://orden501_save.json` al comenzar cada mañana y al superar una jornada.
