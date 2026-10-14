import os
from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(RAIZ, "Assets", "sprites")
PUEBLO = os.path.join(SPRITES, "pueblo", "pueblo.png")
INTERIORES = os.path.join(SPRITES, "interiores", "interiores.png")
MUEBLES = os.path.join(SPRITES, "interiores", "muebles.png")

VERDE = {"osc": (28, 128, 104), "med": (44, 168, 132), "cla": (108, 214, 160), "borde": (18, 74, 66)}
OTONO = {"osc": (196, 72, 34), "med": (234, 106, 46), "cla": (255, 168, 92), "borde": (112, 38, 24)}
TRONCO = {"med": (138, 86, 52), "osc": (102, 60, 36), "borde": (60, 36, 24)}
TRONCO_CLARO = {"med": (236, 226, 214), "osc": (196, 182, 170), "borde": (92, 76, 70)}

MADERA = (185, 139, 94)
MADERA_CLARA = (200, 164, 128)
MADERA_OSCURA = (143, 103, 63)
MADERA_BORDE = (96, 64, 36)


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


def tronco(t, arriba, abajo):
    img, d = lienzo(16, 32)
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
        d.rectangle([3, 25, 12, 30], fill=(214, 196, 158))
        d.line([(3, 25), (12, 25)], fill=(110, 76, 52))
        d.rectangle([3, 29, 12, 30], fill=(176, 156, 120))
        d.line([(4, 26), (4, 28)], fill=(236, 222, 190))
        img = contorno(img, (84, 62, 48))
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


def pasto():
    img, d = lienzo()
    d.rectangle([0, 0, 15, 15], fill=(56, 203, 171))
    for x, y in ((2, 3), (9, 1), (12, 7), (5, 9), (10, 12), (1, 13), (6, 14)):
        d.point((x, y), fill=(88, 226, 182))
        d.point((x + 2, y), fill=(88, 226, 182))
        d.point((x + 1, y + 1), fill=(44, 176, 160))
    for x, y in ((14, 2), (7, 5), (3, 11), (13, 14)):
        d.point((x, y), fill=(48, 188, 166))
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
    poste, poste_claro = (36, 112, 92), (70, 160, 128)
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
    return contorno(img, (18, 52, 44))


def poste():
    img, d = lienzo(16, 32)
    gris, gris_claro, gris_oscuro = (128, 132, 160), (176, 180, 206), (92, 96, 122)
    d.rectangle([11, 3, 12, 29], fill=gris)
    d.line([(11, 3), (11, 29)], fill=gris_claro)
    d.rectangle([4, 2, 12, 3], fill=gris)
    d.line([(4, 2), (11, 2)], fill=gris_claro)
    d.rectangle([2, 3, 6, 4], fill=gris_oscuro)
    d.line([(3, 5), (5, 5)], fill=(255, 236, 160))
    d.rectangle([10, 27, 13, 29], fill=gris_oscuro)
    return contorno(img, (44, 46, 64))


def buzon(cuerpo, claro, oscuro, borde):
    img, d = lienzo()
    d.rectangle([6, 13, 9, 14], fill=(70, 72, 84))
    d.rounded_rectangle([4, 3, 11, 12], radius=3, fill=cuerpo)
    d.line([(5, 5), (5, 10)], fill=claro)
    d.line([(10, 5), (10, 11)], fill=oscuro)
    d.line([(6, 6), (9, 6)], fill=(40, 30, 30))
    d.rectangle([6, 9, 9, 10], fill=(240, 240, 232))
    return contorno(img, borde)


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


def dibujar_pueblo(hoja):
    pegar(hoja, 16, 16, 8, conifera(VERDE, TRONCO))
    pegar(hoja, 16, 17, 8, redondo(VERDE, TRONCO))
    pegar(hoja, 16, 17, 10, redondo(VERDE, TRONCO, maceta=True).crop((0, 16, 16, 32)))
    pegar(hoja, 16, 16, 11, conifera(OTONO, TRONCO_CLARO))
    pegar(hoja, 16, 17, 11, pequeno(OTONO, TRONCO_CLARO))
    pegar(hoja, 16, 1, 1, pasto())
    pegar(hoja, 16, 0, 10, banca())
    pegar(hoja, 16, 7, 6, farol())
    pegar(hoja, 16, 2, 6, poste())
    pegar(hoja, 16, 8, 9, buzon((214, 58, 52), (244, 104, 92), (160, 36, 40), (90, 24, 24)))
    pegar(hoja, 16, 8, 11, buzon((70, 110, 210), (118, 154, 236), (48, 78, 160), (24, 40, 90)))


def dibujar_interiores(hoja):
    pegar(hoja, 17, 5, 2, piso_madera())
    pegar(hoja, 17, 6, 2, piso_baldosa((194, 194, 194), (188, 188, 190), (168, 168, 172), (208, 208, 210)))
    pegar(hoja, 17, 7, 2, piso_baldosa((230, 218, 191), (224, 210, 180), (204, 188, 154), (240, 232, 210)))
    pegar(hoja, 17, 23, 0, barril((176, 112, 62), (212, 152, 94), (138, 84, 46), (96, 98, 112), (70, 42, 26)))
    pegar(hoja, 17, 24, 0, barril((122, 78, 46), (156, 104, 64), (92, 58, 34), (184, 190, 204), (48, 30, 20)))
    pegar(hoja, 17, 48, 17, caja())
    pegar(hoja, 17, 36, 3, refri())


def dibujar_muebles(hoja):
    pegar(hoja, 17, 0, 2, silla_frente())
    pegar(hoja, 17, 1, 2, silla_espalda())
    pegar(hoja, 17, 3, 0, mesa(32))
    pegar(hoja, 17, 7, 0, mesa(16))
    pegar(hoja, 17, 16, 0, planta(True))
    pegar(hoja, 17, 17, 0, planta(False))


if __name__ == "__main__":
    for ruta, dibujar in ((PUEBLO, dibujar_pueblo), (INTERIORES, dibujar_interiores), (MUEBLES, dibujar_muebles)):
        hoja = Image.open(ruta).convert("RGBA")
        dibujar(hoja)
        hoja.save(ruta)
        print("listo", os.path.relpath(ruta, RAIZ))
