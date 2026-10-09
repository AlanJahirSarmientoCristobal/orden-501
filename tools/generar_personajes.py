import os
from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESTINO = os.path.join(RAIZ, "Assets", "sprites", "personajes")
PLANTILLAS = os.path.join(DESTINO, "plantillas")

BASE = {
    "K": (27, 27, 36),
    "E": (27, 27, 36),
    "w": (255, 255, 255),
    "m": (164, 82, 74),
    "G": (70, 76, 94),
    "L": (40, 40, 52),
}
PIELES = {
    "clara": [(245, 204, 170), (214, 166, 130)],
    "media": [(236, 184, 142), (201, 143, 104)],
    "morena": [(214, 160, 118), (176, 122, 86)],
    "oscura": [(176, 120, 84), (140, 92, 62)],
}

CABEZA_BASE = {
    "down": [
        "....SSSSSS....",
        "..SSSSSSSSSS..",
        ".SSSSSSSSSSSS.",
        "SSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSS",
        "sSSEwSSSSEwSSs",
        "sSSEESSSSEESSs",
        ".sSSSSSSSSSSs.",
        ".sSSSSmmSSSSs.",
        "..sSSSSSSSSs..",
        "..ssSSSSSSss..",
        "....ssssss....",
    ],
    "up": [
        "....SSSSSS....",
        "..SSSSSSSSSS..",
        ".SSSSSSSSSSSS.",
        "SSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSS",
        "sSSSSSSSSSSSSs",
        ".sSSSSSSSSSSs.",
        ".sSSSSSSSSSSs.",
        "..sSSSSSSSSs..",
        "..ssssssssss..",
        "....ssssss....",
    ],
    "side": [
        "...SSSSSS.....",
        "..SSSSSSSSS...",
        ".SSSSSSSSSSSS.",
        "SSSSSSSSSSSSS.",
        "SSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSS",
        "SSSSSSSSSSEwSS",
        "SSSSSSSSSSEESS",
        "sSSSSSSSSSSSSS",
        ".sSSSSSSSSSmS.",
        ".sssSSSSSSSS..",
        "..ssSSSSSSs...",
        "....sssss.....",
    ],
}

