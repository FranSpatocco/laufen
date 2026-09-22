# Laufen 🏃

App de tracking de running multiplataforma (Web, Android, iOS) hecha 100% en Flutter, inspirada en Strava. Pieza de portfolio para demostrar Flutter de punta a punta: UI, estado, GPS, mapas y un backend real en Firebase.

**Demo en vivo:** https://laufen-app.web.app

## Funcionalidad

- **Auth**: registro/login con email y contraseña, y con Google (nativo en Android/iOS, popup en web).
- **Navegación de 4 secciones** (Inicio, Entrenar, Historial, Perfil), con transiciones y animaciones propias hechas con las APIs nativas de Flutter.
- **Tipos de entrenamiento**: carrera libre, trote o caminata.
- **Carrera en vivo**: mapa (`flutter_map` + OpenStreetMap) con la ruta dibujándose en tiempo real, cronómetro, distancia y pace calculados a partir del GPS (`geolocator`), con filtros de precisión y velocidad para descartar saltos de GPS.
- **Historial**: lista de carreras pasadas, con detalle de cada una (ruta en el mapa + stats).
- **Dashboard**: total de km, cantidad de carreras, mejor pace y carrera más larga — agregado client-side sobre Firestore, con tarjetas animadas.
- **Landing con CMS**: la página pública lee su copy desde Firestore, con fallback a un texto por default.

## Stack

- **Flutter** (Dart) — un solo codebase para Web, Android e iOS.
- **Firebase**: Firestore (datos), Authentication (email/password + Google), Hosting (deploy web).
- **flutter_map** + OpenStreetMap para el mapa (sin depender de una API key de Google Maps).
- **geolocator** para el tracking GPS.

## Correr el proyecto

```bash
flutter pub get
flutter run
```

Necesita un proyecto de Firebase propio configurado con `flutterfire configure` (no se versiona `google-services.json` con credenciales de producción de otro usuario — este repo trae el del proyecto de demo).

## Estructura

```
lib/
  screens/    # una pantalla por archivo (landing, login, main_shell + sus 4 tabs, carrera en vivo, detalle)
  widgets/    # componentes reusables (stat_display, animated_stat_tile)
  services/   # toda la lógica de Firebase vive acá — los widgets nunca llaman a Firestore directo
  models/     # RunModel, TrainingType, LandingContent
  utils/      # tema, constantes, formatters, transiciones de página
```

Más contexto de arquitectura y decisiones de diseño en [CLAUDE.md](CLAUDE.md).
