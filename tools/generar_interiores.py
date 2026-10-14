import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_art import RAIZ, SPRITES, contorno, franja, lienzo, nueve, pegar, ruido, sombrear_filas, textura

INTERIORES = os.path.join(SPRITES, "interiores", "interiores.png")
MUEBLES = os.path.join(SPRITES, "interiores", "muebles.png")

MADERA = (185, 139, 94)
MADERA_CLARA = (200, 164, 128)
MADERA_OSCURA = (143, 103, 63)
MADERA_BORDE = (96, 64, 36)


def piso_madera():
    img, d = lienzo()
    tonos = ((185, 139, 94), (178, 133, 89), (188, 143, 97), (176, 131, 87))
    juntas = (5, 12, 2, 9)
    for i in range(4):
        y = i * 4
        d.rectangle([0, y, 15, y + 3], fill=tonos[i])
        d.line([(0, y + 3), (15, y + 3)], fill=(160, 118, 78))
        d.line([(juntas[i], y), (juntas[i], y + 2)], fill=(150, 108, 70))
        d.point(((juntas[i] + 6) % 16, y + 1), fill=(198, 154, 108))
    return img


def piso_baldosa(base, alterno, junta, brillo):
    img, d = lienzo()
    for ty in range(2):
        for tx in range(2):
            x, y = tx * 8, ty * 8
            d.rectangle([x, y, x + 7, y + 7], fill=base if (tx + ty) % 2 == 0 else alterno)
            d.line([(x, y), (x + 5, y)], fill=brillo)
            d.line([(x, y), (x, y + 5)], fill=brillo)
            d.line([(x + 7, y), (x + 7, y + 7)], fill=junta)
            d.line([(x, y + 7), (x + 7, y + 7)], fill=junta)
    return img


def barril(madera, clara, oscura, aro, borde):
    img, d = lienzo()
    d.rounded_rectangle([4, 5, 11, 15], radius=2, fill=madera)
    d.line([(5, 6), (5, 14)], fill=clara)
    d.line([(8, 7), (8, 13)], fill=oscura)
    d.line([(10, 6), (10, 14)], fill=oscura)
    d.line([(4, 8), (11, 8)], fill=aro)
    d.line([(4, 12), (11, 12)], fill=aro)
    d.line([(5, 5), (10, 5)], fill=clara)
    return contorno(img, borde)


def caja():
    img, d = lienzo()
    d.rectangle([4, 4, 12, 13], fill=(204, 154, 98))
    d.rectangle([6, 6, 10, 11], fill=(176, 124, 72))
    d.line([(6, 6), (10, 11)], fill=(214, 166, 110))
    d.line([(10, 6), (6, 11)], fill=(214, 166, 110))
    d.line([(4, 4), (12, 4)], fill=(232, 186, 130))
    return contorno(img, (96, 62, 36))


def refri():
    img, d = lienzo(16, 32)
    cuerpo, claro, oscuro, manija = (55, 170, 165), (68, 187, 182), (40, 125, 121), (232, 244, 242)
    d.rounded_rectangle([2, 1, 13, 29], radius=2, fill=cuerpo)
    d.line([(3, 2), (3, 28)], fill=claro)
    d.line([(12, 2), (12, 28)], fill=oscuro)
    d.line([(2, 11), (13, 11)], fill=oscuro)
    d.line([(4, 12), (11, 12)], fill=claro)
    d.line([(10, 4), (10, 8)], fill=manija)
    d.line([(10, 15), (10, 22)], fill=manija)
    d.rectangle([5, 3, 7, 4], fill=claro)
    d.point((3, 30), fill=(40, 44, 50))
    d.point((4, 30), fill=(40, 44, 50))
    d.point((11, 30), fill=(40, 44, 50))
    d.point((12, 30), fill=(40, 44, 50))
    return contorno(img, (20, 70, 68))


