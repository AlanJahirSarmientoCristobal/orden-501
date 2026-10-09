import sys
from collections import deque
from pathlib import Path

from PIL import Image

ALTURA_FINAL = 40

def es_fondo(pixel):
    r, g, b, a = pixel
    if a < 20:
        return True
    claro = min(r, g, b) >= 185
    gris = max(r, g, b) - min(r, g, b) <= 22
    return claro and gris

def quitar_fondo(img):
    ancho, alto = img.size
    px = img.load()
    visto = [[False] * alto for _ in range(ancho)]
    cola = deque()
    for x in range(ancho):
        cola.append((x, 0))
        cola.append((x, alto - 1))
    for y in range(alto):
        cola.append((0, y))
        cola.append((ancho - 1, y))
    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= ancho or y >= alto or visto[x][y]:
            continue
        visto[x][y] = True
        if not es_fondo(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return img

def columnas_con_contenido(img):
    ancho, alto = img.size
    px = img.load()
    return [any(px[x, y][3] > 0 for y in range(alto)) for x in range(ancho)]

def segmentos(columnas, separacion_min=6):
    resultado, inicio, vacias = [], None, 0
    for x, lleno in enumerate(columnas):
        if lleno:
            if inicio is None:
                inicio = x
            vacias = 0
            fin = x
        elif inicio is not None:
            vacias += 1
            if vacias >= separacion_min:
                resultado.append((inicio, fin))
                inicio = None
    if inicio is not None:
        resultado.append((inicio, fin))
    return resultado

def main():
    raiz = Path(__file__).resolve().parent.parent
    hoja = Path(sys.argv[1]) if len(sys.argv) > 1 else raiz / "Assets/sprites/monster/monster_hoja.png"
    if not hoja.exists():
        sys.exit(f"No se encontró la hoja: {hoja}")
    img = quitar_fondo(Image.open(hoja).convert("RGBA"))
    partes = segmentos(columnas_con_contenido(img))
    destino = hoja.parent
    for i, (x0, x1) in enumerate(partes, start=1):
        recorte = img.crop((x0, 0, x1 + 1, img.height))
        recorte = recorte.crop(recorte.getbbox())
        escala = ALTURA_FINAL / recorte.height
        recorte = recorte.resize((max(1, round(recorte.width * escala)), ALTURA_FINAL), Image.NEAREST)
        salida = destino / f"monster_{i}.png"
        recorte.save(salida)
        print(f"{salida.name}: {recorte.width}x{recorte.height}")
    print(f"{len(partes)} diseños recortados.")

if __name__ == "__main__":
    main()
