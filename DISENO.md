# ORDEN 501 — Del documento de diseño al código

Resumen de cómo se implementó cada sección de `ORDEN_501_Actividad1.docx`, y de los valores que el documento no fijaba y que se decidieron durante el desarrollo. Esos valores se pueden ajustar en los archivos indicados.

## Mecánicas del documento

| Sección del documento | Implementación |
|---|---|
| Ciclo del día: mañana → jornada → faltante → cierre | `town.gd` → `restaurant.gd` → `closing_report.gd` |
| Mapa del pueblo con Mercado y Cervecería | `scenes/town/mapa_pueblo.tscn` (TileMap estilo Kenney) + `scripts/town/town.gd` (puertas, minimapa, peatones y vecinos) |
| Tiendas con interior | `scenes/town/mercado.tscn` y `cerveceria.tscn` (script `store.gd`), con tiles Roguelike en `TileMapLayer`: la tienda está decorada y se compra con el vendedor en `scenes/ui/menu_compra.tscn` (estilo Pokémon Rojo Fuego) |
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
- **Sprint con estamina (Shift):** no aparece en el documento de diseño; se agregó a petición del equipo.
  - Corre 60 % más rápido y gasta 35 de estamina por segundo; se recupera a 22 por segundo sin correr.
  - Si se agota, no puede volver a correr hasta recuperar 25. Valores en `scripts/entities/dani.gd`.
- **Personajes:** se dibujan a escala 4 (64 px) en lugar de 3, en `AssetPaths.ESCALA_PERSONAJE`.
- **Monster:** bebida de la Cervecería ($12 en tienda, $45 en el menú). No caduca, se sirve en la barra, forma parte de las rondas por gol y sirve como sustituto de refresco y cerveza.

## Valores decididos durante el desarrollo

El documento no fijaba estos valores:

- **Reputación inicial:** 75 %, y se conserva de un día a otro.
  - Sube: +1.5 por pedido entregado y +3 por pedido VIP.
  - Baja: −8 si se va un cliente, −12 si se va un VIP, −8 por reservación duplicada y −5 si una reservación llega sin mesa asignada.
