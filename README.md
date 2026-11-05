> **Después de descomprimir o de reemplazar `lib/`, ejecuta siempre `bash setup.sh`.** `app_database.g.dart` es código generado (no viene en el zip) y se borra al reemplazar la carpeta.

# GymAssist (Flutter) — Fase de vistas

App **móvil (mobile-first)**: NavigationBar inferior, listas de tarjetas, formularios en hojas inferiores. Al correr en macOS/Chrome se muestra dentro de un marco de teléfono (`lib/app.dart`). Solo UI. Todos los datos salen de `lib/core/mock/mock_data.dart` y cada punto donde irá lógica real está marcado con `TODO(...)`.

## Arrancar (la primera vez hay que generar el código de Drift)
```bash
cd gymassist_flutter
flutter create . --platforms=android,ios,macos,web --project-name gymassist   # genera carpetas de plataforma
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # genera app_database.g.dart
flutter test                                                  # reglas de negocio con BD en memoria
flutter run --dart-define=SEED_DEMO=true                      # opcional: datos de demostración
```
Usuarios de demo: `admin` / `admin123`; clientes `laura`, `carlos`, `marta` / `cliente123`.

> macOS: `flutter_secure_storage` necesita el entitlement de Keychain; si falla en macOS prueba en el simulador de iOS/Android.
En modo debug, la pantalla de login tiene atajos "Entrar como admin / cliente" para revisar cada vista.

## Arquitectura (por capas, feature-first)
`features/<feature>/{presentation, domain, data}` + `core/` (tema, router, widgets). En esta fase solo existen `presentation/` y algo de `domain/`
(`ClientStatus`, `ImcCalculator`). `data/` (Drift, repositorios) llega en las fases 1-4 del plan.

## Mapa de vistas (Spring Boot → Flutter)
| Thymeleaf | Ruta Flutter | Archivo |
|---|---|---|
| index | `/` | public/landing_page |
| login (login + registro) | `/login` | auth/auth_page |
| gymRegister | `/gimnasio/registro` | gym_setup/gym_register_page |
| AdminHome | `/admin` | admin_home/admin_home_page |
| AdminRegister | `/admin/clientes` | clients/clients_page |
| planesGimnasio (+editarPlan) | `/admin/membresias` | plans/plans_page |
| rutinasGimnasio / editarRutina | `/admin/rutinas`, `/admin/rutinas/:id/editar` | routines/ |
| Dashboard (Power BI) | `/admin/dashboard` | dashboard/dashboard_page (fl_chart) |
| Predicciones | `/admin/predicciones` | predictions/predictions_page |
| modelo | `/admin/modelo` | optimization/optimization_page |
| CuentaAdmin | `/admin/cuenta` | account/admin_account_page |
| ClienteHome | `/cliente` | client_home/client_home_page |
| Clienteimc | `/cliente/imc` | measurements/imc_page |
| ClienteRutinas + rutinasGrupo | `/cliente/rutinas`, `/cliente/rutinas/grupo/:grupo` | routines/client_routines_page |
| ClienteAsistencia | `/cliente/asistencia` | attendance/attendance_page |
| ClienteCuenta | `/cliente/cuenta` | account/client_account_page |
| ClientePago | `/cliente/pago` | payments/payment_page |
| chatbot (widget) | botón flotante del cliente | chatbot/chatbot_panel |
| Error / error403 | errorBuilder, `/acceso-denegado` | core/widgets/error_pages |

No migradas a propósito: `checkout`, `payment-success`, `payment-failure`, `error-payment`, `pago` (dependen de MercadoPago, que requiere internet).

## Probar en móvil
```bash
open -a Simulator && flutter run -d ios   # simulador iOS
flutter run -d <emulador-android>        # emulador Android
```

## Capa de datos
Ver `docs/modelo_de_datos.md` (ER, mapeo Mongo/Postgres → SQLite y dónde quedó cada regla de negocio).

