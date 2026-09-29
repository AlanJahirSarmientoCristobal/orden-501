# ORDEN 501 — Del documento de diseño al código

Resumen de cómo se implementó cada sección de `ORDEN_501_Actividad1.docx`, y de los valores que el documento no fijaba y que se decidieron durante el desarrollo. Esos valores se pueden ajustar en los archivos indicados.

## Mecánicas del documento

| Sección del documento | Implementación |
|---|---|
| Ciclo del día: mañana → jornada → faltante → cierre | `town.gd` → `restaurant.gd` → `closing_report.gd` |
| Mapa del pueblo con Mercado y Cervecería | `scenes/town/mapa_pueblo.tscn` (TileMap estilo Kenney) + `scripts/town/town.gd` (puertas, minimapa, peatones y vecinos) |
| Tiendas con interior | `scripts/town/store.gd`: cada insumo en su propio estante; la compra se hace en `panel_tienda.gd` |
| Monster (7 diseños, un solo producto) | `AssetPaths.siguiente_diseno("monster")` rota el sprite cada vez que se muestra |
| Dinero y capacidad del almacén limitados | `GameState.comprar()`, `capacidad_almacen()` |
| Caducidad y merma | `Inventario.retirar_caducados()`; la merma se calcula al cerrar la jornada |
| Tablet (E): stock, cola de cocina, reservaciones, avisos | `scripts/ui/tablet.gd` |
| Pedido urgente (Q) más caro y con demora | `scripts/ui/panel_urgente.gd`, `restaurant.pedir_urgente()` |
| Faltante: agotado / urgente / sustituto | `restaurant._mostrar_faltante()` y `Catalogo.SUSTITUTOS` |
| Bandeja de 3 platillos (4 con mejora) | `Dani.bandeja`, `GameState.capacidad_bandeja()` |
| Clientes con estados y temporizadores propios | `Cliente`: EN_FILA → CAMINANDO → ORDENANDO → ESPERANDO_COMIDA → COMIENDO → SALIENDO |
| Herencia Cliente → Habitual / VIP / Reservación | `scripts/customers/` (polimorfismo en paciencia, propina, pedido y penalización) |
| Mesas sucias que hay que limpiar | `Mesa`: estados LIMPIA / OCUPADA / SUCIA; se limpia manteniendo Espacio |
| Reservaciones sin duplicar (R) | `GameState.asignar_reservacion()` detecta mesa y horario repetidos |
| Medio tiempo y goles | `restaurant._procesar_eventos()` y `_gol()` |
| Reporte de cierre y mejoras | `closing_report.gd`, `GameState.MEJORAS` |
| "Reiniciar jornada" | `GameState.reiniciar_jornada()` restaura la foto de la mañana |
| Terraza al final de la temporada | `GameState.terraza_desbloqueada` agrega las mesas 7 y 8 |
| Clase de configuración de dificultad | `ConfiguracionDificultad` (tabla exacta de la sección 12) |
| Guardado del progreso | `GameState.guardar()` / `cargar()` en `user://orden501_save.json` |

## Ampliaciones pedidas por el equipo

- **Mapa del pueblo más grande:** 2×2 pantallas (el documento hablaba de "una o dos pantallas"). Tiene un minimapa para orientarse, y el reloj de la mañana sigue corriendo dentro de las tiendas.
- **Mercado y Cervecería con interior:** son cuartos de una pantalla, con cada producto en un lugar distinto.
- **Monster:** bebida de la Cervecería ($20 en tienda, $45 en el menú). No caduca, se sirve en la barra, forma parte de las rondas por gol y sirve como sustituto de refresco y cerveza.

## Valores decididos durante el desarrollo

El documento no fijaba estos valores:

- **Reputación inicial:** 75 %, y se conserva de un día a otro.
  - Sube: +1.5 por pedido entregado y +3 por pedido VIP.
  - Baja: −8 si se va un cliente, −12 si se va un VIP, −8 por reservación duplicada y −5 si una reservación llega sin mesa asignada.
- **Almacén:** 80 unidades. La mejora "Estantes extra" agrega 30, hasta dos veces.
- **Duración del partido** (tiempo real para 90'): 3 min en el Nivel 1, 3.5 min en el Nivel 2 y 4 min en el Nivel 3.
- **Meta de ventas del Nivel 2:** $1,000 en Fácil, $1,200 en Normal y $1,400 en Difícil.
- **"Mesas se ensucian":** se interpretó como el tiempo que hay que mantener Espacio para limpiar (0.8 / 1.5 / 2.5 s). En la Gran Final ese tiempo se multiplica por 1.3.
- **Nivel 1:** no hay VIP ni reservaciones, y la paciencia es 20 % mayor ("clientes pacientes").
- **Clientes VIP:** piden el Combo VIP ($220), tienen el 60 % de la paciencia y dejan 35 % de propina (15 % el habitual).
- **Propina:** es mayor mientras más rápido se atiende (se multiplica por la paciencia restante). Un sustituto deja 40 % de la propina normal.
- **Medio tiempo (45'):** llegan 2 + nivel clientes de golpe, y hasta el minuto 60 el 75 % de los pedidos son bebidas.
- **Goles:** 1 o 2 goles al azar (3 en la Gran Final). Cada mesa que está comiendo tiene 70 % de probabilidad de pedir otra ronda de bebidas.
- **Reservaciones:** 4 en la Liguilla y 6 en la Gran Final, en horarios que a veces coinciden. Una mesa reservada se aparta 10 minutos antes de la llegada.
- **Mesas:** la 1 a la 3 son para 2 personas; la 4 a la 8 son para 4.
- **Quiebre de stock:** cuenta una vez por pedido que no se pudo preparar.
- **Promoción 2x1:** mejora de un solo uso. En la siguiente jornada llegan alrededor de 40 % más clientes (el intervalo entre llegadas se divide entre 1.4).

Los precios y las recetas están en `scripts/core/catalogo.gd`, y los valores de progresión en `scripts/autoload/game_state.gd`.
