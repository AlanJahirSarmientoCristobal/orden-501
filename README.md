# ORDEN 501

Videojuego 2D de estrategia y gestión creado con Godot 4.7.2 e inspirado en los procesos reales del restaurante La 501. El proyecto conserva la campaña de exploración anterior como modo alternativo.

## Modo ORDEN 501

El jugador es Dani, Gerente Digital de La 501, y debe estabilizar el restaurante a lo largo de tres niveles:

1. **Orden en la casa:** administrar ingredientes, pedidos y reabasto sin sufrir quiebres de stock.
2. **Reservas sin fallas:** confirmar reservaciones y asignar mesas sin duplicar horarios.
3. **Temporada baja, ventas altas:** utilizar promociones, reportes y decisiones operativas para alcanzar la meta de ventas.

El sistema incluye inventario consumido por recetas, alertas de stock bajo, entregas demoradas del proveedor, calendario de reservas, clientes reservados, conflictos de mesa, promociones, reportes del turno, reputación mínima de 70%, guardado independiente y dificultad Fácil, Normal o Difícil.

## Campaña de exploración anterior

La campaña se desarrolla en cinco mapas conectados mediante zonas de viaje: Barrio 501, Mercado Central, Estadio 501, Parque y Ribera y Zona Industrial. Incluye:

- 15 misiones principales ampliadas, con objetivos persistentes repartidos entre distintos mapas.
- Recolección, exploración, entrevistas, reparto, promoción y circuitos de entrenamiento.
- Selección de dificultad Fácil, Normal y Difícil al comenzar una nueva partida.
- La dificultad modifica objetivos, recompensas, metas y tiempo de los turnos, paciencia de clientes y velocidad de cocina.
- Portales de viaje, rutas secundarias, trivia deportiva y trabajos diarios repetibles en cada distrito.
- Ciclo día/noche y guardado automático en `user://la501_campaign.json`.
- Tres jornadas de restaurante integradas como misiones especiales.

## Ejecutar

1. Abre `project.godot` con Godot 4.7.2 o una versión compatible de Godot 4.
2. Presiona `F6` para ejecutar una escena o `F5` para iniciar desde el menú.

Controles:

- `WASD` o flechas: movimiento.
- `Shift`: correr durante el minijuego del restaurante.
- `Espacio` o `Enter`: interactuar.
- Acércate a los marcadores de viaje y pulsa `Espacio` para cambiar de mapa.
- `E`: escáner de demanda dentro del restaurante.
- En ORDEN 501, `E`: abrir el Panel de Gestión.
- En ORDEN 501, `Tab`: consultar el reporte completo del turno.
- `Q`: desechar el plato más antiguo dentro del restaurante.
- `Esc`: pausar o reanudar.

## Prueba rápida

Las escenas de prueba validan el modo de gestión, la campaña y el servicio del restaurante.

```powershell
godot --headless --path . res://tests/gameplay_smoke_test.tscn
godot --headless --path . res://tests/campaign_smoke_test.tscn
godot --headless --path . res://tests/business_management_smoke_test.tscn
```

## Recursos visuales

Los sprites activos provienen de los paquetes CC0 de Kenney incluidos en `Assets/sprites`. Consulta `THIRD_PARTY_LICENSES.md`. El antiguo `Assets/Player.png` ya no está referenciado por ninguna escena.
