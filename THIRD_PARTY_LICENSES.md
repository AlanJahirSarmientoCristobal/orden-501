# Licencias de recursos de terceros

El único recurso de terceros del proyecto es la fuente **Kenney Pixel** (Kenney Fonts), usada en el menú de compra. Está publicada bajo Creative Commons Zero (CC0 1.0): puede emplearse en proyectos personales, educativos y comerciales, y la atribución es opcional. Licencia en `Assets/fonts/License_kenney_fonts.txt`. Sitio del autor: https://kenney.nl/

Todos los gráficos son originales del proyecto:

- Los personajes (`Assets/sprites/personajes/`, generados con `tools/generar_personajes.py`).
- Los íconos de comida (`Assets/sprites/comida/`, generados con `tools/generar_iconos_comida.py`).
- El pueblo (`Assets/sprites/pueblo/pueblo.png`): calles, banquetas, edificios, autos, árboles y objetos, generado con `tools/generar_pueblo.py`.
- Los interiores (`Assets/sprites/interiores/interiores.png` y `muebles.png`): muros, pisos, muebles, equipo y productos, generados con `tools/generar_interiores.py`.
- Las pantallas del partido y el letrero de neón (`Assets/sprites/restaurante/`), generados con `tools/generar_sprites_restaurante.py`.
- Los 7 diseños del Monster (`Assets/sprites/monster/`).

La música y los efectos de sonido se generan por código en `scripts/autoload/audio_manager.gd`; no se usan archivos de audio de terceros.

El código original de este proyecto no queda cubierto automáticamente por la licencia CC0 de la fuente. Se recomienda añadir una licencia propia antes de distribuir el repositorio.