def silla_frente():
    img, d = lienzo()
    d.rectangle([4, 4, 11, 8], fill=MADERA)
    d.line([(4, 4), (11, 4)], fill=MADERA_CLARA)
    d.line([(5, 6), (10, 6)], fill=MADERA_OSCURA)
    d.rectangle([4, 9, 11, 12], fill=(198, 101, 39))
    d.line([(5, 9), (10, 9)], fill=(226, 134, 64))
    d.line([(4, 12), (11, 12)], fill=MADERA_OSCURA)
    d.line([(4, 13), (4, 14)], fill=MADERA_OSCURA)
    d.line([(11, 13), (11, 14)], fill=MADERA_OSCURA)
    return contorno(img, MADERA_BORDE)


def silla_espalda():
    img, d = lienzo()
    d.rectangle([4, 1, 11, 8], fill=MADERA)
    d.line([(4, 1), (11, 1)], fill=MADERA_CLARA)
    d.line([(5, 3), (10, 3)], fill=MADERA_OSCURA)
    d.line([(5, 6), (10, 6)], fill=MADERA_OSCURA)
    d.rectangle([4, 9, 11, 10], fill=MADERA_CLARA)
    d.point((4, 11), fill=MADERA_OSCURA)
    d.point((11, 11), fill=MADERA_OSCURA)
    return contorno(img, MADERA_BORDE)


