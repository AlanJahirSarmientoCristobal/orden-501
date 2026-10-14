import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_art import RAIZ, SPRITES, contorno, lienzo, pegar

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
    for ruta, dibujar in ((INTERIORES, dibujar_interiores), (MUEBLES, dibujar_muebles)):
        hoja = Image.open(ruta).convert("RGBA")
        dibujar(hoja)
        hoja.save(ruta)
        print("listo", os.path.relpath(ruta, RAIZ))