- **Almacén:** 100 unidades. La mejora "Estantes extra" agrega 30, hasta dos veces.
- **Duración del partido** (tiempo real para 90'): 2.5 min en el Nivel 1, 3 min en el Nivel 2 y 3.5 min en el Nivel 3.
- **Meta de ventas del Nivel 2:** $1,000 en Fácil, $1,200 en Normal y $1,400 en Difícil.
- **"Mesas se ensucian":** se interpretó como el tiempo que hay que mantener Espacio para limpiar (0.8 / 1.5 / 2.5 s). En la Gran Final ese tiempo se multiplica por 1.3.
- **Nivel 1:** no hay VIP ni reservaciones, y la paciencia es 20 % mayor ("clientes pacientes").
- **Clientes VIP:** piden el Combo VIP ($220), tienen el 70 % de la paciencia y dejan 35 % de propina (15 % el habitual).
- **Propina:** es mayor mientras más rápido se atiende (se multiplica por la paciencia restante). Un sustituto deja 40 % de la propina normal.
- **Medio tiempo (45'):** llegan 2 + nivel clientes de golpe, y hasta el minuto 60 el 75 % de los pedidos son bebidas.
- **Goles:** 1 o 2 goles al azar (3 en la Gran Final). Cada mesa que está comiendo tiene 70 % de probabilidad de pedir otra ronda de bebidas.
- **Reservaciones:** 4 en la Liguilla y 6 en la Gran Final, en horarios que a veces coinciden. Una mesa reservada se aparta 10 minutos antes de la llegada.
- **Mesas:** la 1 a la 3 son para 2 personas; la 4 a la 8 son para 4.
- **Grupos de clientes** (pedido del equipo): en Fácil solo llegan personas solas. En Normal, 20 % de parejas y 10 % de familias de 4; en Difícil, 30 % y 15 %. En la Jornada Regular (nivel 1) no llegan familias; empiezan en la Liguilla.
  - Las familias solo caben en mesas de 4; las parejas y las personas solas prefieren las de 2.
  - El grupo hace una sola comanda por persona (×2 o ×4): gasta y paga ese múltiplo, y la cocina tarda 35 % más por cada persona adicional.
  - Los VIP siempre llegan solos. Las reservaciones llegan con su número de personas.
- **Quiebre de stock:** cuenta una vez por pedido que no se pudo preparar.
- **Stock bajo:** se avisa a partir de 6 unidades (amarillo en el panel; rojo con 2 o menos).
- **Fila de la entrada:** máximo 5 grupos; mientras esperan, la paciencia baja al 35 % del ritmo normal.
- **Precios de insumos:** carne $12, pollo $10, papas $5, verdura $4, pan $3, cerveza $9, refresco $5, hielo $2 y Monster $12. Se bajaron para que el límite real sea el almacén y no el dinero.

### Cómo se balanceó

`tests/simulador_partida.tscn` simula a un jugador que respeta los límites reales de Dani: camina a su velocidad, usa sprint con estamina, mantiene Espacio para limpiar, carga 3 platillos y tarda en decidir. Con ese simulador se juega la temporada completa y se ajustan los valores anteriores:

```powershell
godot --headless --path . res://tests/simulador_partida.tscn -- dificil 3
```
- **Mejoras** (reporte de cierre, al superar la jornada). El segundo nivel cuesta más que el primero:

  | Mejora | Efecto | Costo por nivel |
  |---|---|---|
  | Tenis nuevos | +15 % de velocidad por nivel | $400 / $800 |
  | Bandeja grande | Cuarto espacio en la bandeja | $600 |
  | Parrilla industrial | La cocina prepara 25 % más rápido | $650 |
  | Estantes extra | +30 de almacén por nivel | $350 / $700 |
  | Trapeador industrial | Limpiar toma 40 % menos | $500 |
  | Proveedor preferente | Urgentes 30 % más baratos y más rápidos | $550 |
  | Promoción 2x1 (consumible) | Siguiente jornada: ~40 % más clientes y cada pedido da +$15 y +1 % de reputación | $300 |

- **Eventos del partido:** 1 evento en el Nivel 1, 1–2 en la Liguilla y 2 en la Gran Final, sin repetirse:
  - **Retraso del proveedor:** los urgentes tardan 50 % más durante 20 minutos del partido.
  - **Crítico gastronómico:** entra primero a la fila. Si se le atiende, da +10 % de reputación; si se va, quita 15 %.
  - **Apagón:** la cocina y la barra se detienen 10 s.
  - **Penales:** si al 90' el marcador va empatado, hay 20 s más de partido y otra ronda de bebidas.
- **Reto Imposible** (solo en Selección de nivel, siempre disponible): una Gran Final con el balance original de Difícil. Usa los insumos anteriores (×1.67), partidos 30 s más largos, VIP con 60 % de paciencia, la fila al 50 %, parejas 35 % y familias 30 % desde el inicio, sin piso de reputación y sin mejoras. No guarda ni afecta la campaña.
- **Selección de nivel:** los niveles 1–3 se desbloquean al superarlos en la campaña.

Los precios y las recetas están en `scripts/core/catalogo.gd`, y los valores de progresión en `scripts/autoload/game_state.gd`.
- **Tutorial de la Jornada 1** (`scripts/ui/tutorial.gd`): franja de objetivos sobre el HUD que avanza al cumplir cada paso. Tiene tres partes: pueblo (moverse, Shift, tablet, inventario y entrar a una tienda), tienda (menú del vendedor) y práctica en La 501 con un `ClientePractica`, que no se desespera, no gasta inventario y no cuenta en las ventas. El reloj de la mañana y el del partido no corren durante el tutorial. Se guarda cuáles ya se vieron (`GameState.tutoriales`) y **T** los omite todos.
- **Árboles del pueblo:** los de 2 tiles ponen el tronco (sólido) en la capa Objetos y la copa en la capa Copas, que se dibuja encima de los personajes.
- **Escenas y nodos:** todo el juego está armado con escenas `.tscn` editables. Dani (`dani.tscn`) tiene su `Camera2D` como nodo hijo; en `town.tscn` está activada y limitada al mapa (0, 0, 2592, 1440). Los clientes son escenas heredadas de `cliente.tscn`. Las mesas, estaciones, puertas y pláticas son `Interactuable` (Area2D) cuya señal `usado` se conecta en la escena. La interfaz usa el Theme `Assets/tema/tema.tres` y las ventanas heredan de `panel_modal.tscn`.