def mesa(ancho):
    img, d = lienzo(ancho, 16)
    fin = ancho - 2
    patas = (6, ancho - 8) if ancho > 16 else (7,)
    for x in patas:
        d.rectangle([x, 11, x + 1, 14], fill=MADERA_OSCURA)
    if ancho == 16:
        d.line([(5, 14), (10, 14)], fill=MADERA_OSCURA)
    d.ellipse([1, 2, fin, 12], fill=MADERA)
    d.ellipse([1, 1, fin, 10], fill=MADERA_CLARA)
    d.ellipse([4, 2, 4 + ancho // 4, 5], fill=(218, 186, 152))
    return contorno(img, (110, 76, 44))


def planta(alta):
    img, d = lienzo()
    tope = 1 if alta else 4
    hoja, hoja_clara = (108, 192, 64), (160, 226, 96)
    d.polygon([(7, 10), (3, tope + 4), (6, tope + 6)], fill=hoja)
    d.polygon([(8, 10), (12, tope + 3), (9, tope + 6)], fill=hoja)
    d.polygon([(7, 10), (7, tope), (9, tope + 5), (8, 10)], fill=hoja_clara)
    d.rectangle([5, 10, 10, 14], fill=(52, 160, 150))
    d.line([(4, 10), (11, 10)], fill=(84, 196, 184))
    d.line([(10, 11), (10, 14)], fill=(36, 116, 110))
    return contorno(img, (28, 70, 40))


ROBLE = (176, 128, 80)
ROBLE_CLARO = (206, 160, 106)
NOGAL = (132, 84, 48)
NOGAL_OSCURO = (98, 62, 36)
NOGAL_BORDE = (70, 44, 26)
HERRERIA = (40, 40, 46)
ACERO = (176, 182, 192)
ACERO_CLARO = (214, 220, 228)
ACERO_OSCURO = (120, 126, 138)
VIDRIO = (150, 200, 220)
VIDRIO_BRILLO = (210, 236, 246)
TERRACOTA = (196, 92, 58)
CREMA = (240, 226, 200)
OLIVO = (112, 146, 74)
CEMENTO = (150, 150, 154)
TRANSPARENTE = (0, 0, 0, 0)


def adobe(x, y):
    r = ruido(x, y, 21)
    if r < 10:
        return (150, 128, 102)
    if r < 16:
        return (176, 154, 126)
    return (164, 140, 112)


def muro_alto(lados, esquina=None):
    img = textura(adobe)
    franja(img, lados, [(92, 74, 58), (190, 168, 138)])
    if esquina:
        img.putpixel(esquina, (92, 74, 58, 255))
    return img


def yeso(x, y):
    r = ruido(x, y, 22)
    if r < 8:
        return (224, 212, 190)
    if r < 13:
        return (242, 234, 218)
    return (234, 224, 204)


def pared_superior():
    img = textura(yeso)
    d = ImageDraw.Draw(img)
    d.line([(0, 0), (15, 0)], fill=(92, 62, 38))
    d.line([(0, 1), (15, 1)], fill=(132, 90, 56))
    d.line([(0, 2), (15, 2)], fill=(206, 194, 172))
    return img


def pared_inferior():
    img = textura(yeso)
    d = ImageDraw.Draw(img)
    d.line([(0, 4), (15, 4)], fill=ROBLE_CLARO)
    d.rectangle([0, 5, 15, 13], fill=ROBLE)
    for x in range(3, 16, 4):
        d.line([(x, 5), (x, 13)], fill=(140, 98, 60))
    d.line([(0, 14), (15, 14)], fill=NOGAL_OSCURO)
    d.line([(0, 15), (15, 15)], fill=NOGAL_BORDE)
    return img


def ventana_arco():
    img = Image.new("RGBA", (16, 32))
    img.paste(pared_superior(), (0, 0))
    img.paste(pared_inferior(), (0, 16))
    vidrio, d = lienzo(16, 32)
    d.ellipse([1, 2, 14, 15], fill=NOGAL)
    d.rectangle([1, 9, 14, 29], fill=NOGAL)
    d.ellipse([3, 4, 12, 13], fill=VIDRIO)
    d.rectangle([3, 9, 12, 27], fill=VIDRIO)
    d.ellipse([4, 5, 11, 12], fill=(184, 220, 236))
    d.rectangle([4, 9, 11, 12], fill=(170, 212, 230))
    d.line([(7, 4), (7, 27)], fill=HERRERIA)
    d.line([(8, 4), (8, 27)], fill=HERRERIA)
    d.line([(3, 14), (12, 14)], fill=HERRERIA)
    d.line([(3, 21), (12, 21)], fill=HERRERIA)
    d.line([(4, 18), (6, 16)], fill=VIDRIO_BRILLO)
    d.line([(9, 25), (11, 23)], fill=VIDRIO_BRILLO)
    d.rectangle([0, 28, 15, 29], fill=ROBLE_CLARO)
    d.line([(0, 30), (15, 30)], fill=NOGAL_OSCURO)
    img.alpha_composite(contorno(vidrio, NOGAL_BORDE))
    return img


def tapete(x, y):
    cx, cy = x % 8, y % 8
    distancia = abs(cx - 3) + abs(cy - 3)
    if distancia == 0:
        return (60, 110, 96)
    if distancia == 2:
        return CREMA
    return (170, 70, 48) if ruido(x, y, 23) < 12 else (180, 76, 52)


def borde_tapete(img, lados):
    franja(img, lados, [(86, 48, 32), CREMA, CREMA, (60, 110, 96), (180, 76, 52)])


def lona(color, con_poste):
    img, d = lienzo()
    alto = 5 if con_poste else 15
    for x in range(16):
        tono = color if x % 8 < 4 else CREMA
        d.line([(x, 0), (x, alto)], fill=tono)
        if con_poste and x % 4 in (1, 2):
            d.point((x, alto + 1), fill=tono)
    sombrear_filas(img, (0,), 0.7)
    if not con_poste:
        sombrear_filas(img, (13, 14, 15), 0.9)
        return img
    sombrear_filas(img, (alto, alto + 1), 0.85)
    d.rectangle([1, alto + 2, 2, 15], fill=NOGAL)
    d.line([(1, alto + 2), (1, 15)], fill=ROBLE)
    return contorno(img, NOGAL_BORDE)


def mesa_puesto(pieza):
    img, d = lienzo()
    d.line([(0, 5), (15, 5)], fill=ROBLE_CLARO)
    d.rectangle([0, 6, 15, 8], fill=ROBLE)
    d.line([(0, 9), (15, 9)], fill=NOGAL_OSCURO)
    d.rectangle([0, 10, 15, 11], fill=(140, 96, 58))
    d.line([(0, 12), (15, 12)], fill=NOGAL_BORDE)
    for x in (4, 11):
        d.point((x, 7), fill=(150, 108, 66))
    if pieza == "izq":
        d.rectangle([0, 0, 2, 15], fill=NOGAL_OSCURO)
        d.line([(0, 0), (0, 15)], fill=NOGAL)
    if pieza == "der":
        d.rectangle([13, 0, 15, 15], fill=NOGAL_OSCURO)
        d.line([(13, 0), (13, 15)], fill=NOGAL)
    return img


def caja_producto(colores, ancho_completo=False):
    img, d = lienzo()
    x0, x1 = (1, 14) if ancho_completo else (2, 13)
    total = len(colores)
    for i, (color, brillo) in enumerate(colores):
        cx = x0 + 3 + (i * (x1 - x0 - 6)) // (total - 1) if total > 1 else 8
        d.ellipse([cx - 3, 3, cx + 3, 9], fill=color)
        d.point((cx - 1, 4), fill=brillo)
        d.point((cx, 4), fill=brillo)
    d.rectangle([x0, 7, x1, 14], fill=ROBLE)
    d.line([(x0, 7), (x1, 7)], fill=ROBLE_CLARO)
    for y in (10, 13):
        d.line([(x0, y), (x1, y)], fill=NOGAL)
    return contorno(img, NOGAL_BORDE)


def botella(color, claro, etiqueta):
    img, d = lienzo()
    d.rectangle([7, 2, 8, 5], fill=color)
    d.point((7, 1), fill=ROBLE)
    d.point((8, 1), fill=ROBLE)
    d.rounded_rectangle([5, 6, 10, 14], radius=1, fill=color)
    d.line([(6, 7), (6, 13)], fill=claro)
    d.rectangle([5, 9, 10, 11], fill=etiqueta)
    return contorno(img, (34, 30, 30))


def bolillos():
    img, d = lienzo()
    d.rectangle([2, 9, 13, 12], fill=CREMA)
    for x in (3, 8):
        d.ellipse([x, 5, x + 5, 10], fill=(214, 150, 72))
        d.line([(x + 1, 7), (x + 4, 7)], fill=(246, 206, 140))
    return contorno(img, (110, 70, 34))


def pollo_asado():
    img, d = lienzo()
    d.ellipse([1, 8, 14, 14], fill=(244, 244, 238))
    d.ellipse([3, 4, 12, 12], fill=(196, 112, 50))
    d.ellipse([4, 5, 8, 8], fill=(232, 156, 82))
    d.rectangle([11, 4, 13, 6], fill=(196, 112, 50))
    d.point((14, 3), fill=(244, 244, 238))
    d.point((2, 11), fill=(100, 170, 70))
    d.point((13, 11), fill=(100, 170, 70))
    return contorno(img, (90, 50, 26))


def corte_carne():
    img, d = lienzo()
    d.polygon([(2, 7), (13, 6), (14, 12), (3, 13)], fill=CREMA)
    d.ellipse([4, 6, 12, 12], fill=(196, 58, 64))
    d.ellipse([5, 7, 9, 9], fill=(232, 98, 96))
    d.point((10, 10), fill=(246, 222, 200))
    return contorno(img, (96, 40, 36))


def plato_tacos():
    img, d = lienzo()
    d.ellipse([1, 4, 14, 13], fill=(244, 244, 238))
    d.ellipse([3, 6, 12, 11], fill=(220, 220, 214))
    for x in (4, 8):
        d.ellipse([x, 6, x + 4, 10], fill=(240, 206, 120))
        d.point((x + 2, 7), fill=(200, 60, 50))
        d.point((x + 1, 8), fill=(100, 170, 70))
        d.point((x + 3, 8), fill=(250, 240, 220))
    return contorno(img, (90, 86, 80))


def cazuela():
    img, d = lienzo()
    d.ellipse([3, 6, 12, 14], fill=(176, 80, 48))
    d.ellipse([3, 5, 12, 10], fill=(206, 104, 64))
    d.ellipse([4, 6, 11, 9], fill=(150, 44, 36))
    d.point((6, 7), fill=(236, 120, 80))
    d.point((2, 8), fill=(176, 80, 48))
    d.point((13, 8), fill=(176, 80, 48))
    return contorno(img, (84, 36, 24))


def barril_cerveza_tirada():
    img, d = lienzo(32, 32)
    d.rounded_rectangle([6, 2, 25, 31], radius=3, fill=ACERO)
    d.line([(7, 4), (7, 30)], fill=ACERO_CLARO)
    d.line([(24, 4), (24, 30)], fill=ACERO_OSCURO)
    d.rectangle([9, 4, 22, 6], fill=NOGAL)
    d.rectangle([12, 4, 19, 6], fill=(214, 160, 60))
    for x in (10, 15, 20):
        d.rectangle([x, 7, x + 1, 8], fill=HERRERIA)
        d.rectangle([x, 9, x + 1, 11], fill=(214, 170, 72))
    d.rectangle([9, 13, 22, 14], fill=(70, 74, 84))
    d.line([(16, 17), (16, 31)], fill=ACERO_OSCURO)
    d.line([(13, 19), (13, 22)], fill=HERRERIA)
    d.line([(18, 19), (18, 22)], fill=HERRERIA)
    d.rectangle([5, 24, 26, 27], fill=ROBLE)
    d.line([(5, 24), (26, 24)], fill=ROBLE_CLARO)
    d.line([(5, 27), (26, 27)], fill=NOGAL)
    return contorno(img, (54, 58, 66))


def enfriador():
    img, d = lienzo(16, 32)
    d.rectangle([1, 1, 14, 31], fill=HERRERIA)
    d.rectangle([3, 3, 12, 29], fill=(34, 40, 48))
    d.line([(3, 3), (12, 3)], fill=(255, 240, 200))
    colores = ((196, 128, 40), (72, 140, 60), (150, 80, 40), (200, 60, 50))
    for i, y in enumerate((10, 18, 26)):
        d.line([(3, y), (12, y)], fill=ACERO_OSCURO)
        for j, x in enumerate((4, 6, 8, 10)):
            color = colores[(i + j) % 4]
            d.rectangle([x, y - 4, x + 1, y - 1], fill=color)
            d.point((x, y - 5), fill=color)
    d.line([(4, 14), (7, 11)], fill=(90, 110, 124))
    d.line([(2, 12), (2, 18)], fill=ROBLE_CLARO)
    return img


def hielera(maquina):
    img, d = lienzo()
    d.rounded_rectangle([2, 2, 13, 15], radius=2, fill=ACERO)
    d.line([(3, 3), (3, 14)], fill=ACERO_CLARO)
    d.line([(12, 3), (12, 14)], fill=ACERO_OSCURO)
    if maquina:
        d.rectangle([4, 4, 11, 6], fill=(40, 44, 52))
        d.point((5, 5), fill=(90, 200, 120))
        d.point((7, 5), fill=(90, 160, 230))
        d.point((9, 5), fill=(90, 160, 230))
        d.rectangle([6, 9, 9, 13], fill=(60, 64, 72))
    else:
        d.line([(2, 6), (13, 6)], fill=ACERO_OSCURO)
        d.rectangle([4, 9, 11, 11], fill=(70, 140, 210))
        d.line([(5, 10), (10, 10)], fill=(236, 244, 250))
        d.line([(6, 4), (9, 4)], fill=HERRERIA)
    return contorno(img, (70, 76, 88))


def estante(con_cajon):
    img = textura(lambda x, y: (88, 58, 34))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 1], fill=NOGAL)
    d.rectangle([0, 0, 1, 15], fill=NOGAL)
    d.rectangle([14, 0, 15, 15], fill=NOGAL)
    for y in (6, 11):
        d.line([(1, y), (14, y)], fill=ROBLE_CLARO)
        d.line([(1, y + 1), (14, y + 1)], fill=NOGAL)
    if con_cajon:
        d.rectangle([2, 12, 13, 15], fill=ROBLE)
        d.line([(7, 13), (8, 13)], fill=HERRERIA)
    else:
        d.line([(0, 15), (15, 15)], fill=NOGAL_BORDE)
    return img