PEINADOS = {
    "dani": {
        "down": (0, [
            "....HHhHHh....", "..HHHhHHHhHH..", ".HHHHHHhHHHHH.", "GHHHHHHHHHHHHG",
            "GHHSSHHHSSSHHG", "GHSSSSSSSSSSHG", "GSSEwSSSSEwSSG", "GSSEESSSSEESSG",
            ".sSSSSSSSSSSG.", ".sSSSSmmSSSGs.", "..sSSSSSSSOs..", "..ssSSSSSSss..", "....ssssss...."]),
        "up": (0, [
            "....HHhHHh....", "..HHHhHHHhHH..", ".HHHHHHhHHHHH.", "GHHHHHHHHhHHHG",
            "GHHHhHHHHHHHHG", "GHHHHHHHhHHHHG", "GHHHHHHHHHHHHG", "GhHHHHHHHHHHhG",
            ".hhHHHHHHHHhh.", ".fffffffffffff", "..sfffffffffs.", "..ssssssssss..", "....ssssss...."]),
        "side": (0, [
            "...HHhHHh.....", "..HHHhHHHhH...", ".HHHHHHhHHHHH.", "HHHHHGHHHHHHH.",
            "HHHHHGHHHSSSSS", "fHHHHGGSSSSSSS", "fHHHHGGSSSEwSS", "ffHHHGGSSSEESS",
            "ffssSGSSSSSSSS", ".fssSSGSSSSmS.", ".sssSSSGGOSS..", "..ssSSSSSSs...", "....sssss....."]),
    },
    "corto": {
        "down": (0, [
            "....HHHHHH....", "..HHHHhHHHHH..", ".HHHHhHHHHHHH.", "HHHHHHHHHHHHHH",
            "HHSSSSSSSSSSHH", "H............H", "H............H"]),
        "up": (0, [
            "....HHHHHH....", "..HHHHhHHHHH..", ".HHHHhHHHHHHH.", "HHHHHHHHHHHHHH",
            "HHHHHHHHhHHHHH", "HHHhHHHHHHHHHH", "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH",
            ".HHHHHHHHHHHH.", ".HHHHHHHHHHHH.", "..hHHHHHHHHh.."]),
        "side": (0, [
            "...HHHHHH.....", "..HHHHhHHHH...", ".HHHHhHHHHHHH.", "HHHHHHHHHHHHH.",
            "HHHHHHHHHH....", "HHHHH.H.......", "HHHH..........", "HHH...........",
            ".HH..........."]),
    },
    "largo": {
        "down": (0, [
            "....HHHHHH....", "..HHHHhHHHHH..", ".HHHHhHHHHHHH.", "HHHHHHHHHHHHHH",
            "HHHHHSSHHHHHHH", "HH..........HH", "HH..........HH", "HH..........HH",
            "HH..........HH", "HH..........HH", "HHH........HHH", "HHH........HHH",
            "HH..........HH", "HH..........HH", "HH..........HH", "hh..........hh"]),
        "up": (0, [
            "....HHHHHH....", "..HHHHhHHHHH..", ".HHHHhHHHHHHH.", "HHHHHHHHHHHHHH",
            "HHHHHHHHhHHHHH", "HHHhHHHHHHHHHH", "HHHHHHHHHHhHHH", "HHHHHHHHHHHHHH",
            "HHHHhHHHHHHHHH", "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH", "HHHHHHHhHHHHHH",
            "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH", ".HHHHHHHHHHHH.", "..hHHhHHhHHh.."]),
        "side": (0, [
            "...HHHHHH.....", "..HHHHhHHHH...", ".HHHHhHHHHHHH.", "HHHHHHHHHHHHH.",
            "HHHHHHHHHHHH..", "HHHHHHHHH.....", "HHHHHHH.......", "HHHHHH........",
            "HHHHHH........", "HHHHHH........", "HHHHHH........", "HHHHHH........",
            "HHHHH.........", "HHHHH.........", "HHHHH.........", "hHHh.........."]),
    },
    "chongo": {
        "down": (-1, [
            ".....HhHH.....", "....HHHHHH....", "..HHHHhHHHHH..", ".HHHHHHHHhHHH.",
            "HHHHHHHHHHHHHH", "HHHSSSHHSSSHHH", "HH..........HH", "H............H"]),
        "up": (-1, [
            ".....HhHH.....", "....HHHHHH....", "..HHHHhHHHHH..", ".HHHHHHHHhHHH.",
            "HHHHHHHHHHHHHH", "HHHhHHHHHHHHHH", "HHHHHHHHhHHHHH", "HHHHHHHHHHHHHH",
            "HHHHHHHHHHHHHH", "HhHHHHHHHHHHhH", ".HHHHHHHHHHHH.", ".hhHHHHHHHHhh."]),
        "side": (-1, [
            "..HhHH........", "..HHHHHHH.....", "..HHHHhHHHH...", ".HHHHhHHHHHHH.",
            "HHHHHHHHHHHHH.", "HHHHHHHHHH....", "HHHHH.H.......", "HHHH..........",
            "HHH...........", ".HH..........."]),
    },
    "calvo": {
        "down": (0, ["", ".....ww.......", "", "", "HH..........HH", "HH..........HH",
                     "H............H", "H............H"]),
        "up": (0, ["", ".....ww.......", "", "", "", "HHHHHHHHHHHHHH", "HHHHHHHhHHHHHH",
                   "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH", "HhHHHHHHHHHHhH", ".HHHHHHHHHHHH."]),
        "side": (0, ["", "....ww........", "", "", "", "HHHH..........", "HHHH..........",
                     "HHH...........", ".HH..........."]),
    },
    "gorra": {
        "down": (0, [
            "....CCCCCC....", "..CCCCcCCCCC..", ".CCCCCCCCCCCC.", "CCCCCCCCCCCCCC",
            "cccccccccccccc", "H............H", "H............H"]),
        "up": (0, [
            "....CCCCCC....", "..CCCCcCCCCC..", ".CCCCCCCCCCCC.", "CCCCCCCCCCCCCC",
            "CCCCCCcCCCCCCC", "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH",
            "HHHHHHHHHHHHHH", ".HHHHHHHHHHHH.", ".HHHHHHHHHHHH."]),
        "side": (0, [
            "...CCCCCC.....", "..CCCCcCCCC...", ".CCCCCCCCCCCC.", "CCCCCCCCCCCCC.",
            "HHHHHHHHHccccccc", "HHHH.H..........", "HHH.............", ".HH............."]),
    },
    "chef": {
        "down": (-2, [
            "...CCCCCCCC...", "..CCCcCCCCCC..", "..CCCCCCcCCC..", ".cccccccccccc.",
            ".HHHHHHHHHHHH.", "HHH........HHH", "HH..........HH"]),
        "up": (-2, [
            "...CCCCCCCC...", "..CCCcCCCCCC..", "..CCCCCCcCCC..", ".cccccccccccc.",
            ".HHHHHHHHHHHH.", "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH",
            "HHHHHHHHHHHHHH", "HHHHHHHHHHHHHH", ".HHHHHHHHHHHH.", ".hHHHHHHHHHHh."]),
        "side": (-2, [
            "..CCCCCCCC....", ".CCCcCCCCCC...", ".CCCCCCCcCC...", "cccccccccccc..",
            "HHHHHHHHHHH...", "HHHHHHH.......", "HHHHH.........", "HHHH..........",
            "HHH...........", ".HH..........."]),
    },
}

