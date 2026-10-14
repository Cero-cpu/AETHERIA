# ☁️ Sistema de Nubes en Movimiento (AETHERIA)

Sistema modular y ligero de nubes 2D para colocar en cualquier escenario o nivel con cero configuración obligatoria.

---

## 🚀 ¿Cómo usarlo en 3 pasos?

1. **Arrastra la escena:**
   Arrastra `nube.tscn` (o crea un nodo `Nube`) directamente a tu nivel en el árbol de nodos o en el viewport 2D.
2. **Asigna o cambia el sprite:**
   En el **Inspector**, en la propiedad `Texture`, arrastra la imagen/sprite de la nube que quieras (tienes 3 listas en `sprites/` o puedes usar las tuyas).
3. **Colócala y duplícala:**
   Muévela con el ratón a donde quieras que empiece. Puedes duplicarla con `Ctrl + D` tantas veces como quieras.

---

## ⚙️ Opciones en el Inspector (Opcionales)

Seleccionando cualquier nube, verás agrupadas estas propiedades:

### 💨 Movimiento
- **`velocidad`** *(defecto: 20.0)*: Píxeles por segundo (movimiento lento y atmosférico).
- **`variacion_velocidad`** *(defecto: 6.0)*: Añade un pequeño factor aleatorio único a cada nube para que no se muevan en bloque robótico.
- **`direccion`** *(defecto: Vector2(1, 0))*: Hacia dónde sopla el viento (derecha, izquierda, diagonal, etc.).

### 🌊 Flotación Suave (Vaivén Vertical)
- **`flotacion_activa`** *(defecto: true)*: Ondulación senoidal suave para que parezcan flotar con vida propia.
- **`amplitud_flotacion`** *(defecto: 4.0)*: Píxeles que sube y baja.
- **`velocidad_flotacion`** *(defecto: 1.0)*: Ritmo de la ondulación.

### 🔄 Ciclo y Reaparición
- **`modo_ciclo`**:
  - `POR_DISTANCIA` *(Recomendado)*: La nube se desplaza `distancia_maxima` desde su punto de origen y vuelve a aparecer en el extremo opuesto en un ciclo continuo alrededor de su posición.
  - `POR_PANTALLA_O_CAMARA`: Reaparece en el lado contrario cuando sale del campo de visión de la cámara activa.
  - `SIN_CICLO`: Sigue avanzando continuamente.
- **`distancia_maxima`** *(defecto: 1400.0 px)*: Rango de viaje antes del ciclo.
- **`variacion_altura_al_reaparecer`** *(defecto: 25.0 px)*: Desfase aleatorio en Y para que nunca reaparezca en la misma línea fija.

### 🎨 Detalles Visuales
- **`opacidad_aleatoria`**: Da diferentes niveles de transparencia para simular nubes lejanas y cercanas.
- **`escala_aleatoria`**: Varia ligeramente el tamaño al iniciar.