def cemento(x, y):
    r = ruido(x, y, 24)
    if r < 8:
        return (134, 134, 140)
    if r < 12:
        return (168, 168, 172)
    return CEMENTO


def mostrador(lado="centro", encima=None):
    img = textura(cemento)
    d = ImageDraw.Draw(img)
    d.line([(0, 0), (15, 0)], fill=(176, 176, 180))
    d.line([(0, 6), (15, 6)], fill=(196, 196, 200))
    d.rectangle([0, 7, 15, 13], fill=ROBLE)
    d.line([(0, 14), (15, 14)], fill=NOGAL_OSCURO)
    d.line([(0, 15), (15, 15)], fill=TRANSPARENTE)
    for x0 in (1, 8):
        d.rectangle([x0, 8, x0 + 6, 13], outline=(150, 108, 66))
    d.line([(6, 10), (6, 11)], fill=HERRERIA)
    d.line([(9, 10), (9, 11)], fill=HERRERIA)
    if lado in ("izq", "solo"):
        d.line([(0, 0), (0, 14)], fill=NOGAL_BORDE)
    if lado in ("der", "solo"):
        d.line([(15, 0), (15, 14)], fill=NOGAL_BORDE)
    if encima:
        encima(d)
    return img


def tarja(d):
    d.rectangle([3, 1, 12, 5], fill=ACERO_OSCURO)
    d.rectangle([4, 2, 11, 4], fill=ACERO)
    d.point((7, 0), fill=HERRERIA)
    d.point((8, 0), fill=HERRERIA)
    d.point((7, 3), fill=(90, 96, 108))


