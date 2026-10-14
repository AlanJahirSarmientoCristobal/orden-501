import json
import random
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
COLUMNAS, FILAS = 54, 30
ATLAS_COLUMNAS = 27
random.seed(501)

VACIO = -1
suelo = [[VACIO] * COLUMNAS for _ in range(FILAS)]
objetos = [[VACIO] * COLUMNAS for _ in range(FILAS)]
copas = [[VACIO] * COLUMNAS for _ in range(FILAS)]
solidos = set()

BANQUETA = [[8, 9, 10], [35, 36, 37], [62, 63, 64]]
PASTO = [[0, 1, 2], [27, 28, 29], [54, 55, 56]]
AGUA = [[170, 171, 172], [197, 198, 199], [224, 225, 226]]
TECHO_MORADO = [[81, 82, 83], [108, 109, 110], [135, 136, 137]]
TECHO_GRIS = [[89, 90, 91], [116, 117, 118], [143, 144, 145]]

FACHADA_ROJA = {"pilar": [16, 70, 97], "arriba": [20, 21, 22], "franja": [47, 48, 49], "baja": [101, 102, 103]}
FACHADA_NARANJA = {"pilar": [124, 151, 205], "arriba": [128, 129, 130], "franja": [155, 156, 157], "baja": [209, 210, 211]}

CALLE_H = [406, 433, 460]
CALLE_V = [461, 462, 463]
CEBRA_H = [405, 432, 459]
CEBRA_V = [434, 435, 436]
ASFALTO = 441

AUTOS_FRENTE = [[[447, 448], [474, 475]], [[393, 394], [420, 421]], [[396, 397], [423, 424]]]
AUTOS_LADO = [[453, 454], [480, 481]]
ESTACIONAMIENTO = 442
ARBOLES_DOBLES = [(233, 260), (232, 259), (314, 341), (313, 340)]
MACETEROS = [(233, 287), (232, 286)]
ARBOLES = [292, 319, 238, 265]
FAROL = (169, 196)
POSTE_LUZ = (164, 191)
BANCA = 270
BOTE = 253
BUZON = 305
HIDRANTE = 251
VENTANA = 362
VENTANA_ALTA = 389
PUERTA = 283
PUERTA_DOBLE = 284
PUERTA_TIENDA = 285
VITRINA = [386, 387, 388]
PUERTAS_VIDRIO = [412, 413]
TOLDO = [328, 329, 330]
TOLDO_PUERTA = 332
AIRE = [333, 334]
CERCA = [382, 383, 384]

SOLIDOS_OBJETO = set(ARBOLES + [t for _, t in ARBOLES_DOBLES + MACETEROS] + [BANCA, BOTE, BUZON, HIDRANTE, 382, 383, 384, 385])

def poner(capa, x, y, tile, solido=False):
    if 0 <= x < COLUMNAS and 0 <= y < FILAS:
        capa[y][x] = tile
        nombre_capa = "suelo" if capa is suelo else ("copas" if capa is copas else "objetos")
        if solido:
            solidos.add((nombre_capa, x, y))
        else:
            solidos.discard((nombre_capa, x, y))

def arbol(x, y, opciones=None):
    if y > 0 and copas[y - 1][x] == VACIO and objetos[y - 1][x] == VACIO:
        copa, tronco = random.choice(opciones or ARBOLES_DOBLES)
        poner(objetos, x, y, tronco, solido=True)
        poner(copas, x, y - 1, copa)
    else:
        poner(objetos, x, y, random.choice(ARBOLES), solido=True)

def nueve(capa, x0, y0, ancho, alto, piezas, solido=False):
    for y in range(alto):
        for x in range(ancho):
            fila = 0 if y == 0 else (2 if y == alto - 1 else 1)
            col = 0 if x == 0 else (2 if x == ancho - 1 else 1)
            poner(capa, x0 + x, y0 + y, piezas[fila][col], solido)

