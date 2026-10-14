import os
from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(RAIZ, "Assets", "sprites")


def lienzo(ancho=16, alto=16):
    img = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def contorno(img, color):
    ancho, alto = img.size
    fuente = img.load()
    copia = img.copy()
    destino = copia.load()
    for y in range(alto):
        for x in range(ancho):
            if fuente[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < ancho and 0 <= ny < alto and fuente[nx, ny][3] != 0:
                    destino[x, y] = color + (255,)
                    break
    return copia


def pegar(hoja, paso, columna, fila, img):
    for i in range(img.height // 16):
        for j in range(img.width // 16):
            hoja.paste(img.crop((16 * j, 16 * i, 16 * j + 16, 16 * i + 16)), ((columna + j) * paso, (fila + i) * paso))


def ruido(x, y, semilla=0):
    n = (x * 374761393 + y * 668265263 + semilla * 982451653) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return (n ^ (n >> 16)) % 100


def textura(funcion, ancho=16, alto=16):
    img = Image.new("RGBA", (ancho, alto))
    px = img.load()
    for y in range(alto):
        for x in range(ancho):
            px[x, y] = funcion(x, y) + (255,)
    return img


def oscurecer(color, factor):
    return tuple(max(0, min(255, int(v * factor))) for v in color[:3])


def sombrear_filas(img, filas, factor):
    px = img.load()
    for y in filas:
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = oscurecer((r, g, b), factor) + (a,)


def lados_de(columna, fila):
    lados = set()
    if fila == 0:
        lados.add("arriba")
    if fila == 2:
        lados.add("abajo")
    if columna == 0:
        lados.add("izq")
    if columna == 2:
        lados.add("der")
    return lados


def franja(img, lados, colores):
    px = img.load()
    for i, color in reversed(list(enumerate(colores))):
        for k in range(16):
            if "arriba" in lados:
                px[k, i] = color + (255,)
            if "abajo" in lados:
                px[k, 15 - i] = color + (255,)
            if "izq" in lados:
                px[i, k] = color + (255,)
            if "der" in lados:
                px[15 - i, k] = color + (255,)


def nueve(hoja, paso, columna, fila, relleno, borde):
    for f in range(3):
        for c in range(3):
            img = textura(relleno)
            borde(img, lados_de(c, f))
            pegar(hoja, paso, columna + c, fila + f, img)
