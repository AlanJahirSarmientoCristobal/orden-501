import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generar_plantilla_comida import CUADRO, ICONOS, posicion, tamano_hoja
from cortar_iconos_comida import CARPETA, cortar

CONTORNO = (27, 27, 36, 255)

C = {
    "blanco": (250, 248, 240),
    "hueso": (232, 226, 210),
    "hueso_s": (196, 186, 166),
    "carne": (196, 58, 64),
    "carne_l": (232, 98, 96),
    "carne_s": (150, 38, 50),
    "grasa": (246, 222, 200),
    "pollo": (246, 186, 170),
    "pollo_l": (255, 216, 204),
    "pollo_s": (214, 142, 132),
    "costal": (196, 150, 98),
    "costal_l": (222, 182, 128),
    "costal_s": (156, 112, 70),
    "cuerda": (120, 82, 50),
    "papa": (214, 168, 96),
    "papa_s": (172, 126, 66),
    "verde": (92, 176, 72),
    "verde_l": (150, 216, 104),
    "verde_s": (56, 126, 56),
    "pan": (226, 156, 78),
    "pan_l": (248, 196, 120),
    "pan_s": (176, 106, 50),
    "miga": (252, 226, 168),
    "ajonjoli": (255, 246, 214),
    "metal": (206, 212, 222),
    "metal_s": (142, 150, 166),
    "dorado": (240, 178, 50),
    "dorado_l": (255, 216, 106),
    "dorado_s": (190, 122, 30),
    "rojo": (222, 52, 52),
    "rojo_l": (250, 104, 96),
    "rojo_s": (162, 30, 42),
    "hielo": (190, 232, 250),
    "hielo_l": (240, 252, 255),
    "hielo_s": (120, 186, 222),
    "vidrio": (214, 238, 248),
    "cola": (92, 46, 34),
    "cola_l": (140, 76, 54),
    "cerveza": (244, 168, 40),
    "cerveza_l": (255, 206, 92),
    "espuma": (255, 252, 238),
    "espuma_s": (226, 222, 206),
    "queso": (255, 200, 40),
    "carne_cocida": (112, 62, 44),
    "carne_cocida_l": (150, 90, 62),
    "tomate": (232, 70, 56),
    "alita": (206, 96, 40),
    "alita_l": (238, 140, 66),
    "alita_s": (156, 62, 30),
    "caja": (214, 44, 50),
    "caja_l": (240, 90, 84),
    "caja_s": (160, 28, 38),
    "papa_frita": (255, 210, 72),
    "papa_frita_s": (224, 160, 40),
    "plato": (238, 240, 246),
    "plato_s": (196, 200, 214),
    "mancha": (150, 96, 60),
    "estrella": (255, 214, 64),
    "estrella_s": (222, 160, 30),
}