def calle_horizontal(y0, x0, x1):
    for x in range(x0, x1):
        for i in range(3):
            poner(suelo, x, y0 + i, CALLE_H[i])

def calle_vertical(x0, y0, y1):
    for y in range(y0, y1):
        for i in range(3):
            poner(suelo, x0 + i, y, CALLE_V[i])

def cruce(x0, y0):
    for y in range(3):
        for x in range(3):
            poner(suelo, x0 + x, y0 + y, ASFALTO)

def cebra_h(x, y0):
    for i in range(3):
        poner(suelo, x, y0 + i, CEBRA_H[i])

def cebra_v(x0, y):
    for i in range(3):
        poner(suelo, x0 + i, y, CEBRA_V[i])

AV_Y = 13
AV_X = 25
SUR_Y = 23

nueve(suelo, 0, 0, AV_X, AV_Y, BANQUETA)
nueve(suelo, AV_X + 3, 0, COLUMNAS - AV_X - 3, AV_Y, BANQUETA)
nueve(suelo, 0, AV_Y + 3, AV_X, FILAS - AV_Y - 3, BANQUETA)
nueve(suelo, AV_X + 3, AV_Y + 3, COLUMNAS - AV_X - 3, SUR_Y - AV_Y - 3, BANQUETA)
nueve(suelo, AV_X + 3, SUR_Y + 3, COLUMNAS - AV_X - 3, FILAS - SUR_Y - 3, BANQUETA)

calle_horizontal(AV_Y, 0, COLUMNAS)
calle_vertical(AV_X, 0, FILAS)
calle_horizontal(SUR_Y, AV_X + 3, COLUMNAS)
cruce(AV_X, AV_Y)
cruce(AV_X, SUR_Y)
for x in (AV_X - 1, AV_X + 3):
    cebra_h(x, AV_Y)
cebra_h(AV_X + 3, SUR_Y)
for y in (AV_Y - 1, AV_Y + 3, SUR_Y - 1, SUR_Y + 3):
    cebra_v(AV_X, y)

lugares = {}

def edificio(nombre, x0, y0, ancho, techo, fachada, alto_techo=3, puerta="doble", ventanas=True, toldo=False, vitrina=False):
    nueve(suelo, x0, y0, ancho, alto_techo, techo, solido=True)
    yf = y0 + alto_techo
    for i, clave in enumerate(["arriba", "franja", "baja"]):
        y = yf + i
        for x in range(ancho):
            if x == 0 or x == ancho - 1:
                tile = fachada["pilar"][i]
            else:
                fila = fachada[clave]
                tile = fila[0] if x == 1 else (fila[2] if x == ancho - 2 else fila[1])
            poner(suelo, x0 + x, y, tile, solido=True)
    centro = x0 + ancho // 2
    if ventanas:
        for x in range(x0 + 1, x0 + ancho - 1):
            if (x - x0) % 2 == 1:
                poner(objetos, x, yf, VENTANA)
            poner(objetos, x, yf + 1, VENTANA_ALTA if (x - x0) % 3 == 1 else VACIO)
    yb = yf + 2
    if vitrina:
        for x in range(x0 + 1, x0 + ancho - 1):
            poner(suelo, x, yb, VITRINA[0] if x == x0 + 1 else (VITRINA[2] if x == x0 + ancho - 2 else VITRINA[1]), solido=True)
    if toldo:
        for x in range(x0 + 1, x0 + ancho - 1):
            poner(objetos, x, yb, TOLDO[(x - x0 - 1) % 3])
    if puerta == "vidrio":
        poner(suelo, centro - 1, yb, PUERTAS_VIDRIO[0], solido=True)
        poner(suelo, centro, yb, PUERTAS_VIDRIO[1], solido=True)
        puerta_x = centro - 0.5
    else:
        tile = {"doble": PUERTA_DOBLE, "sencilla": PUERTA, "tienda": PUERTA_TIENDA}[puerta]
        poner(suelo, centro, yb, tile, solido=True)
        if toldo:
            poner(objetos, centro, yb, TOLDO_PUERTA)
        puerta_x = centro
    poner(objetos, x0 + 1, y0 + 1, AIRE[0])
    if ancho > 5:
        poner(objetos, x0 + ancho - 2, y0 + 1, AIRE[1])
    if nombre:
        lugares[nombre] = {
            "rect": [x0, y0, ancho, alto_techo + 3],
            "puerta": [puerta_x + 0.5, yb + 1.5],
        }

