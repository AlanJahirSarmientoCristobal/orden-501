# Licencias de recursos de terceros

Parte de los gráficos del proyecto viene de paquetes de Kenney publicados bajo Creative Commons Zero (CC0 1.0). Pueden emplearse en proyectos personales, educativos y comerciales; la atribución es opcional.

- **Roguelike RPG Pack**, Kenney: paredes, tapetes, toldos, ventanas, estantes y comida de los interiores (`Assets/sprites/interiores/interiores.png`). Licencia en `Assets/sprites/interiores/License_roguelike_rpg.txt`.
- **Roguelike Indoors**, Kenney: mostradores, estufas y fregadero (`Assets/sprites/interiores/muebles.png`). Licencia en `Assets/sprites/interiores/License_roguelike_indoor.txt`.
- **Kenney Fonts** (Kenney Pixel, usada en el menú de compra). Licencia en `Assets/fonts/License_kenney_fonts.txt`.

Sitio del autor: https://kenney.nl/

Son originales del proyecto:

- Los personajes (`Assets/sprites/personajes/`, generados con `tools/generar_personajes.py`).
- Los íconos de comida (`Assets/sprites/comida/`, generados con `tools/generar_iconos_comida.py`).
- Todo el pueblo (`Assets/sprites/pueblo/pueblo.png`): calles, banquetas, edificios, autos, árboles y objetos, generado con `tools/generar_pueblo.py`.
- Los pisos, barriles, caja, refrigerador, sillas, mesas y macetas de los interiores, generados con `tools/generar_interiores.py`.
- Las pantallas del partido y el letrero de neón (`Assets/sprites/restaurante/`), generados con `tools/generar_sprites_restaurante.py`.
- Los 7 diseños del Monster (`Assets/sprites/monster/`).

La música y los efectos de sonido se generan por código en `scripts/autoload/audio_manager.gd`; no se usan archivos de audio de terceros.

El código original de este proyecto no queda cubierto automáticamente por las licencias CC0 de los recursos. Se recomienda añadir una licencia propia antes de distribuir el repositorio.
