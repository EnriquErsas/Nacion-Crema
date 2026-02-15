# Nación U Crema

Sitio estático (HTML + React vía CDN) listo para hosting en cualquier plataforma de sitios estáticos.

## Supabase

- Auth: el registro/inicio/cierre de sesión se hace con Supabase Auth.
- Productos: la web intenta leer desde la tabla `products`. Si no existe o está vacía, muestra productos de prueba.
- Seguridad: `.env` y `.env.*` están ignorados para Git y Vercel.

### Tabla `products` (recomendado)

Columnas sugeridas para que el mapeo sea directo:

- `id` (int/bigint) o `uuid`
- `nombre` (text)
- `precio` (numeric)
- `categoria` (text)
- `imagen_url` (text) o `imagen` (text)
- `rating` (numeric) y `reviews` (int) (opcionales)
- `descripcion` (text) (opcional)

## Vista local

- Abrir `index.html` en el navegador, o
- Servir la carpeta con un servidor estático (recomendado) para evitar problemas de rutas.

## Despliegue (recomendado)

### Opción A: Netlify (más simple)

1. Entra a Netlify y elige “Add new site”.
2. Arrastra y suelta esta carpeta del proyecto (la que contiene `index.html`).
3. Listo: la URL publicada servirá `index.html` y `assets/`.

### Opción B: Vercel

1. Importa el repositorio/proyecto en Vercel.
2. Framework: “Other”.
3. Build Command: vacío.
4. Output Directory: `.` (la raíz).

### Opción C: GitHub Pages

1. Sube estos archivos a un repositorio.
2. Settings → Pages → Deploy from branch.
3. Selecciona la rama y la carpeta raíz (`/`).
4. Guarda y espera a que quede publicada.
