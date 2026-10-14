import os
from PIL import Image, ImageDraw, ImageFont

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "Assets", "sprites", "comida", "plantillas")
ACTUAL = os.path.join(RAIZ, "Assets", "sprites", "comida", "%s.png")
CUADRO = 32
MARGEN = 2
COLUMNAS = 5

ICONOS = [
    ("insumo_carne", "Carne", "Mercado"),
    ("insumo_pollo", "Pollo", "Mercado"),
    ("insumo_papas", "Papas (bolsa)", "Mercado"),
    ("insumo_verdura", "Verdura", "Mercado"),
    ("insumo_pan", "Pan", "Mercado"),
    ("insumo_cerveza", "Cerveza (lata)", "Cervecería"),
    ("insumo_refresco", "Refresco (lata)", "Cervecería"),
    ("insumo_hielo", "Hielo", "Cervecería"),
    ("platillo_refresco", "Refresco servido", "Barra"),
    ("platillo_cerveza", "Cerveza servida", "Barra"),
    ("platillo_hamburguesa", "Hamburguesa 501", "Cocina"),
    ("platillo_alitas", "Alitas", "Cocina"),
    ("platillo_papas", "Papas fritas", "Cocina"),
    ("platillo_combo", "Combo VIP", "Cocina"),
    ("plato_sucio", "Plato sucio", "Mesas"),
]

COLOR_LUGAR = {
    "Mercado": (155, 208, 142),
    "Cervecería": (242, 165, 65),
    "Barra": (79, 176, 198),
    "Cocina": (232, 93, 74),
    "Mesas": (191, 211, 220),
}


def fuente(tam):
    try:
        return ImageFont.truetype("arial.ttf", tam)
    except OSError:
        return ImageFont.load_default()


def posicion(indice):
    return (indice % COLUMNAS) * CUADRO, (indice // COLUMNAS) * CUADRO


def tamano_hoja():
    filas = (len(ICONOS) + COLUMNAS - 1) // COLUMNAS
    return COLUMNAS * CUADRO, filas * CUADRO


def cuadro_guia(d, x, y, tinte):
    d.rectangle([x, y, x + CUADRO - 1, y + CUADRO - 1], fill=tinte)
    d.rectangle([x + MARGEN, y + MARGEN, x + CUADRO - 1 - MARGEN, y + CUADRO - 1 - MARGEN], outline=(255, 255, 255, 70))
    d.line([x + 6, y + CUADRO - 1 - MARGEN, x + CUADRO - 7, y + CUADRO - 1 - MARGEN], fill=(255, 80, 80, 150))


def plantilla_icono():
    img = Image.new("RGBA", (CUADRO, CUADRO), (0, 0, 0, 0))
    cuadro_guia(ImageDraw.Draw(img), 0, 0, (0, 200, 255, 40))
    return img


def plantilla_hoja():
    img = Image.new("RGBA", tamano_hoja(), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i in range(len(ICONOS)):
        x, y = posicion(i)
        cuadro_guia(d, x, y, (255, 0, 255, 40) if (x // CUADRO + y // CUADRO) % 2 == 0 else (0, 200, 255, 40))
    return img


def icono_actual(clave, tam):
    ruta = ACTUAL % clave
    if not os.path.exists(ruta):
        return None
    img = Image.open(ruta).convert("RGBA")
    caja = img.getbbox()
    if caja:
        img = img.crop(caja)
    escala = tam / max(img.width, img.height)
    return img.resize((max(1, round(img.width * escala)), max(1, round(img.height * escala))), Image.NEAREST)


def referencia_actual():
    img = Image.new("RGBA", tamano_hoja(), (0, 0, 0, 0))
    for i, (clave, _, _) in enumerate(ICONOS):
        icono = icono_actual(clave, CUADRO)
        if icono is None:
            continue
        x, y = posicion(i)
        img.alpha_composite(icono, (x, y))
    return img


def guia():
    ancho_tarjeta, alto_tarjeta = 250, 270
    filas = (len(ICONOS) + COLUMNAS - 1) // COLUMNAS
    img = Image.new("RGBA", (40 + COLUMNAS * ancho_tarjeta, 120 + filas * alto_tarjeta + 70), (20, 32, 43, 255))
    d = ImageDraw.Draw(img)
    d.text((24, 20), "ORDEN 501 · Íconos de comida propios", fill=(244, 241, 234), font=fuente(30))
    d.text((24, 62), "Dibuja cada ícono en un cuadro de 32 x 32 px con fondo transparente. Abajo: el ícono actual, su nombre y el archivo a guardar.",
           fill=(191, 211, 220), font=fuente(16))
    for i, (clave, nombre, lugar) in enumerate(ICONOS):
        x = 20 + (i % COLUMNAS) * ancho_tarjeta
        y = 110 + (i // COLUMNAS) * alto_tarjeta
        color = COLOR_LUGAR[lugar]
        d.rounded_rectangle([x, y, x + ancho_tarjeta - 16, y + alto_tarjeta - 16], radius=12, fill=(14, 23, 32), outline=color, width=3)
        d.text((x + 14, y + 10), "%d · %s" % (i + 1, lugar.upper()), fill=color, font=fuente(15))
        icono = icono_actual(clave, 128)
        if icono:
            img.alpha_composite(icono, (x + (ancho_tarjeta - 16 - icono.width) // 2, y + 36 + (136 - icono.height) // 2))
        d.text((x + 14, y + 184), nombre, fill=(244, 241, 234), font=fuente(19))
        d.text((x + 14, y + 214), clave + ".png", fill=(242, 165, 65), font=fuente(15))
    d.text((24, img.height - 52), "Guarda tus íconos en Assets/sprites/comida/ con el nombre indicado (o dibuja la hoja completa y córtala con tools/cortar_iconos_comida.py).",
           fill=(242, 165, 65), font=fuente(16))
    return img


if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    plantilla_icono().save(os.path.join(SALIDA, "plantilla_icono_32px.png"))
    plantilla_hoja().save(os.path.join(SALIDA, "plantilla_hoja_32px.png"))
    referencia_actual().save(os.path.join(SALIDA, "referencia_actual.png"))
    guia().save(os.path.join(SALIDA, "guia_iconos.png"))
    print("Plantillas en", SALIDA)
