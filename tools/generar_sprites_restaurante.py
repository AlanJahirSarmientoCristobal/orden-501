from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
SALIDA = RAIZ / "Assets/sprites/restaurante"

NEGRO = (17, 17, 17, 255)
MARCO = (43, 43, 51, 255)
MARCO_LUZ = (69, 69, 79, 255)
MARCADOR = (11, 26, 16, 255)
PASTO_A = (46, 139, 58, 255)
PASTO_B = (51, 160, 67, 255)
LINEA = (232, 245, 232, 255)
ROJO = (217, 83, 79, 255)
AZUL = (63, 169, 245, 255)
BALON = (255, 255, 255, 255)
BRILLO = (255, 255, 255, 60)

LETRAS = {
    "L": ["X..", "X..", "X..", "X..", "XXX"],
    "A": ["XXX", "X.X", "XXX", "X.X", "X.X"],
    "5": ["XXX", "X..", "XX.", "..X", "XX."],
    "0": ["XXX", "X.X", "X.X", "X.X", "XXX"],
    "1": [".X.", "XX.", ".X.", ".X.", "XXX"],
    "G": ["XXX", "X..", "X.X", "X.X", "XXX"],
    "O": ["XXX", "X.X", "X.X", "X.X", "XXX"],
    "!": ["X", "X", "X", ".", "X"],
    " ": ["..", "..", "..", "..", ".."],
}

def texto(img, x, y, cadena, color, escala=1):
    for letra in cadena:
        patron = LETRAS[letra]
        for fy, fila in enumerate(patron):
            for fx, c in enumerate(fila):
                if c == "X":
                    for sy in range(escala):
                        for sx in range(escala):
                            img.putpixel((x + fx * escala + sx, y + fy * escala + sy), color)
        x += (len(patron[0]) + 1) * escala
    return x

def ancho_texto(cadena, escala=1):
    return sum((len(LETRAS[l][0]) + 1) * escala for l in cadena) - escala

def marco_tv(ancho=64, alto=20):
    img = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
    for x in range(ancho):
        for y in range(alto):
            borde = x in (0, ancho - 1) or y in (0, alto - 1)
            img.putpixel((x, y), NEGRO if borde else MARCO)
    for x in range(1, ancho - 1):
        img.putpixel((x, 1), MARCO_LUZ)
    return img

def cancha(img, jugadores):
    ancho, alto = img.size
    x0, x1, y0, y1 = 2, ancho - 3, 8, alto - 3
    for x in range(2, ancho - 2):
        for y in range(2, 8):
            img.putpixel((x, y), MARCADOR)
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            img.putpixel((x, y), PASTO_A if (x // 4) % 2 == 0 else PASTO_B)
    for x in range(x0 + 1, x1):
        img.putpixel((x, y0), LINEA)
        img.putpixel((x, y1), LINEA)
    for y in range(y0, y1 + 1):
        img.putpixel((x0 + 1, y), LINEA)
        img.putpixel((x1 - 1, y), LINEA)
    medio = (x0 + x1) // 2
    for y in range(y0, y1 + 1):
        img.putpixel((medio, y), LINEA)
    cy = (y0 + y1) // 2
    for dx, dy in [(-2, -1), (-2, 0), (-2, 1), (2, -1), (2, 0), (2, 1), (-1, -2), (0, -2), (1, -2), (-1, 2), (0, 2), (1, 2)]:
        img.putpixel((medio + dx, cy + dy), LINEA)
    for y in range(cy - 2, cy + 3):
        img.putpixel((x0 + 3, y), LINEA)
        img.putpixel((x1 - 3, y), LINEA)
    for (x, y, color) in jugadores:
        img.putpixel((x, y), color)
        img.putpixel((x, y - 1), color)
    return img

def tv_gol():
    img = marco_tv()
    ancho, alto = img.size
    colores = [(255, 209, 102, 255), (242, 139, 56, 255)]
    for x in range(2, ancho - 2):
        for y in range(2, alto - 2):
            img.putpixel((x, y), colores[((x + y) // 3) % 2])
    frase = "GOL!"
    w = ancho_texto(frase, 2)
    texto(img, (ancho - w) // 2, 5, frase, (255, 255, 255, 255), 2)
    for i, (x, y) in enumerate([(5, 4), (10, 12), (54, 5), (58, 13), (16, 5), (48, 12), (8, 8), (57, 9)]):
        img.putpixel((x, y), [ROJO, AZUL, (95, 211, 141, 255), (255, 255, 255, 255)][i % 4])
    return img

def neon(encendido):
    ancho, alto = 64, 18
    img = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
    tubo = (255, 95, 162, 255) if encendido else (122, 47, 85, 255)
    luz = (255, 208, 230, 255) if encendido else (138, 90, 112, 255)
    halo = (255, 95, 162, 90) if encendido else (0, 0, 0, 0)
    for x in range(ancho):
        for y in range(alto):
            borde = x in (0, ancho - 1) or y in (0, alto - 1)
            img.putpixel((x, y), NEGRO if borde else (27, 31, 42, 255))
    for x in range(3, ancho - 3):
        img.putpixel((x, 2), tubo)
        img.putpixel((x, alto - 3), tubo)
    for y in range(3, alto - 3):
        img.putpixel((2, y), tubo)
        img.putpixel((ancho - 3, y), tubo)
    frase = "LA 501"
    w = ancho_texto(frase, 2)
    x0, y0 = (ancho - w) // 2, 4
    capa = Image.new("RGBA", (ancho, alto), (0, 0, 0, 0))
    texto(capa, x0, y0, frase, luz, 2)
    for x in range(ancho):
        for y in range(alto):
            if capa.getpixel((x, y))[3] > 0:
                for dx, dy in [(-1, 0), (1, 0)]:
                    nx, ny = x + dx, y + dy
                    if 2 < nx < ancho - 3 and 2 < ny < alto - 3 and capa.getpixel((nx, ny))[3] == 0 and halo[3] > 0:
                        img.putpixel((nx, ny), halo)
    img.alpha_composite(capa)
    return img

def main():
    SALIDA.mkdir(parents=True, exist_ok=True)
    cuadros = [
        [(18, 12, ROJO), (24, 15, ROJO), (40, 11, ROJO), (35, 14, AZUL), (46, 13, AZUL), (28, 11, AZUL), (31, 13, BALON)],
        [(20, 13, ROJO), (26, 14, ROJO), (38, 12, ROJO), (33, 13, AZUL), (44, 14, AZUL), (29, 12, AZUL), (34, 12, BALON)],
    ]
    for i, jugadores in enumerate(cuadros, start=1):
        cancha(marco_tv(), jugadores).save(SALIDA / f"tv_{i}.png")
    tv_gol().save(SALIDA / "tv_gol.png")
    neon(True).save(SALIDA / "neon_on.png")
    neon(False).save(SALIDA / "neon_off.png")
    print("Sprites generados en", SALIDA)

if __name__ == "__main__":
    main()