## Correr en Chrome (web)
Drift usa SQLite compilado a WebAssembly en el navegador. Hacen falta dos archivos en `web/` cuyas versiones coincidan con las de `pubspec.lock`
(drift **2.31.0** y sqlite3 **2.9.4** al escribir esto):
```bash
cd gymassist_flutter
flutter create . --platforms=web,macos,android,ios --project-name gymassist   # si aún no existe web/
curl -L -o web/sqlite3.wasm    https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm
curl -L -o web/drift_worker.js https://github.com/simolus3/drift/releases/download/drift-2.31.0/drift_worker.js
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --dart-define=SEED_DEMO=true
```
Si algún día `flutter pub upgrade` cambia las versiones de `drift` o `sqlite3`, vuelve a descargar los dos archivos con el número de versión nuevo.

Notas web: los datos viven en el navegador (IndexedDB/OPFS) y se borran al limpiar los datos del sitio; el hash bcrypt corre en el hilo principal
(en móvil/desktop corre en un isolate), por eso el primer login puede tardar un instante; `LocalFileStorage` (fotos de rutinas) aún no funciona en web.
# gymassist_flutter


## Predicciones con la red neuronal (FastAPI + TensorFlow)
La pantalla **Predicciones** (`/admin/predicciones`) ya no usa datos de ejemplo: lee los clientes de la base local
(plan, membresía, asistencias, medidas), los envía a la API de Python y muestra lo que devuelve la red LSTM:
probabilidad de abandono, nivel de riesgo, los 3 factores que más pesan, la asistencia semanal y la recomendación.

```
Flutter (Drift) --JSON--> FastAPI  POST /predecir/lote --> red LSTM + Densa (TensorFlow)
                <--JSON--  probabilidadAbandono, riesgo, factores, recomendacion
```

1. Encender la API (repo GymAssist2.0, carpeta `prediccion-ml`):
   ```
   cd prediccion-ml
   .venv\Scripts\activate
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```
2. Correr la app:
   ```
   flutter pub get
   flutter run -d chrome --dart-define=SEED_DEMO=true
   ```
   `SEED_DEMO` agrega 7 clientes con 12 semanas de historial (valentina, juanh, daniela, miguel, camila, felipe, isabela)
   para que se vean casos de riesgo bajo, medio, alto y crítico.

Dirección de la API: `lib/core/config/api_config.dart`. Por defecto `http://localhost:8000` (Chrome/Windows) y
`http://10.0.2.2:8000` (emulador Android). Para un celular real: `--dart-define=ML_API_URL=http://<IP-del-PC>:8000`.
En Android hay que permitir HTTP sin cifrar: `android:usesCleartextTraffic="true"` en la etiqueta `<application>` de
`android/app/src/main/AndroidManifest.xml`.

Código: `lib/features/predictions/` (`data/prediction_api_client.dart`, `data/churn_payload_builder.dart`,
`data/predictions_providers.dart`, `domain/prediction_domain.dart`, `presentation/predictions_page.dart`).


## Conexión con el backend (Spring Boot en Railway)
La app ya no usa datos de ejemplo: todas las pantallas consumen la API de Spring Boot (`/api/m/**`,
ver `API_MOVIL.md` en el repo GymAssist2.0). Spring Boot tiene las claves de MongoDB, AWS S3 y Mercado Pago;
la app solo conoce dos direcciones:

| Qué | Variable | Valor por defecto |
|---|---|---|
| Backend Spring Boot | `SPRING_API_URL` | `https://gymassist20-production.up.railway.app` |
| API de predicción (Python) | `ML_API_URL` | `http://localhost:8000` (emulador Android: `10.0.2.2:8000`) |

```bash
flutter pub get
flutter run -d chrome                                                   # usa el backend de Railway
flutter run -d chrome --dart-define=SPRING_API_URL=http://localhost:8080   # backend local
```

- Login con token JWT (se guarda con `flutter_secure_storage`). Las rutas se protegen por rol y estado:
  admin sin gimnasio → `/gimnasio/registro`; cliente sin pagar → `/cliente/pago`.
- Pago: Spring Boot crea el cobro en Mercado Pago y la app abre el link (`url_launcher`); el webhook del
  backend activa la membresía. El admin también puede registrar pagos en efectivo.
- Fotos de rutinas: se eligen con `image_picker` y se suben a S3 a través de Spring Boot.
- Código: `lib/core/api/` (cliente HTTP, sesión, modelos, providers) y las páginas en `lib/features/`.
- La base local (Drift) y `demo_seed.dart` quedan sin uso por las pantallas.

Si en Chrome las fotos de S3 no cargan, el bucket necesita una regla CORS que permita `GET` desde cualquier origen.
