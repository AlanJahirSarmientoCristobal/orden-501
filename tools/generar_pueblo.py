import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_art import RAIZ, SPRITES, contorno, franja, lienzo, nueve, oscurecer, pegar, ruido, sombrear_filas, textura

PUEBLO = os.path.join(SPRITES, "pueblo", "pueblo.png")
COLUMNAS, FILAS = 27, 18

VERDE = {"osc": (40, 120, 70), "med": (62, 156, 86), "cla": (128, 200, 110), "borde": (24, 68, 44)}
OTONO = {"osc": (196, 72, 34), "med": (234, 106, 46), "cla": (255, 168, 92), "borde": (112, 38, 24)}
TRONCO = {"med": (138, 86, 52), "osc": (102, 60, 36), "borde": (60, 36, 24)}
TRONCO_CLARO = {"med": (236, 226, 214), "osc": (196, 182, 170), "borde": (92, 76, 70)}

VIDRIO = (150, 200, 220)
VIDRIO_BRILLO = (210, 236, 246)
HERRERIA = (40, 40, 46)
ROBLE = (176, 128, 80)
ROBLE_CLARO = (206, 160, 106)
NOGAL = (132, 84, 48)
NOGAL_OSCURO = (98, 62, 36)
TERRACOTA = (196, 92, 58)
CREMA = (240, 226, 200)