def ingredientes(d):
    d.rectangle([2, 1, 13, 5], fill=ROBLE_CLARO)
    d.ellipse([3, 1, 7, 5], fill=(100, 176, 80))
    d.rectangle([9, 2, 12, 4], fill=(250, 210, 80))
    d.point((8, 3), fill=(214, 58, 44))


def salsas(d):
    for x, color in ((3, (200, 50, 40)), (6, (90, 160, 70)), (9, (196, 128, 40)), (12, (200, 50, 40))):
        d.rectangle([x, 1, x + 1, 5], fill=color)
        d.point((x, 0), fill=HERRERIA)


def platos(d):
    for x in (2, 8):
        d.ellipse([x, 1, x + 5, 5], fill=(244, 244, 238))
        d.ellipse([x + 1, 2, x + 4, 4], fill=(220, 220, 214))


def talavera(x, y):
    if x % 4 == 3 or y % 4 == 3:
        return (226, 210, 184)
    return TERRACOTA if ((x // 4) + (y // 4)) % 2 == 0 else (180, 82, 52)


def caja_cobro(lado):
    img, d = lienzo()
    img.paste(textura(talavera).crop((0, 0, 16, 8)), (0, 5))
    d.rectangle([0, 0, 15, 3], fill=NOGAL)
    d.line([(0, 0), (15, 0)], fill=(166, 112, 68))
    d.line([(0, 4), (15, 4)], fill=NOGAL_BORDE)
    if lado in ("izq", "solo"):
        d.line([(0, 0), (0, 12)], fill=NOGAL_BORDE)
    if lado in ("der", "solo"):
        d.line([(15, 0), (15, 12)], fill=NOGAL_BORDE)
    return img


def barra_vertical(tipo):
    img, d = lienzo()
    if tipo in ("pase", "pase_fin"):
        d.rectangle([0, 0, 9, 15], fill=CEMENTO)
        d.line([(1, 0), (1, 15)], fill=(176, 176, 180))
        d.line([(0, 0), (0, 15)], fill=(96, 96, 102))
        d.line([(9, 0), (9, 15)], fill=(110, 110, 116))
        if tipo == "pase_fin":
            d.rectangle([0, 8, 9, 14], fill=ROBLE)
            d.rectangle([2, 9, 7, 13], outline=(150, 108, 66))
            d.line([(0, 15), (9, 15)], fill=TRANSPARENTE)
            d.line([(0, 15), (2, 15)], fill=NOGAL_OSCURO)
            d.line([(7, 15), (9, 15)], fill=NOGAL_OSCURO)
        return img
    d.rectangle([0, 0, 9, 15], fill=ROBLE)
    d.line([(1, 0), (1, 15)], fill=ROBLE_CLARO)
    d.line([(0, 0), (0, 15)], fill=NOGAL_BORDE)
    d.line([(9, 0), (9, 15)], fill=NOGAL_OSCURO)
    d.point((5, 4), fill=(150, 108, 66))
    d.point((4, 11), fill=(150, 108, 66))
    if tipo == "barra_fin":
        d.rectangle([0, 10, 9, 15], fill=NOGAL)
        d.rectangle([2, 11, 7, 14], outline=NOGAL_OSCURO)
    return img


def barra_esquina():
    img, d = lienzo()
    d.rectangle([0, 0, 15, 9], fill=ROBLE)
    d.line([(1, 0), (1, 9)], fill=ROBLE_CLARO)
    d.line([(10, 0), (15, 0)], fill=NOGAL_BORDE)
    d.line([(10, 1), (15, 1)], fill=ROBLE_CLARO)
    d.line([(0, 0), (0, 15)], fill=NOGAL_BORDE)
    d.line([(15, 0), (15, 15)], fill=NOGAL_BORDE)
    d.rectangle([1, 10, 14, 15], fill=NOGAL)
    d.rectangle([2, 11, 13, 14], outline=NOGAL_OSCURO)
    d.line([(1, 10), (14, 10)], fill=NOGAL_OSCURO)
    return img


def estufa(comal):
    img, d = lienzo()
    d.rectangle([0, 0, 15, 14], fill=(46, 46, 52))
    d.line([(0, 0), (15, 0)], fill=(80, 80, 88))
    if comal:
        d.rectangle([1, 1, 14, 6], fill=(70, 70, 78))
        for x in (2, 8):
            d.ellipse([x, 2, x + 5, 5], fill=(244, 230, 190))
            d.point((x + 2, 3), fill=(214, 186, 130))
    else:
        for x in (2, 9):
            for y in (1, 4):
                d.ellipse([x, y, x + 4, y + 3], outline=(110, 110, 120))
                d.point((x + 2, y + 1), fill=(240, 120, 50))
    d.line([(0, 7), (15, 7)], fill=(30, 30, 34))
    for x in (2, 6, 9, 13):
        d.point((x, 8), fill=(214, 170, 72))
    d.rectangle([2, 10, 13, 13], fill=(30, 30, 34))
    d.rectangle([4, 11, 11, 12], fill=(60, 60, 68) if comal else (120, 60, 40))
    d.line([(0, 15), (2, 15)], fill=(30, 30, 34))
    d.line([(13, 15), (15, 15)], fill=(30, 30, 34))
    return img


def dibujar_interiores(hoja):
    pegar(hoja, 17, 5, 2, piso_madera())
    pegar(hoja, 17, 6, 2, piso_baldosa((194, 194, 194), (188, 188, 190), (168, 168, 172), (208, 208, 210)))
    pegar(hoja, 17, 7, 2, piso_baldosa((230, 218, 191), (224, 210, 180), (204, 188, 154), (240, 232, 210)))
    pegar(hoja, 17, 23, 0, barril((176, 112, 62), (212, 152, 94), (138, 84, 46), (96, 98, 112), (70, 42, 26)))
    pegar(hoja, 17, 24, 0, barril((122, 78, 46), (156, 104, 64), (92, 58, 34), (184, 190, 204), (48, 30, 20)))
    pegar(hoja, 17, 48, 17, caja())
    pegar(hoja, 17, 36, 3, refri())
    pegar(hoja, 17, 14, 12, muro_alto({"arriba", "abajo"}))
    pegar(hoja, 17, 15, 13, muro_alto({"izq", "der"}))
    pegar(hoja, 17, 16, 12, muro_alto({"arriba", "izq"}, (15, 15)))
    pegar(hoja, 17, 17, 12, muro_alto({"arriba", "der"}, (0, 15)))
    pegar(hoja, 17, 16, 13, muro_alto({"abajo", "izq"}, (15, 0)))
    pegar(hoja, 17, 17, 13, muro_alto({"abajo", "der"}, (0, 0)))
    pegar(hoja, 17, 15, 12, muro_alto({"arriba", "abajo", "der"}))
    pegar(hoja, 17, 13, 12, muro_alto({"arriba", "abajo", "izq"}))
    pegar(hoja, 17, 18, 15, pared_superior())
    pegar(hoja, 17, 13, 15, pared_inferior())
    pegar(hoja, 17, 44, 2, ventana_arco())
    nueve(hoja, 17, 10, 16, tapete, borde_tapete)
    pegar(hoja, 17, 10, 0, lona(TERRACOTA, False))
    pegar(hoja, 17, 11, 0, lona(OLIVO, False))
    pegar(hoja, 17, 10, 1, lona(TERRACOTA, True))
    pegar(hoja, 17, 11, 1, lona(OLIVO, True))
    pegar(hoja, 17, 10, 4, mesa_puesto("centro"))
    pegar(hoja, 17, 10, 5, mesa_puesto("izq"))
    pegar(hoja, 17, 10, 6, mesa_puesto("der"))
    pegar(hoja, 17, 14, 6, caja_producto([((92, 170, 72), (150, 214, 110)), ((70, 150, 60), (130, 200, 100))]))
    pegar(hoja, 17, 14, 7, caja_producto([((246, 206, 60), (255, 240, 150)), ((236, 190, 40), (255, 236, 130))]))
    pegar(hoja, 17, 16, 6, caja_producto([((214, 58, 44), (250, 130, 110)), ((92, 170, 72), (150, 214, 110)), ((214, 58, 44), (250, 130, 110))], True))
    pegar(hoja, 17, 54, 12, botella((52, 150, 140), (110, 200, 190), CREMA))
    pegar(hoja, 17, 55, 12, botella((196, 128, 40), (236, 180, 90), (250, 240, 220)))
    pegar(hoja, 17, 54, 14, botella((72, 140, 60), (120, 190, 100), (240, 200, 80)))
    pegar(hoja, 17, 54, 13, bolillos())
    pegar(hoja, 17, 54, 15, pollo_asado())
    pegar(hoja, 17, 55, 13, corte_carne())
    pegar(hoja, 17, 55, 18, plato_tacos())
    pegar(hoja, 17, 56, 14, cazuela())
    pegar(hoja, 17, 36, 6, barril_cerveza_tirada())
    pegar(hoja, 17, 37, 3, enfriador())
    pegar(hoja, 17, 32, 2, hielera(False))
    pegar(hoja, 17, 33, 2, hielera(True))
    pegar(hoja, 17, 43, 13, estante(False))
    pegar(hoja, 17, 44, 13, estante(True))


def dibujar_muebles(hoja):
    pegar(hoja, 17, 0, 2, silla_frente())
    pegar(hoja, 17, 1, 2, silla_espalda())
    pegar(hoja, 17, 3, 0, mesa(32))
    pegar(hoja, 17, 7, 0, mesa(16))
    pegar(hoja, 17, 16, 0, planta(True))
    pegar(hoja, 17, 17, 0, planta(False))
    pegar(hoja, 17, 0, 12, mostrador("izq"))
    pegar(hoja, 17, 1, 12, mostrador("centro"))
    pegar(hoja, 17, 2, 12, mostrador("der"))
    pegar(hoja, 17, 4, 12, mostrador("solo", tarja))
    pegar(hoja, 17, 5, 12, mostrador("solo", ingredientes))
    pegar(hoja, 17, 6, 12, mostrador("solo", salsas))
    pegar(hoja, 17, 7, 12, mostrador("solo", platos))
    pegar(hoja, 17, 0, 15, caja_cobro("izq"))
    pegar(hoja, 17, 1, 15, caja_cobro("centro"))
    pegar(hoja, 17, 2, 15, caja_cobro("der"))
    pegar(hoja, 17, 3, 15, caja_cobro("solo"))
    pegar(hoja, 17, 10, 13, barra_vertical("pase"))
    pegar(hoja, 17, 10, 14, barra_vertical("pase_fin"))
    pegar(hoja, 17, 12, 14, barra_vertical("barra"))
    pegar(hoja, 17, 12, 15, barra_vertical("barra_fin"))
    pegar(hoja, 17, 12, 16, barra_esquina())
    pegar(hoja, 17, 14, 14, estufa(False))
    pegar(hoja, 17, 15, 14, estufa(True))


if __name__ == "__main__":
    for ruta, tamano, dibujar in ((INTERIORES, (968, 526), dibujar_interiores), (MUEBLES, (458, 305), dibujar_muebles)):
        hoja = Image.new("RGBA", tamano, (0, 0, 0, 0))
        dibujar(hoja)
        hoja.save(ruta)
        print("listo", os.path.relpath(ruta, RAIZ))
