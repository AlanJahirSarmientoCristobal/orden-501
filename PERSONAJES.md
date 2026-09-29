# Personajes de ORDEN 501: cómo entregar los sprites

Esta guía explica cómo dibujar y entregar los sprites de los personajes para que el juego los use directamente, sin tocar el código. También incluye una ficha de diseño para cada personaje.

## 1. Formato de la hoja de sprites

Cada personaje va en **un solo PNG** con **4 columnas × 3 filas** de cuadros del mismo tamaño.

|  | Col 1 | Col 2 | Col 3 | Col 4 |
|---|---|---|---|---|
| **Fila 1: abajo** (de frente) | De pie | Paso A | De pie | Paso B |
| **Fila 2: arriba** (de espaldas) | De pie | Paso A | De pie | Paso B |
| **Fila 3: lado** (mirando a la **derecha**) | De pie | Paso A | De pie | Paso B |

- **Tamaño recomendado del cuadro: 32 × 32 px**, así que la hoja completa mide **128 × 96 px**. También sirven 16, 24 o 48 px: el juego calcula la escala para que todos los personajes midan lo mismo en pantalla (64 px de alto).
- **Fondo transparente** (PNG con canal alfa). No uses JPG.
- **Pies centrados y pegados al borde inferior** del cuadro (la línea roja de la plantilla).
- **Paso A y Paso B:** en Paso A adelanta un pie y en Paso B el otro. La columna 1 (de pie) es la pose quieta del personaje.
- **Columna 3:** puede ser igual a la columna 1. Si quieres más movimiento, dibuja una variante (por ejemplo, con el cuerpo 1 px más abajo).
- **Izquierda:** no la dibujes. El juego voltea la fila 3.
- **Pixel art sin suavizado:** exporta con la escala al 100 %, sin antialias.

### Archivos de ayuda (`Assets/sprites/personajes/plantillas/`)

| Archivo | Para qué sirve |
|---|---|
| `plantilla_32px.png` | Cuadrícula vacía de 128 × 96 para dibujar encima (en Aseprite, Piskel, LibreSprite, etc.). |
| `guia_plantilla.png` | La cuadrícula ampliada con el nombre de cada cuadro. |
| `ejemplo_dani.png` | El Dani provisional (Kenney) acomodado en el formato exacto. Úsalo como referencia. |

Para regenerarlos: `python tools/generar_plantilla_personaje.py`.

### Retrato (opcional)

Para los diálogos y el menú de compra se puede entregar un **busto** cuadrado (por ejemplo, 64 × 64 o 96 × 96) llamado `retrato_<clave>.png`. Si no existe, se usa el primer cuadro de la hoja.

## 2. Dónde guardarlos y con qué nombre

Guarda cada hoja en **`Assets/sprites/personajes/`** con el nombre de su clave:

| Clave (nombre del archivo) | Personaje | Dónde aparece |
|---|---|---|
| `dani.png` | **Dani**, el gerente (protagonista) | Pueblo y restaurante |
| `chef.png` | El Chef | Cocina del restaurante |
| `cliente_1.png`, `cliente_2.png`, `cliente_3.png` | Clientes habituales (3 variantes) | Restaurante, peatones del pueblo, acompañantes de parejas y familias |
| `cliente_vip.png` | Cliente VIP | Restaurante (Liguilla y Gran Final) |
| `critico.png` | Crítico gastronómico | Evento del partido |
| `vendedor_mercado.png` | Don Chema, vendedor del Mercado | Interior del Mercado y menú de compra |
| `encargado_cerveceria.png` | Lupita, encargada de la Cervecería | Interior de la Cervecería y menú de compra |
| `dona_mari.png` | Doña Mari (consejos) | Plaza del pueblo |
| `profe_juve.png` | Profe Juve (consejos) | Parque del pueblo |
| `capitan.png` | Capitán del equipo (consejos) | Cancha del pueblo |

Al abrir el proyecto en Godot, las imágenes se importan solas y el juego las usa en lugar del sprite de Kenney. Si un personaje no tiene hoja, conserva el provisional, así que puedes entregarlos uno por uno.

Mientras el VIP y el crítico usan el sprite genérico, el juego los pinta de dorado o morado para distinguirlos. Con su hoja propia se muestran con sus colores originales.

## 3. Qué animación usa el juego y cuándo

| Animación | Cuándo se ve |
|---|---|
| Abajo / Arriba / Lado, columnas 1→2→3→4 en bucle (8 cuadros por segundo) | Caminar. Dani al correr (Shift) usa el mismo ciclo, más rápido. |
| Columna 1 de cada fila | Quieto: Dani parado, clientes sentados, vendedores y NPCs. |

Si más adelante quieren animaciones extra (Dani limpiando, cargando la bandeja o el Chef cocinando), se pueden agregar como filas nuevas en la misma hoja. Díganme cuáles y ajusto el código.

## 4. Ficha de diseño por personaje (para la Actividad 2)

Copia esta ficha para cada personaje principal:

```
Nombre:
Rol en el juego:            (protagonista / apoyo / cliente / NPC)
Descripción física:         (edad, complexión, ropa, rasgo distintivo)
Personalidad:               (3 adjetivos)
Paleta de colores:          (4–6 colores en HEX)
Silueta reconocible por:    (gorra, mandil, bufanda del equipo…)
Relación con la historia:
Animaciones:                caminar abajo / arriba / lado (4 cuadros c/u), quieto
Tamaño del sprite:          32 × 32 px (hoja de 128 × 96)
Archivo:                    Assets/sprites/personajes/<clave>.png
```

### Ejemplo: Dani

```
Nombre:                     Dani
Rol en el juego:            Protagonista, nuevo gerente de La 501
Descripción física:         Joven de unos 25 años, cabello oscuro con banda naranja,
                            playera del restaurante y delantal café
Personalidad:               Organizado, entusiasta, bajo presión
Paleta de colores:          #3A3A3A (cabello) #FF6A3D (banda) #F2C29B (piel)
                            #C27A45 (delantal) #8E8EA8 (pantalón)
Silueta reconocible por:    La banda naranja en la cabeza y el delantal
Relación con la historia:   Debe poner en orden el restaurante durante la temporada
                            y llevarlo a la Gran Final
Animaciones:                Caminar en 3 direcciones (4 cuadros), quieto; corre con Shift
Tamaño del sprite:          32 × 32 px
Archivo:                    Assets/sprites/personajes/dani.png
```

**Personajes principales sugeridos para la entrega:** Dani, el Chef, el Cliente VIP, Don Chema y Lupita. Los clientes habituales y los NPCs del pueblo pueden ir como personajes secundarios.
