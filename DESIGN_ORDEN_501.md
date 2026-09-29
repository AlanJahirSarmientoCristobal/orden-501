# Adaptación de la propuesta ORDEN 501

Este modo traduce la propuesta académica a sistemas jugables sin eliminar la campaña de exploración existente.

## Bucle principal

El jugador se mueve por el restaurante, toma comandas, recoge platos de cocina, entrega pedidos y limpia mesas. Simultáneamente administra el negocio desde el Panel de Gestión.

Cada pedido utiliza ingredientes reales del inventario. Si falta algún ingrediente, la cocina rechaza temporalmente la comanda y el jugador debe solicitar reabasto al proveedor. La entrega tarda varios segundos y cuesta monedas, por lo que anticiparse es más eficiente que reaccionar al desabasto.

## Reservaciones

Las reservaciones incluyen identificador, horario y tamaño del grupo. El jugador asigna una mesa desde el calendario. El sistema detecta cuando dos grupos reciben la misma mesa en el mismo horario, resta reputación y registra el error en el reporte. Las reservas confirmadas aparecen posteriormente como clientes reservados en la mesa seleccionada.

## Promociones y reportes

En el tercer nivel se desbloquean la campaña en redes y el Combo 501. Ambas consumen fondos y aumentan temporalmente el flujo de clientes. El reporte accesible con `Tab` resume ventas, pedidos entregados, reputación, quiebres de stock, reservas, duplicidades y promociones.

## Dificultad

- Fácil: más inventario, entregas rápidas, más tiempo y metas económicas menores.
- Normal: balance base de la propuesta.
- Difícil: menos inventario, proveedor más lento, menos tiempo y metas superiores.

## Progresión

- Nivel 1: terminar el turno sin quiebres de stock.
- Nivel 2: confirmar la cantidad solicitada de reservaciones sin duplicidades.
- Nivel 3: activar una promoción y alcanzar la meta de ventas.
- Todos los niveles exigen al menos 70% de reputación.

El progreso de este modo se guarda en `user://orden501_management.json`; la campaña anterior conserva su archivo `user://la501_campaign.json`.
