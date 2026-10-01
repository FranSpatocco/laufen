# Laufen 🏃

App de tracking de running multiplataforma (Web, Android, iOS) hecha 100% en Flutter, inspirada en Strava. Pieza de portfolio para demostrar Flutter de punta a punta: UI, animaciones, estado, GPS, mapas y un backend real en Firebase.

**Demo en vivo:** https://laufen-app.web.app — se prueba en un clic, sin registrarse.

## Funcionalidad

- **Modo invitado**: "Empezar" entra directo a la app, sin login. Un invitado ve una carrera de ejemplo (mapa + parciales) para recorrer la app aunque esté en una PC sin GPS. La cuenta recién se pide al guardar una carrera: al finalizar aparece "¿Querés guardar esta carrera?" → login → se guarda sola al volver.
- **Auth**: email y contraseña, y Google (nativo en Android/iOS, popup en web).
- **Carrera en vivo**: mapa (`flutter_map` + OpenStreetMap) con la ruta dibujándose en tiempo real; cronómetro, distancia y pace calculados del GPS (`geolocator`), con filtros de precisión y de velocidad para descartar saltos de GPS. Sigue trackeando con la pantalla apagada (foreground service en Android, background location en iOS).
- **Tipos de entrenamiento**: carrera libre, trote, caminata e **intervalos** — se eligen dos tiempos (correr / caminar) y durante la carrera un cartel "CORRÉ / CAMINÁ" con cuenta regresiva avisa cada cambio con vibración y sonido.
- **Parciales por km**: el momento exacto en que se cruza cada km se interpola entre dos lecturas de GPS; tabla con el ritmo de cada km y el más rápido resaltado.
- **Historial**: paginado de a 8, con detalle de cada carrera (ruta + stats + parciales). Borrar carreras desde un menú, deslizando o desde el detalle, siempre con confirmación y "Deshacer".
- **Dashboard**: total de km, cantidad de carreras, mejor pace y carrera más larga, con contadores animados.
- **Perfil**: nombre, edad, peso, altura, nivel, objetivo y meta semanal de km, con barra de progreso de la semana.
- **Landing con CMS**: la página pública lee su copy desde Firestore, con fallback a un texto por default.

## Diseño y animaciones

- Animaciones de entrada tipo *timeline* (estilo GSAP) hechas con las APIs nativas de Flutter — un `AnimationController` con `Interval`s escalonados, sin paquetes de animación: el logo se escribe y el punto cae rebotando, el título entra palabra por palabra, y un mapa ilustrado dibuja una ruta en loop (`PathMetric.extractPath`) con el corredor recorriéndola.
- **Responsive real**, no una app de celular estirada: en PC la landing va en dos columnas, la navegación pasa a una barra lateral y el detalle de carrera muestra el mapa con un panel al costado. En celular la landing entra entera sin scroll.
- Identidad propia: paleta "tierra / asfalto", wordmark "laufen" dibujado en código y tipografía Outfit.

## Stack

- **Flutter** (Dart) — un solo codebase para Web, Android e iOS.
- **Firebase**: Firestore (datos), Authentication (email/password + Google), Hosting (web).
- **flutter_map** + OpenStreetMap para el mapa (sin API key de Google Maps).
- **geolocator** para el GPS, **google_sign_in** para el login nativo.

Sin paquetes de estado ni de animación: el proyecto se mantiene con pocas dependencias a propósito.

## Correr el proyecto

```bash
flutter pub get
flutter run
```

Este repo trae la configuración de Firebase del proyecto de demo. Para usar uno propio: `flutterfire configure`.

### Con emuladores (sin tocar producción)

```bash
firebase emulators:start --only auth,firestore
flutter run --dart-define=USE_EMULATORS=true
```

### Tests

```bash
flutter test
```

Tests unitarios de la lógica pura (parciales por km, fases de intervalos, modelos) y tests de widgets (la landing entra sin scroll en un celular, pantallas nuevas sin overflow a 360 px, etc.).

## Estructura

```
lib/
  screens/    # una pantalla por archivo (landing, login, shell + 4 tabs, carrera en vivo, intervalos, detalle, perfil)
  widgets/    # componentes reusables (wordmark, mapa animado, stats, parciales, animaciones de entrada)
  services/   # toda la lógica de Firebase vive acá — los widgets nunca llaman a Firestore directo
  models/     # RunModel, KmSplit, IntervalPlan, UserProfile, TrainingType...
  utils/      # tema, constantes, formatters, transiciones de página
```

Más contexto de arquitectura y decisiones de diseño en [CLAUDE.md](CLAUDE.md).