def casa(x0, y0, ancho, estilo):
    techo = TECHO_MORADO if estilo % 2 == 0 else TECHO_GRIS
    fachada = FACHADA_ROJA if estilo % 3 != 1 else FACHADA_NARANJA
    edificio(None, x0, y0, ancho, techo, fachada, alto_techo=2, puerta="sencilla")

edificio("restaurante", 3, 2, 11, TECHO_MORADO, FACHADA_ROJA, alto_techo=3, puerta="vidrio")
casa(20, 3, 4, 2)
edificio("mercado", 31, 2, 12, TECHO_GRIS, FACHADA_NARANJA, alto_techo=3, puerta="tienda", toldo=True, vitrina=True)
casa(45, 3, 4, 1)
casa(50, 3, 4, 3)
edificio("cerveceria", 34, 16, 10, TECHO_MORADO, FACHADA_NARANJA, alto_techo=2, puerta="vidrio", vitrina=True)
casa(29, 17, 4, 4)
casa(29, 26, 4, 2)

PARQUE = (1, 17, 23, 12)
px, py, pw, ph = PARQUE
mitad_x, mitad_y = px + pw // 2, py + ph // 2
jardines = [
    (px, py, mitad_x - px - 1, mitad_y - py - 1),
    (mitad_x + 2, py, px + pw - mitad_x - 2, mitad_y - py - 1),
    (px, mitad_y + 2, mitad_x - px - 1, py + ph - mitad_y - 2),
    (mitad_x + 2, mitad_y + 2, px + pw - mitad_x - 2, py + ph - mitad_y - 2),
]
for jx, jy, jw, jh in jardines:
    nueve(suelo, jx, jy, jw, jh, PASTO)
nueve(suelo, mitad_x - 2, mitad_y - 2, 5, 5, AGUA, solido=True)
lugares["parque"] = {"rect": [px, py, pw, ph], "estanque": [mitad_x + 0.5, mitad_y + 0.5]}
for jx, jy, jw, jh in jardines:
    for ty in range(jy + 1, jy + jh - 1, 2):
        for tx in range(jx + 1 + (ty % 3), jx + jw - 1, 3):
            if random.random() < 0.6:
                arbol(tx, ty)
for x in (mitad_x - 3, mitad_x + 3):
    for y in (mitad_y - 3, mitad_y + 3):
        poner(objetos, x, y, BANCA)

nueve(suelo, 16, 6, 3, 3, AGUA, solido=True)
lugares["plaza"] = {"rect": [14, 3, 8, 8], "fuente": [17.5, 7.5]}
for x in (15, 19):
    poner(objetos, x, 7, BANCA)
for x, y in [(15, 4), (19, 4), (15, 10), (19, 10)]:
    arbol(x, y, MACETEROS)

nueve(suelo, 35, 26, 18, 4, PASTO)
lugares["cancha"] = {"rect": [35, 26, 18, 4]}

for x in range(2, COLUMNAS, 6):
    if abs(x - AV_X - 1) > 3:
        poner(objetos, x, AV_Y - 2, FAROL[0])
        poner(objetos, x, AV_Y - 1, FAROL[1])
for y in range(2, FILAS, 6):
    if abs(y - AV_Y - 1) > 3 and abs(y - SUR_Y - 1) > 3:
        poner(objetos, AV_X - 1, y - 1, POSTE_LUZ[0])
        poner(objetos, AV_X - 1, y, POSTE_LUZ[1])