def adoquin(x, y):
    hilada = y // 4
    desfase = 4 if hilada % 2 else 0
    if y % 4 == 3 or (x + desfase) % 8 == 7:
        return (150, 142, 130)
    tonos = ((186, 176, 160), (176, 166, 150), (196, 186, 170))
    color = tonos[(((x + desfase) % 16) // 8 + hilada) % 3]
    return oscurecer(color, 0.93) if ruido(x, y, 11) < 6 else color


def borde_banqueta(img, lados):
    franja(img, lados, [(112, 106, 98), (214, 208, 196), (200, 194, 182)])


def pasto(x, y):
    r = ruido(x, y, 1)
    if ruido(x, y, 2) == 0:
        return (250, 228, 120)
    if r < 9:
        return (126, 190, 92)
    if r < 16:
        return (76, 138, 62)
    return (98, 166, 76)


def borde_pasto(img, lados):
    franja(img, lados, [(128, 120, 108), (204, 196, 180), (76, 132, 60)])


def agua(x, y):
    if y % 8 == 3 and (x + (y // 8) * 7) % 16 in (2, 3, 4, 5):
        return (140, 204, 236)
    if ruido(x, y, 3) < 10:
        return (58, 132, 186)
    return (70, 148, 200)


def borde_agua(img, lados):
    franja(img, lados, [(92, 86, 80), (190, 182, 166), (168, 160, 144), (42, 100, 146)])


def teja(x, y):
    tonos = ((228, 132, 88), (204, 98, 62), (188, 86, 54), (146, 60, 40))
    color = tonos[x % 4]
    if (y + ((x // 4) % 2) * 2) % 4 == 3:
        color = oscurecer(color, 0.78)
    return color


def lamina(x, y):
    color = ((116, 122, 134), (60, 64, 74), (80, 84, 96), (86, 90, 102))[x % 4]
    return oscurecer(color, 0.94) if y % 8 == 7 else color


def borde_techo(contorno_color, orilla, fascia):
    def borde(img, lados):
        franja(img, lados - {"abajo"}, [contorno_color, orilla])
        franja(img, lados & {"abajo"}, fascia)
    return borde


def ladrillo(x, y):
    hilada = y // 4
    desfase = 4 if hilada % 2 else 0
    if y % 4 == 3 or (x + desfase) % 8 == 7:
        return (222, 206, 186)
    tonos = ((176, 74, 52), (160, 64, 44), (190, 88, 60))
    return tonos[(((x + desfase) % 16) // 8 + hilada) % 3]


def estuco(x, y):
    r = ruido(x, y, 5)
    if r < 7:
        return (226, 214, 192)
    if r < 12:
        return (244, 236, 220)
    return (236, 226, 206)


def cantera(base, junta):
    def piedra(x, y):
        bloque = y // 8
        corte = 10 if bloque == 0 else 5
        if y % 8 == 7 or x == corte:
            return junta
        if x in (0, 15):
            return oscurecer(base, 0.82)
        return oscurecer(base, 0.94) if ruido(x, y, 7) < 12 else base
    return piedra


def muro(relleno, fila, lado, estilo):
    img = textura(relleno)
    d = ImageDraw.Draw(img)
    if fila == "arriba":
        d.line([(0, 0), (15, 0)], fill=(60, 34, 26))
        sombrear_filas(img, (1, 2), 0.74)
    elif fila == "franja":
        if estilo == "ladrillo":
            d.line([(0, 6), (15, 6)], fill=(156, 108, 68))
            d.rectangle([0, 7, 15, 8], fill=(118, 78, 46))
            d.line([(0, 9), (15, 9)], fill=(78, 50, 30))
            for x in (3, 11):
                d.point((x, 7), fill=(64, 64, 70))
        else:
            for y in range(3, 13):
                if (y - 3) % 3 == 2:
                    d.line([(0, y), (15, y)], fill=(110, 76, 46))
                else:
                    d.line([(0, y), (15, y)], fill=(190, 140, 90) if ((y - 3) // 3) % 2 == 0 else (176, 128, 80))
    elif fila == "baja":
        if estilo == "ladrillo":
            d.line([(0, 11), (15, 11)], fill=(196, 190, 180))
            d.rectangle([0, 12, 15, 15], fill=(150, 146, 140))
            d.line([(5, 12), (5, 15)], fill=(112, 108, 104))
            d.line([(13, 12), (13, 15)], fill=(112, 108, 104))
            d.line([(0, 15), (15, 15)], fill=(112, 108, 104))
        else:
            d.line([(0, 10), (15, 10)], fill=(104, 106, 116))
            d.rectangle([0, 11, 15, 15], fill=(70, 72, 80))
            d.line([(0, 15), (15, 15)], fill=(52, 54, 60))
    if lado == "izq":
        sombrear_filas_columna(img, 0, 0.72)
    elif lado == "der":
        sombrear_filas_columna(img, 15, 0.72)
    return img


def sombrear_filas_columna(img, x, factor):
    px = img.load()
    for y in range(16):
        r, g, b, a = px[x, y]
        px[x, y] = oscurecer((r, g, b), factor) + (a,)


def pilar(base, junta, fila):
    img = textura(cantera(base, junta))
    if fila == "arriba":
        d = ImageDraw.Draw(img)
        d.line([(0, 0), (15, 0)], fill=(60, 34, 26))
        sombrear_filas(img, (1, 2), 0.74)
    return img


def fachada(hoja, pilares, filas, relleno, estilo, piedra):
    for i, fila in enumerate(("arriba", "franja", "baja")):
        pegar(hoja, 16, pilares[i][0], pilares[i][1], pilar(piedra[0], piedra[1], fila))
        for j, lado in enumerate(("izq", "centro", "der")):
            columna, fila_hoja = filas[i][j]
            pegar(hoja, 16, columna, fila_hoja, muro(relleno, fila, lado, estilo))


def ventana():
    img, d = lienzo()
    d.rectangle([3, 2, 12, 12], fill=HERRERIA)
    d.rectangle([4, 3, 11, 11], fill=VIDRIO)
    d.line([(7, 3), (7, 11)], fill=HERRERIA)
    d.line([(4, 7), (11, 7)], fill=HERRERIA)
    d.line([(4, 6), (6, 4)], fill=VIDRIO_BRILLO)
    d.line([(8, 10), (10, 8)], fill=VIDRIO_BRILLO)
    d.rectangle([2, 13, 13, 13], fill=ROBLE)
    d.line([(2, 14), (13, 14)], fill=NOGAL_OSCURO)
    return img


def ventana_jardinera():
    img, d = lienzo()
    d.rectangle([4, 1, 11, 8], fill=HERRERIA)
    d.rectangle([5, 2, 10, 7], fill=VIDRIO)
    d.line([(5, 5), (7, 3)], fill=VIDRIO_BRILLO)
    d.rectangle([3, 11, 12, 14], fill=ROBLE)
    d.line([(3, 11), (12, 11)], fill=ROBLE_CLARO)
    d.line([(3, 14), (12, 14)], fill=NOGAL_OSCURO)
    for x, color in ((4, (226, 70, 80)), (6, (250, 200, 80)), (8, (226, 70, 80)), (10, (240, 120, 160))):
        d.point((x, 9), fill=color)
        d.point((x + 1, 10), fill=(70, 140, 60))
        d.point((x, 10), fill=(90, 160, 70))
    return contorno(img, (40, 30, 26))


def jamba():
    return textura(lambda x, y: (196, 186, 170) if ruido(x, y, 8) > 8 else (180, 170, 154))


def puerta_sencilla():
    img = jamba()
    d = ImageDraw.Draw(img)
    d.rectangle([2, 0, 13, 15], fill=(120, 112, 100))
    d.rectangle([4, 2, 11, 15], fill=NOGAL)
    for x in (6, 9):
        d.line([(x, 3), (x, 15)], fill=NOGAL_OSCURO)
    d.line([(4, 2), (11, 2)], fill=(160, 108, 64))
    d.rectangle([6, 4, 9, 6], fill=VIDRIO)
    d.point((10, 10), fill=(230, 200, 90))
    return img


def puerta_tienda():
    img = textura(lambda x, y: NOGAL)
    d = ImageDraw.Draw(img)
    d.line([(0, 0), (15, 0)], fill=NOGAL_OSCURO)
    d.rectangle([3, 2, 12, 15], fill=VIDRIO)
    d.line([(4, 5), (7, 2)], fill=VIDRIO_BRILLO)
    d.rectangle([4, 7, 11, 9], fill=(186, 50, 44))
    d.line([(5, 8), (10, 8)], fill=(250, 240, 220))
    d.line([(11, 10), (11, 12)], fill=(230, 200, 90))
    return img


def puertas_vidrio():
    img = textura(lambda x, y: HERRERIA, 32, 16)
    d = ImageDraw.Draw(img)
    d.rectangle([2, 4, 14, 15], fill=VIDRIO)
    d.rectangle([17, 4, 29, 15], fill=VIDRIO)
    d.rectangle([3, 1, 28, 2], fill=(110, 150, 170))
    for x in (3, 18):
        d.line([(x, 8), (x + 4, 4)], fill=VIDRIO_BRILLO)
    d.line([(12, 7), (12, 11)], fill=ROBLE_CLARO)
    d.line([(19, 7), (19, 11)], fill=ROBLE_CLARO)
    return img


def vitrina(pieza):
    img = textura(lambda x, y: HERRERIA)
    d = ImageDraw.Draw(img)
    fin = 13 if pieza == 2 else 15
    d.rectangle([2, 2, fin, 9], fill=VIDRIO)
    d.line([(2, 7), (fin, 7)], fill=ROBLE)
    for x, color in ((3, (226, 70, 60)), (6, (250, 200, 70)), (9, (100, 176, 80)), (12, (240, 140, 50))):
        if x + 1 <= fin:
            d.rectangle([x, 5, x + 1, 6], fill=color)
    d.line([(3, 4), (5, 2)], fill=VIDRIO_BRILLO)
    d.rectangle([0, 11, 15, 15], fill=(146, 100, 62))
    d.line([(0, 11), (15, 11)], fill=ROBLE)
    d.rectangle([3, 12, 12, 14], fill=(128, 86, 52))
    if pieza == 0:
        d.rectangle([0, 0, 1, 15], fill=HERRERIA)
    return img


def toldo(con_farol=False):
    img, d = lienzo()
    for x in range(16):
        color = TERRACOTA if (x // 4) % 2 == 0 else CREMA
        d.line([(x, 1), (x, 6)], fill=color)
        if x % 4 in (1, 2):
            d.point((x, 7), fill=color)
    sombrear_filas(img, (5, 6, 7), 0.88)
    d.line([(0, 0), (15, 0)], fill=(70, 44, 28))
    if con_farol:
        d.line([(7, 8), (7, 9)], fill=(50, 50, 56))
        d.rectangle([6, 10, 8, 13], fill=(255, 214, 110))
        d.line([(6, 10), (8, 10)], fill=(50, 50, 56))
    return contorno(img, (70, 44, 28))


def chimenea():
    img, d = lienzo()
    d.rectangle([4, 4, 11, 14], fill=(176, 74, 52))
    for y in (6, 9, 12):
        d.line([(4, y), (11, y)], fill=(222, 206, 186))
    for x, y in ((7, 4), (5, 7), (9, 7), (7, 10), (5, 13), (9, 13)):
        d.line([(x, y), (x, y + 1)], fill=(222, 206, 186))
    d.rectangle([3, 2, 12, 3], fill=(120, 112, 104))
    d.line([(5, 2), (10, 2)], fill=(40, 32, 30))
    return contorno(img, (70, 34, 26))


def panel_solar():
    img, d = lienzo()
    d.rectangle([1, 3, 14, 12], fill=(190, 196, 206))
    d.rectangle([2, 4, 13, 11], fill=(42, 64, 120))
    for x in (5, 9):
        d.line([(x, 4), (x, 11)], fill=(88, 118, 180))
    d.line([(2, 7), (13, 7)], fill=(88, 118, 180))
    d.line([(3, 5), (4, 4)], fill=(140, 170, 220))
    return contorno(img, (30, 34, 48))


def cerca():
    img, d = lienzo()
    for x in (2, 10):
        d.rectangle([x, 3, x + 1, 14], fill=(150, 102, 60))
        d.point((x, 3), fill=(186, 136, 86))
    for y in (5, 10):
        d.rectangle([0, y, 15, y + 1], fill=(160, 110, 66))
        d.line([(0, y), (15, y)], fill=(192, 142, 92))
    return contorno(img, (84, 54, 32))


def asfalto(x, y):
    r = ruido(x, y, 9)
    if r < 6:
        return (86, 84, 90)
    if r < 11:
        return (62, 60, 66)
    return (74, 72, 78)


CUNETA = (50, 48, 54)
CUNETA_CLARA = (64, 62, 68)
AMARILLO = (232, 190, 72)
BLANCO = (236, 236, 228)


def calle(lados, extra=None):
    img = textura(asfalto)
    franja(img, lados, [CUNETA, CUNETA_CLARA])
    if extra:
        extra(ImageDraw.Draw(img))
    return img


def dibujar_calles(hoja):
    pegar(hoja, 16, 1, 15, calle({"arriba"}))
    pegar(hoja, 16, 1, 16, calle(set(), lambda d: d.rectangle([2, 7, 9, 8], fill=AMARILLO)))
    pegar(hoja, 16, 1, 17, calle({"abajo"}))
    pegar(hoja, 16, 2, 17, calle({"izq"}))
    pegar(hoja, 16, 3, 17, calle(set(), lambda d: d.rectangle([7, 2, 8, 9], fill=AMARILLO)))
    pegar(hoja, 16, 4, 17, calle({"der"}))

    def cebra_h(d):
        for y in (2, 10):
            d.rectangle([2, y, 13, y + 2], fill=BLANCO)

    def cebra_v(d):
        for x in (2, 10):
            d.rectangle([x, 2, x + 2, 13], fill=BLANCO)

    for i, lados in enumerate(({"arriba"}, set(), {"abajo"})):
        pegar(hoja, 16, 0, 15 + i, calle(lados, cebra_h))
    for i, lados in enumerate(({"izq"}, set(), {"der"})):
        pegar(hoja, 16, 2 + i, 16, calle(lados, cebra_v))
    pegar(hoja, 16, 9, 16, calle(set()))

    def letra_p(d):
        d.rounded_rectangle([3, 3, 12, 12], radius=2, outline=BLANCO)
        d.line([(6, 5), (6, 10)], fill=BLANCO)
        d.line([(6, 5), (8, 5)], fill=BLANCO)
        d.line([(9, 6), (9, 6)], fill=BLANCO)
        d.line([(6, 7), (8, 7)], fill=BLANCO)
    pegar(hoja, 16, 10, 16, calle(set(), letra_p))


def auto_frente(color, claro, oscuro, pickup=False):
    img, d = lienzo(32, 32)
    d.point((5, 19), fill=oscuro)
    d.point((26, 19), fill=oscuro)
    d.rounded_rectangle([6, 2, 25, 29], radius=5, fill=color)
    d.line([(7, 5), (7, 26)], fill=claro)
    d.line([(24, 5), (24, 26)], fill=oscuro)
    if pickup:
        d.rectangle([8, 4, 23, 14], fill=(150, 102, 60))
        for y in (6, 9, 12):
            d.line([(8, y), (23, y)], fill=(118, 78, 46))
        d.rectangle([9, 16, 22, 20], fill=claro)
        d.rectangle([8, 21, 23, 23], fill=(60, 76, 92))
    else:
        d.rectangle([9, 5, 22, 7], fill=(60, 76, 92))
        d.rectangle([9, 9, 22, 17], fill=claro)
        d.rectangle([8, 19, 23, 22], fill=(60, 76, 92))
    d.line([(10, 20), (13, 20)], fill=(120, 150, 170))
    d.rectangle([8, 27, 10, 28], fill=(255, 240, 180))
    d.rectangle([21, 27, 23, 28], fill=(255, 240, 180))
    d.line([(13, 28), (18, 28)], fill=(50, 50, 56))
    return contorno(img, (30, 30, 36))


def auto_lado(color, claro, oscuro, pickup=False):
    img, d = lienzo(32, 16)
    d.point((21, 2), fill=oscuro)
    d.point((21, 13), fill=oscuro)
    d.rounded_rectangle([2, 3, 29, 12], radius=3, fill=color)
    d.line([(4, 4), (27, 4)], fill=claro)
    d.line([(4, 11), (27, 11)], fill=oscuro)
    if pickup:
        d.rectangle([3, 5, 15, 10], fill=(150, 102, 60))
        for x in (7, 11):
            d.line([(x, 5), (x, 10)], fill=(118, 78, 46))
        d.rectangle([17, 5, 21, 10], fill=claro)
        d.rectangle([22, 5, 24, 10], fill=(60, 76, 92))
    else:
        d.rectangle([6, 5, 8, 10], fill=(60, 76, 92))
        d.rectangle([9, 5, 19, 10], fill=claro)
        d.rectangle([20, 5, 23, 10], fill=(60, 76, 92))
    d.line([(21, 6), (21, 8)], fill=(120, 150, 170))
    d.point((29, 4), fill=(255, 240, 180))
    d.point((29, 11), fill=(255, 240, 180))
    d.point((2, 4), fill=(220, 50, 40))
    d.point((2, 11), fill=(220, 50, 40))
    return contorno(img, (30, 30, 36))


def tronco(t, arriba, abajo, alto=32):
    img, d = lienzo(16, alto)
    d.rectangle([7, arriba, 8, abajo], fill=t["med"])
    d.line([(8, arriba), (8, abajo)], fill=t["osc"])
    return contorno(img, t["borde"])


def conifera(c, t):
    copa, d = lienzo(16, 32)
    for arriba, abajo, mitad in ((10, 25, 6), (5, 18, 5), (1, 10, 3)):
        d.polygon([(7, arriba), (8, arriba), (8 + mitad, abajo), (7 - mitad, abajo)], fill=c["med"])
        d.polygon([(8, arriba + 1), (8 + mitad, abajo), (8, abajo)], fill=c["osc"])
        d.line([(7, arriba + 2), (7 - mitad + 2, abajo - 1)], fill=c["cla"])
        if abajo < 25:
            d.line([(7 - mitad + 2, abajo + 1), (8 + mitad - 2, abajo + 1)], fill=c["osc"])
    img = tronco(t, 24, 29)
    img.alpha_composite(contorno(copa, c["borde"]))
    return img


def redondo(c, t, maceta=False):
    copa, d = lienzo(16, 32)
    d.ellipse([2, 3, 13, 22], fill=c["med"])
    d.ellipse([5, 10, 13, 22], fill=c["osc"])
    d.ellipse([4, 5, 11, 17], fill=c["med"])
    d.ellipse([4, 6, 7, 9], fill=c["cla"])
    img, d = lienzo(16, 32)
    d.rectangle([7, 20, 8, 29], fill=t["med"])
    d.line([(8, 20), (8, 29)], fill=t["osc"])
    if maceta:
        d.rectangle([3, 25, 12, 30], fill=(196, 92, 58))
        d.line([(3, 25), (12, 25)], fill=(96, 62, 40))
        d.rectangle([3, 29, 12, 30], fill=(160, 70, 44))
        d.line([(4, 26), (4, 28)], fill=(226, 130, 90))
        img = contorno(img, (84, 44, 30))
    else:
        img = contorno(img, t["borde"])
    img.alpha_composite(contorno(copa, c["borde"]))
    return img


def pequeno(c, t):
    copa, d = lienzo(16, 32)
    d.polygon([(7, 7), (8, 7), (12, 16), (3, 16)], fill=c["med"])
    d.ellipse([2, 11, 13, 25], fill=c["med"])
    d.ellipse([7, 14, 13, 25], fill=c["osc"])
    d.ellipse([4, 12, 10, 22], fill=c["med"])
    d.ellipse([4, 13, 6, 16], fill=c["cla"])
    d.line([(6, 10), (5, 12)], fill=c["cla"])
    img = tronco(t, 24, 29)
    img.alpha_composite(contorno(copa, c["borde"]))
    return img


def arbusto(c):
    img, d = lienzo()
    d.ellipse([2, 4, 13, 14], fill=c["med"])
    d.ellipse([6, 8, 13, 14], fill=c["osc"])
    d.ellipse([3, 5, 10, 11], fill=c["med"])
    d.ellipse([4, 6, 6, 8], fill=c["cla"])
    return contorno(img, c["borde"])


def pino_pequeno(c, t):
    copa, d = lienzo()
    for arriba, abajo, mitad in ((5, 12, 5), (1, 8, 3)):
        d.polygon([(7, arriba), (8, arriba), (8 + mitad, abajo), (7 - mitad, abajo)], fill=c["med"])
        d.polygon([(8, arriba + 1), (8 + mitad, abajo), (8, abajo)], fill=c["osc"])
        d.line([(7, arriba + 2), (7 - mitad + 2, abajo - 1)], fill=c["cla"])
    img = tronco(t, 12, 14, 16)
    img.alpha_composite(contorno(copa, c["borde"]))
    return img


def arbolito(c, t):
    copa, d = lienzo()
    d.ellipse([3, 1, 12, 11], fill=c["med"])
    d.ellipse([6, 5, 12, 11], fill=c["osc"])
    d.ellipse([4, 2, 9, 8], fill=c["med"])
    d.ellipse([4, 3, 6, 5], fill=c["cla"])
    img = tronco(t, 10, 14, 16)
    img.alpha_composite(contorno(copa, c["borde"]))
    return img


def banca():
    img, d = lienzo()
    fierro = (64, 66, 80)
    d.line([(3, 4), (3, 14)], fill=fierro)
    d.line([(12, 4), (12, 14)], fill=fierro)
    for y in (4, 7):
        d.rectangle([1, y, 14, y + 1], fill=(184, 116, 64))
        d.line([(1, y), (14, y)], fill=(220, 156, 96))
    d.rectangle([1, 10, 14, 12], fill=(184, 116, 64))
    d.line([(1, 10), (14, 10)], fill=(220, 156, 96))
    d.line([(1, 12), (14, 12)], fill=(140, 84, 46))
    return contorno(img, (58, 36, 24))


def farol():
    img, d = lienzo(16, 32)
    poste, poste_claro = (52, 56, 64), (96, 102, 114)
    d.rectangle([7, 10, 8, 28], fill=poste)
    d.line([(7, 10), (7, 28)], fill=poste_claro)
    d.rectangle([6, 25, 9, 26], fill=poste)
    d.rectangle([5, 27, 10, 29], fill=poste)
    d.point((7, 0), fill=poste)
    d.line([(6, 1), (9, 1)], fill=poste)
    d.line([(5, 2), (10, 2)], fill=poste)
    d.rectangle([5, 3, 10, 8], fill=poste)
    d.rectangle([6, 3, 9, 8], fill=(255, 222, 120))
    d.line([(7, 4), (7, 6)], fill=(255, 246, 200))
    d.line([(5, 9), (10, 9)], fill=poste)
    return contorno(img, (26, 28, 34))


def poste():
    img, d = lienzo(16, 32)
    gris, gris_claro, gris_oscuro = (128, 132, 150), (176, 180, 196), (92, 96, 112)
    d.rectangle([11, 3, 12, 29], fill=gris)
    d.line([(11, 3), (11, 29)], fill=gris_claro)
    d.rectangle([4, 2, 12, 3], fill=gris)
    d.line([(4, 2), (11, 2)], fill=gris_claro)
    d.rectangle([2, 3, 6, 4], fill=gris_oscuro)
    d.line([(3, 5), (5, 5)], fill=(255, 236, 160))
    d.rectangle([10, 27, 13, 29], fill=gris_oscuro)
    return contorno(img, (44, 46, 60))


def buzon():
    img, d = lienzo()
    d.rectangle([6, 13, 9, 14], fill=(70, 72, 84))
    d.rounded_rectangle([4, 3, 11, 12], radius=3, fill=(70, 110, 210))
    d.line([(5, 5), (5, 10)], fill=(118, 154, 236))
    d.line([(10, 5), (10, 11)], fill=(48, 78, 160))
    d.line([(6, 6), (9, 6)], fill=(40, 30, 30))
    d.rectangle([6, 9, 9, 10], fill=(240, 240, 232))
    return contorno(img, (24, 40, 90))


def hidrante():
    img, d = lienzo()
    rojo, claro, oscuro = (204, 52, 44), (236, 96, 80), (150, 32, 32)
    d.rectangle([5, 13, 10, 14], fill=(90, 90, 100))
    d.rectangle([3, 7, 12, 8], fill=rojo)
    d.rounded_rectangle([5, 5, 10, 13], radius=1, fill=rojo)
    d.rectangle([6, 3, 9, 5], fill=rojo)
    d.line([(7, 2), (8, 2)], fill=rojo)
    d.line([(6, 6), (6, 12)], fill=claro)
    d.line([(9, 6), (9, 12)], fill=oscuro)
    return contorno(img, (80, 20, 20))


def bote():
    img, d = lienzo()
    d.rectangle([4, 5, 11, 14], fill=(160, 110, 66))
    for x in (6, 9):
        d.line([(x, 6), (x, 14)], fill=(118, 78, 46))
    d.line([(4, 11), (11, 11)], fill=(62, 66, 74))
    d.rectangle([3, 3, 12, 5], fill=(62, 66, 74))
    d.line([(4, 3), (11, 3)], fill=(96, 100, 110))
    d.point((7, 8), fill=(110, 180, 90))
    d.point((8, 8), fill=(110, 180, 90))
    return contorno(img, (40, 34, 30))


def dibujar_terreno(hoja):
    nueve(hoja, 16, 0, 0, pasto, borde_pasto)
    nueve(hoja, 16, 8, 0, adoquin, borde_banqueta)
    nueve(hoja, 16, 8, 6, agua, borde_agua)
    nueve(hoja, 16, 0, 3, teja, borde_techo((84, 36, 26), (170, 74, 48), [(64, 40, 26), (124, 82, 50), (156, 108, 68), (110, 48, 32)]))
    nueve(hoja, 16, 8, 3, lamina, borde_techo((38, 40, 48), (100, 104, 116), [(70, 48, 30), (178, 132, 82), (206, 160, 106), (52, 54, 62)]))


def dibujar_edificios(hoja):
    fachada(hoja, [(16, 0), (16, 2), (16, 3)], [[(20, 0), (21, 0), (22, 0)], [(20, 1), (21, 1), (22, 1)], [(20, 3), (21, 3), (22, 3)]],
            ladrillo, "ladrillo", ((214, 180, 150), (164, 132, 110)))
    fachada(hoja, [(16, 4), (16, 5), (16, 7)], [[(20, 4), (21, 4), (22, 4)], [(20, 5), (21, 5), (22, 5)], [(20, 7), (21, 7), (22, 7)]],
            estuco, "estuco", ((178, 174, 166), (128, 124, 118)))
    pegar(hoja, 16, 11, 13, ventana())
    pegar(hoja, 16, 11, 14, ventana_jardinera())
    pegar(hoja, 16, 13, 10, puerta_sencilla())
    pegar(hoja, 16, 15, 10, puerta_tienda())
    pegar(hoja, 16, 7, 15, puertas_vidrio())
    for i in range(3):
        pegar(hoja, 16, 8 + i, 14, vitrina(i))
        pegar(hoja, 16, 4 + i, 12, toldo())
        pegar(hoja, 16, 4 + i, 14, cerca())
    pegar(hoja, 16, 8, 12, toldo(con_farol=True))
    pegar(hoja, 16, 9, 12, chimenea())
    pegar(hoja, 16, 10, 12, panel_solar())


def dibujar_objetos(hoja):
    pegar(hoja, 16, 16, 8, conifera(VERDE, TRONCO))
    pegar(hoja, 16, 17, 8, redondo(VERDE, TRONCO))
    pegar(hoja, 16, 17, 10, redondo(VERDE, TRONCO, maceta=True).crop((0, 16, 16, 32)))
    pegar(hoja, 16, 16, 11, conifera(OTONO, TRONCO_CLARO))
    pegar(hoja, 16, 17, 11, pequeno(OTONO, TRONCO_CLARO))
    pegar(hoja, 16, 22, 8, arbusto(VERDE))
    pegar(hoja, 16, 22, 9, pino_pequeno(VERDE, TRONCO))
    pegar(hoja, 16, 22, 10, arbolito(VERDE, TRONCO))
    pegar(hoja, 16, 22, 11, arbolito(OTONO, TRONCO_CLARO))
    pegar(hoja, 16, 0, 10, banca())
    pegar(hoja, 16, 7, 6, farol())
    pegar(hoja, 16, 2, 6, poste())
    pegar(hoja, 16, 8, 9, hidrante())
    pegar(hoja, 16, 8, 11, buzon())
    pegar(hoja, 16, 10, 9, bote())
    pegar(hoja, 16, 15, 16, auto_frente((214, 164, 56), (238, 196, 96), (168, 124, 36)))
    pegar(hoja, 16, 15, 14, auto_frente((104, 124, 70), (134, 156, 92), (78, 94, 52), pickup=True))
    pegar(hoja, 16, 21, 16, auto_lado((44, 96, 124), (72, 132, 160), (30, 68, 90)))
    pegar(hoja, 16, 21, 17, auto_lado((184, 82, 56), (214, 118, 84), (140, 58, 40), pickup=True))


if __name__ == "__main__":
    hoja = Image.new("RGBA", (COLUMNAS * 16, FILAS * 16), (0, 0, 0, 0))
    dibujar_terreno(hoja)
    dibujar_calles(hoja)
    dibujar_edificios(hoja)
    dibujar_objetos(hoja)
    hoja.save(PUEBLO)
    print("listo", os.path.relpath(PUEBLO, RAIZ))