def nuevo():
    img = Image.new("RGBA", (CUADRO, CUADRO), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def p(d, puntos, color):
    for x, y in puntos:
        d.point((x, y), fill=C[color])


def rect(d, x0, y0, x1, y1, color):
    d.rectangle([x0, y0, x1, y1], fill=C[color])


def elipse(d, x0, y0, x1, y1, color):
    d.ellipse([x0, y0, x1, y1], fill=C[color])


def contorno(img):
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
                    destino[x, y] = CONTORNO
                    break
    return copia


def carne():
    img, d = nuevo()
    elipse(d, 4, 10, 27, 26, "grasa")
    elipse(d, 6, 11, 26, 24, "carne")
    elipse(d, 7, 12, 22, 19, "carne_l")
    elipse(d, 9, 14, 24, 23, "carne")
    rect(d, 8, 23, 24, 24, "carne_s")
    elipse(d, 17, 14, 21, 18, "hueso")
    p(d, [(20, 17), (21, 16)], "hueso_s")
    p(d, [(10, 16), (11, 17), (12, 17), (14, 20), (15, 21), (13, 19)], "grasa")
    p(d, [(8, 14), (9, 13), (10, 13)], "blanco")
    return img


def pollo():
    img, d = nuevo()
    d.line([(16, 19), (25, 26)], fill=C["hueso"], width=3)
    elipse(d, 23, 23, 27, 27, "hueso")
    elipse(d, 25, 21, 29, 25, "hueso")
    p(d, [(26, 27), (27, 26), (28, 25)], "hueso_s")
    elipse(d, 3, 6, 21, 22, "pollo")
    elipse(d, 5, 7, 15, 15, "pollo_l")
    elipse(d, 8, 12, 21, 22, "pollo")
    p(d, [(14, 20), (15, 20), (16, 19), (17, 19), (18, 18), (19, 17), (13, 21), (12, 21)], "pollo_s")
    p(d, [(6, 9), (7, 8), (8, 8)], "blanco")
    return img


def papas_costal():
    img, d = nuevo()
    elipse(d, 8, 5, 13, 10, "papa")
    elipse(d, 13, 4, 19, 9, "papa")
    elipse(d, 18, 6, 23, 11, "papa")
    p(d, [(10, 7), (16, 6), (20, 8)], "papa_s")
    d.polygon([(7, 11), (24, 11), (27, 27), (4, 27)], fill=C["costal"])
    rect(d, 7, 11, 24, 13, "costal_s")
    rect(d, 6, 12, 25, 12, "cuerda")
    d.polygon([(7, 14), (10, 14), (8, 27), (5, 27)], fill=C["costal_l"])
    d.polygon([(22, 14), (24, 14), (27, 27), (24, 27)], fill=C["costal_s"])
    rect(d, 12, 18, 19, 23, "costal_l")
    p(d, [(13, 19), (14, 20), (15, 21), (16, 20), (17, 19), (18, 20), (14, 22), (17, 22)], "costal_s")
    return img


def verdura():
    img, d = nuevo()
    elipse(d, 4, 9, 27, 28, "verde_s")
    elipse(d, 5, 8, 25, 26, "verde")
    elipse(d, 9, 6, 22, 20, "verde_l")
    elipse(d, 11, 9, 20, 17, "verde")
    d.line([(15, 10), (15, 25)], fill=C["verde_l"])
    d.line([(9, 15), (14, 22)], fill=C["verde_l"])
    d.line([(22, 15), (17, 22)], fill=C["verde_l"])
    p(d, [(12, 8), (13, 7), (14, 7)], "blanco")
    return img


def pan():
    img, d = nuevo()
    elipse(d, 3, 11, 28, 27, "pan_s")
    elipse(d, 3, 10, 28, 25, "pan")
    elipse(d, 6, 11, 22, 19, "pan_l")
    d.line([(9, 18), (22, 15)], fill=C["miga"], width=2)
    d.line([(9, 19), (22, 16)], fill=C["pan_s"])
    p(d, [(7, 13), (8, 12), (9, 12)], "blanco")
    return img


def lata(cuerpo, claro, sombra, franja):
    img, d = nuevo()
    rect(d, 9, 7, 22, 27, cuerpo)
    rect(d, 10, 8, 11, 26, claro)
    rect(d, 20, 8, 22, 26, sombra)
    elipse(d, 9, 4, 22, 9, "metal")
    elipse(d, 11, 5, 20, 8, "metal_s")
    p(d, [(14, 6), (15, 6), (16, 6), (17, 7)], "metal")
    rect(d, 9, 26, 22, 28, "metal_s")
    rect(d, 10, 26, 21, 26, "metal")
    franja(d)
    return img


def cerveza_lata():
    def franja(d):
        rect(d, 9, 13, 22, 20, "blanco")
        rect(d, 9, 13, 22, 13, "dorado_s")
        rect(d, 9, 20, 22, 20, "dorado_s")
        elipse(d, 13, 14, 18, 19, "dorado")
        p(d, [(14, 15), (15, 15)], "dorado_l")
    return lata("dorado", "dorado_l", "dorado_s", franja)


def refresco_lata():
    def franja(d):
        for x in range(9, 23):
            y = 16 + (1 if (x // 3) % 2 else 0)
            rect(d, x, y, x, y + 2, "blanco")
    return lata("rojo", "rojo_l", "rojo_s", franja)


def cubo(d, x, y, t):
    rect(d, x, y, x + t, y + t, "hielo")
    rect(d, x, y, x + t, y + 1, "hielo_l")
    rect(d, x, y, x + 1, y + t, "hielo_l")
    rect(d, x + t - 1, y + 2, x + t, y + t, "hielo_s")
    rect(d, x + 2, y + t - 1, x + t, y + t, "hielo_s")
    p(d, [(x + 3, y + 3), (x + 4, y + 3), (x + 3, y + 4)], "blanco")


def hielo():
    img, d = nuevo()
    cubo(d, 4, 17, 10)
    cubo(d, 17, 17, 10)
    cubo(d, 10, 5, 10)
    return img


def vaso(d, liquido, liquido_l):
    d.polygon([(8, 9), (23, 9), (21, 28), (10, 28)], fill=C["vidrio"])
    d.polygon([(9, 13), (22, 13), (20, 27), (11, 27)], fill=C[liquido])
    d.polygon([(10, 13), (12, 13), (12, 27), (11, 27)], fill=C[liquido_l])


def refresco_servido():
    img, d = nuevo()
    d.line([(17, 3), (19, 14)], fill=C["rojo"], width=2)
    vaso(d, "cola", "cola_l")
    cubo(d, 13, 13, 4)
    cubo(d, 16, 18, 4)
    p(d, [(9, 10), (9, 11)], "blanco")
    return img


def cerveza_servida():
    img, d = nuevo()
    rect(d, 20, 13, 26, 15, "vidrio")
    rect(d, 24, 13, 26, 24, "vidrio")
    rect(d, 20, 22, 26, 24, "vidrio")
    rect(d, 6, 9, 21, 28, "vidrio")
    rect(d, 7, 12, 20, 27, "cerveza")
    rect(d, 8, 12, 9, 26, "cerveza_l")
    p(d, [(13, 22), (16, 18), (12, 16), (17, 24)], "cerveza_l")
    elipse(d, 5, 5, 12, 12, "espuma")
    elipse(d, 10, 4, 17, 11, "espuma")
    elipse(d, 15, 6, 22, 12, "espuma")
    rect(d, 6, 10, 21, 12, "espuma")
    p(d, [(7, 12), (10, 12), (14, 12), (18, 12), (20, 11)], "espuma_s")
    return img


def hamburguesa(d, x, y, ancho):
    alto = ancho * 3 // 4
    fin = x + ancho - 1
    elipse(d, x, y, fin, y + alto * 2 // 3, "pan")
    rect(d, x, y + alto // 3, fin, y + alto * 5 // 12, "pan")
    elipse(d, x + 2, y + 1, x + ancho // 2, y + alto // 3, "pan_l")
    for sx, sy in ((ancho // 3, alto // 6), (ancho // 2 + 1, alto // 8), (ancho * 2 // 3, alto // 4), (ancho // 4, alto // 3)):
        p(d, [(x + sx, y + sy)], "ajonjoli")
    capa = y + alto * 5 // 12 + 1
    rect(d, x, capa, fin, capa, "verde")
    p(d, [(x + i, capa + 1) for i in range(0, ancho, 3)], "verde")
    rect(d, x + 1, capa + 1, fin - 1, capa + 1, "queso")
    p(d, [(x + ancho // 3, capa + 2), (x + ancho * 2 // 3, capa + 2)], "queso")
    rect(d, x, capa + 2, fin, capa + 4, "carne_cocida")
    rect(d, x + 1, capa + 2, fin - 1, capa + 2, "carne_cocida_l")
    rect(d, x, capa + 5, fin, capa + 7, "pan_s")
    rect(d, x + 1, capa + 5, fin - 1, capa + 5, "pan")


def hamburguesa_icono():
    img, d = nuevo()
    hamburguesa(d, 3, 7, 26)
    p(d, [(6, 9), (7, 8)], "blanco")
    return img


def alita(d, x, y, invertir=False):
    puntos = [(0, 4), (3, 0), (9, 1), (13, 5), (12, 10), (7, 12), (2, 10)]
    if invertir:
        puntos = [(13 - px, py) for px, py in puntos]
    d.polygon([(x + px, y + py) for px, py in puntos], fill=C["alita"])
    p(d, [(x + (10 - i if invertir else 3 + i), y + 2) for i in range(4)], "alita_l")
    p(d, [(x + (11 - i if invertir else 2 + i), y + 3) for i in range(2)], "alita_l")
    p(d, [(x + (6 - i if invertir else 7 + i), y + 11) for i in range(4)], "alita_s")


def alitas():
    img, d = nuevo()
    alita(d, 3, 15)
    alita(d, 15, 15, True)
    alita(d, 9, 6)
    p(d, [(13, 8), (14, 8)], "blanco")
    return img


def papas_fritas(d, x, y, ancho, alto):
    for i in range(1, ancho - 1, 2):
        largo = 4 + (i * 7) % 5
        rect(d, x + i, y + 6 - largo, x + i, y + 6, "papa_frita")
        p(d, [(x + i, y + 6 - largo)], "papa_frita_s")
    d.polygon([(x, y + 5), (x + ancho - 1, y + 5), (x + ancho - 3, y + alto), (x + 2, y + alto)], fill=C["caja"])
    d.polygon([(x + 1, y + 6), (x + 3, y + 6), (x + 4, y + alto - 1), (x + 3, y + alto - 1)], fill=C["caja_l"])
    rect(d, x + ancho - 4, y + 6, x + ancho - 3, y + alto - 1, "caja_s")
    elipse(d, x + ancho // 2 - 3, y + alto // 2 + 1, x + ancho // 2 + 2, y + alto // 2 + 6, "papa_frita")


def papas_fritas_icono():
    img, d = nuevo()
    papas_fritas(d, 6, 6, 20, 22)
    return img


def estrella(d, cx, cy):
    rect(d, cx - 1, cy - 3, cx + 1, cy + 3, "estrella")
    rect(d, cx - 3, cy - 1, cx + 3, cy + 1, "estrella")
    p(d, [(cx - 2, cy + 2), (cx + 2, cy + 2), (cx - 2, cy - 2), (cx + 2, cy - 2)], "estrella")
    p(d, [(cx, cy - 4), (cx - 4, cy), (cx + 4, cy), (cx, cy + 4)], "estrella_s")


def combo():
    img, d = nuevo()
    papas_fritas(d, 16, 3, 13, 14)
    hamburguesa(d, 2, 13, 20)
    estrella(d, 6, 5)
    return img


def plato_sucio():
    img, d = nuevo()
    elipse(d, 2, 12, 29, 28, "plato_s")
    elipse(d, 2, 11, 29, 26, "plato")
    elipse(d, 8, 14, 23, 23, "plato_s")
    elipse(d, 9, 14, 23, 22, "plato")
    elipse(d, 11, 16, 16, 19, "mancha")
    p(d, [(19, 18), (20, 19), (18, 21), (7, 20), (22, 15), (14, 21)], "mancha")
    p(d, [(5, 14), (6, 13), (7, 13)], "blanco")
    return img


DIBUJOS = {
    "insumo_carne": carne,
    "insumo_pollo": pollo,
    "insumo_papas": papas_costal,
    "insumo_verdura": verdura,
    "insumo_pan": pan,
    "insumo_cerveza": cerveza_lata,
    "insumo_refresco": refresco_lata,
    "insumo_hielo": hielo,
    "platillo_refresco": refresco_servido,
    "platillo_cerveza": cerveza_servida,
    "platillo_hamburguesa": hamburguesa_icono,
    "platillo_alitas": alitas,
    "platillo_papas": papas_fritas_icono,
    "platillo_combo": combo,
    "plato_sucio": plato_sucio,
}


if __name__ == "__main__":
    hoja = Image.new("RGBA", tamano_hoja(), (0, 0, 0, 0))
    for i, (clave, _, _, _) in enumerate(ICONOS):
        hoja.alpha_composite(contorno(DIBUJOS[clave]()), posicion(i))
    ruta = os.path.join(CARPETA, "hoja_iconos.png")
    hoja.save(ruta)
    cortar(ruta)
