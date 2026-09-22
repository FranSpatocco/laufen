# CLAUDE.md — Laufen

## Qué es esto

Laufen ("running" en alemán) — app de tracking de running multiplataforma (iOS, Android, Web) hecha 100% en Flutter. Landing pública + área de usuario logueada. Referencia de producto: Strava, principalmente (mapa + datos de la actividad como protagonistas, sin el ruido social/e-commerce de Nike Run Club o Adidas Running). El objetivo NO es un producto comercial: es una pieza de portfolio para demostrar dominio de Flutter de punta a punta y conseguir un puesto de trabajo. Priorizar que se vea completo y prolijo por sobre agregar funcionalidades de más.

## Stack y por qué

* Flutter (Dart) puro — mobile + web en un solo codebase. Nada de Capacitor, nada de WebView.
* Firebase: Firestore (datos) + Auth (login/registro de usuarios, email/password y Google).
* Deploy: Web en Firebase Hosting (ya en producción: https://laufen-app.web.app). TestFlight e iOS quedan pendientes — requieren Mac/Xcode, no disponibles en esta máquina.

## Estructura de carpetas

```
lib/
  main.dart
  screens/       # una carpeta o archivo por pantalla (landing, login, home, etc.)
  widgets/       # componentes reusables
  services/      # acceso a Firebase: auth_service.dart, firestore_service.dart, content_service.dart (CMS), location_service.dart
  models/        # clases de datos (run_model.dart, content_model.dart)
  utils/         # constantes, theme, formatters
```

Los widgets son "tontos" (solo UI); la lógica de Firebase vive en `services/`. Ningún widget llama a Firestore directo.

## CMS (Firestore como CMS liviano)

Colección `content/landing` en Firestore (ya cargada en producción). La landing lee sus textos desde ahí a través de `services/content_service.dart`, con fallback a los textos estáticos de `utils/constants.dart` si el documento no existe o todavía no cargó.

```
content/landing (documento)
  - hero_title: string
  - hero_subtitle: string
  - sections: array de { title, body, image_url }   # opcional, todavía sin usar

```

Si se agrega un panel de admin más adelante, escribir sobre esta misma colección — no crear una segunda fuente de verdad.

## Funcionalidad core: tracking de carreras (running)

1. **Carrera en vivo** (`screens/live_run_screen.dart`): `geolocator` para ubicación en tiempo real, mapa con `flutter_map` (evita depender de una API key de Google Maps). Cronómetro, distancia acumulada y pace calculados en tiempo real a partir de los puntos GPS.
2. **Guardar carrera**: al finalizar escribe en Firestore bajo `users/{uid}/runs/{runId}` con `date`, `distance_km`, `duration_seconds`, `avg_pace`, `route` (array de `{lat, lng}`).
3. **Historial** (`screens/history_screen.dart`): lista de carreras del usuario ordenada por fecha. Tap en una → `screens/run_detail_screen.dart` con el mapa de esa ruta puntual + sus stats.
4. **Dashboard** (dentro de `screens/home_screen.dart`): total de km corridos, cantidad de carreras, mejor pace histórico — agregado client-side sobre la colección `runs` existente.

No hay splits por km, logros/badges, segmentos, ni feed social — eso es infraestructura de red social que no aporta a demostrar skills de Flutter y vuela el scope de un portfolio piece.

## Auth

Firebase Auth con email/password y Google. En **web** usa `signInWithProvider(GoogleAuthProvider())` directo de `firebase_auth`. En **Android/iOS** eso no funciona (Chrome storage-partitioning rompe el flujo de Custom Tabs que usa por debajo — error "missing initial state", encontrado probando en un dispositivo real), así que ahí se usa el paquete oficial `google_sign_in` (login nativo, sin navegador) y el ID token resultante se pasa a `FirebaseAuth.signInWithCredential`. El área de usuario detrás del login vive en `screens/`, protegida por `screens/auth_gate.dart`, que rutea según el stream `FirebaseAuth.instance.authStateChanges()`.

Requiere tener registrada la huella SHA-1 del keystore de debug en la consola de Firebase (Configuración del proyecto → Tus apps → Android) — ya está hecho para este proyecto.

## i18n

Pendiente de decisión. Si se agrega: usar el paquete `intl` con archivos `.arb` por idioma (`app_es.arb`, `app_en.arb`), no strings sueltos. Todo el texto actual vive centralizado en `utils/constants.dart` para facilitar la migración.

## Diseño

Inspirado en Strava.

* Fondo claro, no dark mode como default.
* Color de acento: naranja estilo Strava (`#FC4C02`) — `seedColor` de `ColorScheme.fromSeed` en Material 3 (`utils/theme.dart`).
* Números grandes (distancia, pace, tiempo) en tipografía bold (`widgets/stat_display.dart`), protagonistas de la carrera en vivo, el detalle y el dashboard.
* El mapa es el elemento visual principal de cada carrera.
* Todas las pantallas con overlays sobre un mapa a pantalla completa (carrera en vivo, detalle) respetan el área segura del sistema (`SafeArea` / `MediaQuery.padding`) — encontramos y corregimos varios casos donde la barra de navegación de Android tapaba contenido, probando en un dispositivo real.

## Estado actual / qué falta

* [x] Crear proyecto en Firebase (Firestore + Auth)
* [x] Scaffold inicial del proyecto Flutter
* [x] Configurar permisos de ubicación (Android `ACCESS_FINE_LOCATION`, iOS `NSLocationWhenInUseUsageDescription`)
* [x] Pantalla de carrera en vivo (mapa + tracking + cronómetro)
* [x] Guardar carrera al finalizar (Firestore)
* [x] Historial de carreras + detalle
* [x] Dashboard de stats
* [x] Landing leyendo de Firestore
* [x] Auth funcionando (email/password + Google)
* [x] Deploy de prueba a Web (https://laufen-app.web.app)
* [ ] Probar tracking GPS con movimiento real (validado el flujo y el manejo de permisos en un Android real; falta una carrera real al aire libre)
* [x] Huella SHA-1 + paquete `google_sign_in` para que el login con Google funcione en Android nativo
* [ ] Deploy a TestFlight (requiere Mac/Xcode — no disponible en esta máquina)
* [x] (Could) Récords personales: mayor distancia histórica junto al mejor pace ya existente en el dashboard

## Instrucciones para Claude Code

* Si ya existe código en la carpeta, leer los archivos antes de tocar nada.
* Priorizar que el proyecto compile y corra en cada paso, no dejar features a medio hacer entre sesiones.
* No agregar dependencias nuevas (paquetes pub.dev) sin que quede claro por qué — este proyecto tiene que quedar limpio para mostrar en una entrevista.
* Explicar brevemente las decisiones de arquitectura no obvias, en comentarios cortos en el código, pensando en que alguien de RRHH técnico lo puede llegar a revisar.