for x, y, t in [(3, 12, BOTE), (24, 12, BUZON), (28, 12, HIDRANTE), (45, 12, BOTE), (28, 22, BUZON), (52, 22, BOTE), (15, 12, HIDRANTE)]:
    poner(objetos, x, y, t, solido=True)
for x in range(1, COLUMNAS, 7):
    if suelo[0][x] in (8, 9, 10) and objetos[0][x] == VACIO:
        arbol(x, 0)

def auto_lado(x, y, modelo):
    for fx in range(2):
        poner(objetos, x + fx, y, modelo[fx], solido=True)

for x, y in [(4, AV_Y), (18, AV_Y + 2), (33, AV_Y), (47, AV_Y + 2), (38, SUR_Y), (50, SUR_Y + 2), (10, AV_Y + 2)]:
    auto_lado(x, y, random.choice(AUTOS_LADO))

def auto_frente(x, y, modelo):
    for fy in range(2):
        for fx in range(2):
            poner(objetos, x + fx, y + fy, modelo[fy][fx], solido=True)

for y in range(17, 21):
    for x in range(46, 53):
        poner(suelo, x, y, ASFALTO)
for x in range(46, 53, 2):
    poner(suelo, x, 20, ESTACIONAMIENTO)
auto_frente(46, 18, AUTOS_FRENTE[0])
auto_frente(50, 18, AUTOS_FRENTE[1])
lugares["estacionamiento"] = {"rect": [46, 17, 7, 4]}

for x in range(35, 53):
    if abs(x - 44) > 1:
        poner(objetos, x, 25 + 1 - 1 + 0, VACIO)
for x in range(35, 53):
    if abs(x - 44) > 1:
        poner(objetos, x, 26, CERCA[(x - 35) % 3], solido=True)

for x, y in [(2, 8), (12, 10), (23, 10), (30, 8), (44, 9), (52, 10), (44, 21), (2, 28), (23, 28), (33, 28)]:
    if objetos[y][x] == VACIO and ("objetos", x, y) not in solidos:
        arbol(x, y)

datos = {
    "columnas": COLUMNAS,
    "filas": FILAS,
    "tile": 16,
    "escala": 3,
    "atlas_columnas": ATLAS_COLUMNAS,
    "suelo": suelo,
    "objetos": objetos,
    "copas": copas,
    "solidos": sorted([list(p) for p in solidos]),
    "calles": {"avenida": [0, AV_Y, COLUMNAS, 3], "avenida_vertical": [AV_X, 0, 3, FILAS], "calle_sur": [AV_X + 3, SUR_Y, COLUMNAS - AV_X - 3, 3]},
    "lugares": lugares,
    "inicio": [lugares["restaurante"]["puerta"][0], lugares["restaurante"]["puerta"][1] + 1],
}
salida = RAIZ / "scenes/town/mapa_pueblo.json"
salida.write_text(json.dumps(datos), encoding="utf-8")
print(f"Mapa guardado en {salida}")

if len(sys.argv) > 1:
    from PIL import Image
    atlas = Image.open(RAIZ / "Assets/sprites/pueblo/pueblo.png").convert("RGBA")

    def tile(i):
        return atlas.crop(((i % ATLAS_COLUMNAS) * 16, (i // ATLAS_COLUMNAS) * 16, (i % ATLAS_COLUMNAS) * 16 + 16, (i // ATLAS_COLUMNAS) * 16 + 16))

    vista = Image.new("RGBA", (COLUMNAS * 16, FILAS * 16), (30, 30, 40, 255))
    for capa in (suelo, objetos, copas):
        for y in range(FILAS):
            for x in range(COLUMNAS):
                if capa[y][x] != VACIO:
                    vista.alpha_composite(tile(capa[y][x]), (x * 16, y * 16))
    vista = vista.resize((vista.width * 2, vista.height * 2), Image.NEAREST)
    vista.save(sys.argv[1])
    print(f"Vista previa: {sys.argv[1]}")