ACCESORIOS = {
    "lentes": {
        "down": (5, ["..LLLL..LLLL..", "..L..LLLL..L..", "..LLLL..LLLL.."]),
        "side": (5, ["..........LLL.", ".....LLLLL..L.", "..........LLL."]),
    },
    "lentes_sol": {
        "down": (5, ["..LLLL..LLLL..", "..LLLLLLLLLL..", "..LLLL..LLLL.."]),
        "side": (5, ["..........LLLL", ".....LLLLLLLLL", "..........LLL."]),
    },
    "bigote": {
        "down": (9, ["....BBBBBB...."]),
        "side": (9, ["..........BBB."]),
    },
}

def poner(img, pal, x0, y0, filas):
    for y, fila in enumerate(filas):
        for x, c in enumerate(fila):
            px, py = x0 + x, y0 + y
            if c != "." and 0 <= px < 32 and 0 <= py < 32:
                img.putpixel((px, py), pal[c] + (255,))

def rect(img, pal, x0, y0, x1, y1, c):
    for y in range(max(y0, 0), min(y1, 31) + 1):
        for x in range(max(x0, 0), min(x1, 31) + 1):
            img.putpixel((x, y), pal[c] + (255,))

def contorno(img, pal):
    lleno = [[img.getpixel((x, y))[3] > 0 for x in range(32)] for y in range(32)]
    for y in range(32):
        for x in range(32):
            if not lleno[y][x] and any(
                    0 <= x + dx < 32 and 0 <= y + dy < 32 and lleno[y + dy][x + dx]
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                img.putpixel((x, y), pal["K"] + (255,))

def pierna(img, pal, x0, x1, y_fin, sombra):
    rect(img, pal, x0, 24, x1, min(25, y_fin), "p" if sombra else "P")
    if y_fin >= 26:
        rect(img, pal, x0, 26, x1, y_fin, "q" if sombra else "Q")

def cuadro(pj, pal, direccion, paso):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    bob = 1 if paso and pj.get("bob", True) else 0
    y = 16 - bob
    largas = pj.get("mangas_largas", False)
    if direccion in ("down", "up"):
        for x, alzada, sombra in ((11, paso == 1, False), (17, paso == 2, True)):
            fin = 28 - int(alzada)
            pierna(img, pal, x, x + 3, fin, sombra)
            ancho = (x - 1, x + 3) if x < 16 else (x, x + 4)
            rect(img, pal, ancho[0], fin + 1, ancho[1], fin + 1, "W")
            rect(img, pal, ancho[0], fin + 2, ancho[1], fin + 2, "u")
        rect(img, pal, 11, y, 20, 23, "T")
        rect(img, pal, 11, 23, 20, 23, "t")
        if pj.get("vestido"):
            rect(img, pal, 10, y + 8, 21, 27, "T")
            rect(img, pal, 10, 27, 21, 27, "t")
        rect(img, pal, 8, y, 23, y + 1, "T")
        rect(img, pal, 8, y, 10, y + 2, "O")
        rect(img, pal, 21, y, 23, y + 2, "O")
        rect(img, pal, 8, y + 2, 10, y + 2, "o")
        rect(img, pal, 21, y + 2, 23, y + 2, "o")
        for x, largo in ((8, 3 if paso == 2 else 4), (22, 3 if paso == 1 else 4)):
            if largas:
                rect(img, pal, x, y + 3, x + 1, y + 1 + largo, "O")
                rect(img, pal, x, y + 2 + largo, x + 1, y + 2 + largo, "S")
            else:
                rect(img, pal, x, y + 3, x + 1, y + 2 + largo, "S")
        if direccion == "down":
            cuello = pj.get("cuello", "S")
            if cuello:
                rect(img, pal, 14, y, 17, y, cuello)
                rect(img, pal, 15, y + 1, 16, y + 1, cuello)
            if "A" in pal:
                rect(img, pal, 12, y + 3, 19, 26, "A")
                rect(img, pal, 12, 26, 19, 26, "a")
                for x in (13, 18):
                    rect(img, pal, x, y, x, y + 2, "A")
            for dx, dy, c in pj.get("frente", []):
                poner(img, pal, dx, y + dy, [c])
        else:
            rect(img, pal, 14, y, 17, y, "s")
            if "A" in pal:
                rect(img, pal, 11, y + 6, 20, y + 6, "a")
                rect(img, pal, 15, y + 7, 16, y + 7, "a")
            for dx, dy, c in pj.get("espalda", []):
                poner(img, pal, dx, y + dy, [c])
    else:
        if paso == 0:
            pierna(img, pal, 13, 18, 28, False)
            rect(img, pal, 13, 29, 20, 29, "W")
            rect(img, pal, 13, 30, 20, 30, "u")
        else:
            atras, frente = (True, False) if paso == 1 else (False, True)
            pierna(img, pal, 11, 14, 27, atras)
            rect(img, pal, 9, 28, 13, 28, "W")
            rect(img, pal, 9, 29, 13, 29, "u")
            pierna(img, pal, 17, 20, 28, frente)
            rect(img, pal, 17, 29, 22, 29, "W")
            rect(img, pal, 17, 30, 22, 30, "u")
        rect(img, pal, 11, y, 20, 23, "T")
        rect(img, pal, 11, 23, 20, 23, "t")
        rect(img, pal, 11, y, 12, 22, "t")
        if pj.get("vestido"):
            rect(img, pal, 10, y + 8, 21, 27, "T")
            rect(img, pal, 10, 27, 21, 27, "t")
        if "A" in pal:
            rect(img, pal, 18, y + 3, 20, 26, "A")
            rect(img, pal, 18, y, 18, y + 2, "A")
        for dx, dy, c in pj.get("lado", []):
            poner(img, pal, dx, y + dy, [c])
        dx = {0: 0, 1: 2, 2: -2}[paso]
        rect(img, pal, 14 + dx, y, 17 + dx, y + 2, "O")
        rect(img, pal, 14 + dx, y + 2, 17 + dx, y + 2, "o")
        if largas:
            rect(img, pal, 15 + dx, y + 3, 16 + dx, y + 5, "O")
            rect(img, pal, 15 + dx, y + 6, 16 + dx, y + 6, "S")
        else:
            rect(img, pal, 15 + dx, y + 3, 16 + dx, y + 6, "S")
        for ddx, ddy, c in pj.get("brazo", []):
            poner(img, pal, ddx + dx, y + ddy, [c])
    cy = 3 - bob
    peinado = PEINADOS[pj["pelo"]]
    if pj["pelo"] != "dani":
        poner(img, pal, 9, cy, CABEZA_BASE[direccion])
    fila, filas = peinado[direccion]
    poner(img, pal, 9, cy + fila, filas)
    for acc in pj.get("accesorios", []):
        if direccion in ACCESORIOS[acc]:
            fila, filas = ACCESORIOS[acc][direccion]
            poner(img, pal, 9, cy + fila, filas)
    contorno(img, pal)
    return img

def hoja(pj):
    pal = dict(BASE)
    pal["S"], pal["s"] = PIELES[pj.get("piel", "media")]
    pal["f"] = pj["colores"].get("f", pal["s"])
    pal.update(pj["colores"])
    pal.setdefault("B", pal["H"])
    pal.setdefault("Q", pal["P"])
    pal.setdefault("q", pal["p"])
    img = Image.new("RGBA", (128, 96), (0, 0, 0, 0))
    for fila, direccion in enumerate(["down", "up", "side"]):
        for col, paso in enumerate([0, 1, 0, 2]):
            img.paste(cuadro(pj, pal, direccion, paso), (col * 32, fila * 32))
    return img

NEGRO = (30, 30, 38)
BLANCO = (238, 238, 242)
GRIS_BLANCO = (196, 198, 210)

PERSONAJES = {
    "player": {
        "nombre": "Dani", "pelo": "dani",
        "colores": {"H": (52, 38, 34), "h": (92, 66, 54), "f": (98, 76, 68),
                    "T": (38, 42, 58), "t": (28, 31, 44), "O": (255, 122, 47), "o": (214, 86, 26),
                    "P": (104, 110, 128), "p": (78, 83, 99), "W": (242, 242, 246), "u": (190, 194, 208),
                    "D": (255, 122, 47)},
        "frente": [(17, 3, "DD")], "espalda": [(12, 4, "DDDDDDDD")],
    },
    "npc1": {
        "nombre": "Chef", "pelo": "chef", "piel": "morena", "bob": False, "mangas_largas": True,
        "accesorios": ["bigote"], "cuello": "D",
        "colores": {"H": (40, 30, 28), "h": (70, 52, 44), "C": BLANCO, "c": GRIS_BLANCO,
                    "T": BLANCO, "t": GRIS_BLANCO, "O": BLANCO, "o": GRIS_BLANCO,
                    "P": (52, 54, 66), "p": (40, 42, 52), "W": NEGRO, "u": (60, 60, 70),
                    "D": (214, 58, 58), "d": (60, 60, 72)},
        "frente": [(13, 3, "d"), (13, 5, "d"), (18, 3, "d"), (18, 5, "d")],
        "lado": [(19, 3, "d"), (19, 5, "d")],
    },
    "npc2": {
        "nombre": "Don Chema", "pelo": "calvo", "piel": "morena", "accesorios": ["bigote"],
        "colores": {"H": (200, 200, 206), "h": (230, 230, 234), "w": (255, 226, 196),
                    "T": (86, 128, 176), "t": (64, 100, 142), "O": (86, 128, 176), "o": (64, 100, 142),
                    "A": (240, 236, 226), "a": (200, 194, 180),
                    "P": (110, 84, 62), "p": (88, 66, 48), "W": (84, 58, 40), "u": (60, 42, 30),
                    "D": (196, 70, 70)},
        "frente": [(16, 6, "D"), (14, 8, "D")],
    },
    "npc3": {
        "nombre": "Lupita", "pelo": "largo", "piel": "clara",
        "colores": {"H": (196, 74, 40), "h": (232, 120, 70),
                    "T": NEGRO, "t": (20, 20, 26), "O": NEGRO, "o": (20, 20, 26),
                    "A": (46, 128, 84), "a": (32, 96, 62),
                    "P": (58, 84, 140), "p": (44, 64, 110), "W": BLANCO, "u": GRIS_BLANCO,
                    "D": (250, 200, 60)},
        "frente": [(15, 5, "DD")], "espalda": [(14, 3, "DDDD")],
    },
    "npc4": {
        "nombre": "Cliente VIP", "pelo": "corto", "piel": "media", "mangas_largas": True,
        "accesorios": ["lentes_sol"], "cuello": "V",
        "colores": {"H": (24, 22, 26), "h": (60, 56, 70), "L": (20, 20, 28),
                    "T": (34, 34, 42), "t": (22, 22, 28), "O": (34, 34, 42), "o": (22, 22, 28),
                    "V": BLANCO, "P": (34, 34, 42), "p": (22, 22, 28),
                    "W": (60, 40, 30), "u": (40, 26, 20), "D": (240, 196, 60)},
        "frente": [(15, 1, "DD"), (15, 2, "DD"), (20, 3, "D")], "lado": [(19, 1, "D")],
    },
    "npc5": {
        "nombre": "Crítico", "pelo": "corto", "piel": "clara", "mangas_largas": True,
        "accesorios": ["lentes"], "cuello": "V",
        "colores": {"H": (90, 90, 100), "h": (140, 140, 150),
                    "T": (110, 70, 150), "t": (84, 52, 116), "O": (110, 70, 150), "o": (84, 52, 116),
                    "V": BLANCO, "P": NEGRO, "p": (20, 20, 26), "W": (110, 70, 40), "u": (80, 50, 30),
                    "D": (250, 210, 90)},
        "frente": [(13, 0, "DDDDDD"), (13, 1, "D")],
    },
    "npc6": {
        "nombre": "Doña Mari", "pelo": "chongo", "piel": "morena", "vestido": True,
        "colores": {"H": (190, 190, 198), "h": (226, 226, 232),
                    "T": (170, 60, 110), "t": (132, 42, 84), "O": (170, 60, 110), "o": (132, 42, 84),
                    "P": (170, 60, 110), "p": (132, 42, 84), "Q": (214, 160, 118), "q": (176, 122, 86),
                    "W": (100, 64, 44), "u": (70, 44, 30), "D": (250, 220, 120)},
        "frente": [(13, 4, "D"), (17, 6, "D"), (14, 9, "D"), (19, 10, "D")],
        "espalda": [(14, 4, "D"), (18, 7, "D"), (12, 10, "D")],
    },
    "npc7": {
        "nombre": "Profe Juve", "pelo": "corto", "piel": "media", "mangas_largas": True,
        "accesorios": ["lentes"],
        "colores": {"H": (40, 34, 32), "h": (84, 76, 72),
                    "T": (36, 58, 120), "t": (26, 42, 92), "O": (36, 58, 120), "o": (26, 42, 92),
                    "P": (36, 58, 120), "p": (26, 42, 92), "W": BLANCO, "u": GRIS_BLANCO,
                    "D": BLANCO, "d": (200, 204, 214)},
        "frente": [(8, 1, "D"), (23, 1, "D"), (16, 3, "d")],
        "espalda": [(8, 1, "D"), (23, 1, "D"), (12, 3, "DDDDDDDD")],
    },
    "npc8": {
        "nombre": "Capitán", "pelo": "corto", "piel": "oscura",
        "colores": {"H": (20, 18, 20), "h": (56, 50, 50),
                    "T": (30, 140, 80), "t": (20, 106, 58), "O": BLANCO, "o": GRIS_BLANCO,
                    "P": BLANCO, "p": GRIS_BLANCO, "Q": (30, 140, 80), "q": (20, 106, 58),
                    "W": NEGRO, "u": (70, 70, 80), "D": BLANCO, "d": (250, 210, 50)},
        "frente": [(14, 0, "DDDD"), (21, 2, "ddd")],
        "espalda": [(12, 3, "DD.DDD"), (13, 4, "D.D.D"), (13, 5, "D.DDD"), (8, 2, "ddd")],
        "brazo": [(14, 2, "dddd")],
    },
    "npc9": {
        "nombre": "Cliente 1", "pelo": "gorra", "piel": "morena",
        "colores": {"H": (36, 28, 26), "h": (70, 56, 50), "C": (200, 50, 50), "c": (150, 34, 34),
                    "T": BLANCO, "t": GRIS_BLANCO, "O": BLANCO, "o": GRIS_BLANCO,
                    "P": (58, 84, 140), "p": (44, 64, 110), "W": (210, 60, 60), "u": BLANCO,
                    "D": (60, 110, 200)},
        "frente": [(14, 3, "DDDD"), (14, 4, "D..D"), (14, 5, "DDDD")],
    },
    "npc10": {
        "nombre": "Cliente 2", "pelo": "largo", "piel": "media",
        "colores": {"H": (70, 44, 30), "h": (120, 80, 56),
                    "T": (40, 160, 160), "t": (28, 122, 122), "O": (40, 160, 160), "o": (28, 122, 122),
                    "P": (40, 44, 70), "p": (30, 32, 54), "W": BLANCO, "u": GRIS_BLANCO,
                    "D": BLANCO},
        "frente": [(15, 4, "DD")],
    },
    "npc11": {
        "nombre": "Cliente 3", "pelo": "corto", "piel": "clara", "accesorios": ["lentes", "bigote"],
        "colores": {"H": (170, 170, 176), "h": (210, 210, 216),
                    "T": (140, 40, 56), "t": (106, 28, 40), "O": (140, 40, 56), "o": (106, 28, 40),
                    "P": (196, 170, 120), "p": (160, 136, 94), "W": (100, 64, 44), "u": (70, 44, 30),
                    "D": BLANCO},
        "frente": [(14, 0, "D"), (17, 0, "D")],
    },
}

def vistas(hojas):
    fondo = (60, 70, 86, 255)
    z = 4
    columnas = 4
    celda = (3 * 32 * z + 24, 32 * z + 40)
    filas = (len(hojas) + columnas - 1) // columnas
    img = Image.new("RGBA", (celda[0] * columnas, celda[1] * filas), fondo)
    try:
        from PIL import ImageDraw, ImageFont
        d = ImageDraw.Draw(img)
        fuente = ImageFont.truetype("arial.ttf", 18)
    except OSError:
        d, fuente = ImageDraw.Draw(img), None
    for i, (codigo, h) in enumerate(hojas.items()):
        x0, y0 = (i % columnas) * celda[0] + 12, (i // columnas) * celda[1] + 8
        d.text((x0, y0), "%s  (%s)" % (codigo, PERSONAJES[codigo]["nombre"]), fill="white", font=fuente)
        for j in range(3):
            c = h.crop((0, j * 32, 32, j * 32 + 32)).resize((32 * z, 32 * z), Image.NEAREST)
            img.alpha_composite(c, (x0 + j * 32 * z, y0 + 30))
    img.save(os.path.join(PLANTILLAS, "vista_personajes.png"))
    cuadros = []
    for paso in range(8):
        lienzo = Image.new("RGBA", (32 * len(hojas), 32), fondo)
        for i, h in enumerate(hojas.values()):
            lienzo.alpha_composite(h.crop(((paso % 4) * 32, 0, (paso % 4) * 32 + 32, 32)), (i * 32, 0))
        cuadros.append(lienzo.resize((lienzo.width * 3, 96), Image.NEAREST).convert("P"))
    cuadros[0].save(os.path.join(PLANTILLAS, "personajes_caminando.gif"), save_all=True,
                    append_images=cuadros[1:], duration=125, loop=0)

if __name__ == "__main__":
    os.makedirs(PLANTILLAS, exist_ok=True)
    hojas = {}
    for codigo, pj in PERSONAJES.items():
        hojas[codigo] = hoja(pj)
        hojas[codigo].save(os.path.join(DESTINO, codigo + ".png"))
    vistas(hojas)
    print("listo:", ", ".join(hojas))
