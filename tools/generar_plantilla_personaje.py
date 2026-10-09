import os
from PIL import Image, ImageDraw, ImageFont

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "Assets", "sprites", "personajes", "plantillas")
TILES = os.path.join(RAIZ, "Assets", "sprites", "rpg_urban", "Tiles", "tile_%04d.png")
CUADRO = 32
COLUMNAS = ["De pie", "Paso A", "De pie", "Paso B"]
FILAS = ["Abajo (de frente)", "Arriba (de espaldas)", "Lado (mira a la DERECHA)"]

def plantilla():
    img = Image.new("RGBA", (CUADRO * 4, CUADRO * 3), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for f in range(3):
        for c in range(4):
            x, y = c * CUADRO, f * CUADRO
            fondo = (255, 0, 255, 40) if (f + c) % 2 == 0 else (0, 200, 255, 40)
            d.rectangle([x, y, x + CUADRO - 1, y + CUADRO - 1], fill=fondo)
            d.line([x + 8, y + CUADRO - 1, x + CUADRO - 9, y + CUADRO - 1], fill=(255, 80, 80, 160))
    return img

def guia(base):
    z = 6
    margen_x, margen_y = 230, 40
    img = Image.new("RGBA", (margen_x + base.width * z + 20, margen_y + base.height * z + 60), (24, 32, 43, 255))
    img.paste(base.resize((base.width * z, base.height * z), Image.NEAREST), (margen_x, margen_y))
    d = ImageDraw.Draw(img)
    try:
        f = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        f = ImageFont.load_default()
    for c, nombre in enumerate(COLUMNAS):
        d.text((margen_x + c * CUADRO * z + 8, 12), "Col %d: %s" % (c + 1, nombre), fill="white", font=f)
    for r, nombre in enumerate(FILAS):
        d.text((10, margen_y + r * CUADRO * z + CUADRO * z // 2 - 10), nombre, fill="white", font=f)
    for c in range(5):
        x = margen_x + c * CUADRO * z
        d.line([x, margen_y, x, margen_y + base.height * z], fill=(255, 255, 255, 90))
    for r in range(4):
        y = margen_y + r * CUADRO * z
        d.line([margen_x, y, margen_x + base.width * z, y], fill=(255, 255, 255, 90))
    d.text((10, img.height - 34), "Cuadros de 32x32 px, fondo transparente, pies centrados en la linea roja. El lado izquierdo lo voltea el juego.",
           fill=(255, 200, 120), font=f)
    return img

def ejemplo_dani():
    base = 429
    img = Image.new("RGBA", (CUADRO * 4, CUADRO * 3), (0, 0, 0, 0))
    for fila in range(3):
        for c, paso in enumerate([0, 1, 0, 2]):
            tile = Image.open(TILES % (base + fila + paso * 27)).convert("RGBA")
            tile = tile.resize((CUADRO, CUADRO), Image.NEAREST)
            img.paste(tile, (c * CUADRO, fila * CUADRO))
    return img

if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    p = plantilla()
    p.save(os.path.join(SALIDA, "plantilla_32px.png"))
    ej = ejemplo_dani()
    ej.save(os.path.join(SALIDA, "ejemplo_dani.png"))
    fondo = Image.alpha_composite(p, ej)
    guia(fondo).save(os.path.join(SALIDA, "guia_plantilla.png"))
    print("listo:", SALIDA)
