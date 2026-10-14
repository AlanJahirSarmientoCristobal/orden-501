import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generar_plantilla_comida import CUADRO, ICONOS, RAIZ, posicion, tamano_hoja

CARPETA = os.path.join(RAIZ, "Assets", "sprites", "comida")


def cortar(ruta_hoja):
    hoja = Image.open(ruta_hoja).convert("RGBA")
    if hoja.size != tamano_hoja():
        sys.exit("La hoja debe medir %d x %d px y mide %d x %d." % (*tamano_hoja(), *hoja.size))
    guardados = 0
    for i, (clave, nombre, _, _) in enumerate(ICONOS):
        x, y = posicion(i)
        icono = hoja.crop((x, y, x + CUADRO, y + CUADRO))
        if icono.getbbox() is None:
            print("vacío   %-22s (%s)" % (clave, nombre))
            continue
        icono.save(os.path.join(CARPETA, clave + ".png"))
        guardados += 1
        print("listo   %-22s (%s)" % (clave, nombre))
    print("%d íconos guardados en %s" % (guardados, CARPETA))


if __name__ == "__main__":
    cortar(sys.argv[1] if len(sys.argv) > 1 else os.path.join(CARPETA, "hoja_iconos.png"))
