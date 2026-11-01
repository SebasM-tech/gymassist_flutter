# Modelo de datos de GymAssist (Flutter, offline-first)

Base de datos local **SQLite vía Drift**. Es la única fuente de verdad: reemplaza MongoDB, PostgreSQL (esquema estrella), Redis (sesión) y S3 (imágenes).

## Diagrama entidad-relación

```mermaid
erDiagram
    USERS ||--o| GYMS : "administra (admin)"
    USERS ||--o| CLIENTS : "es (cliente)"
    GYMS ||--o{ PLANS : tiene
    GYMS ||--o{ CLIENTS : inscribe
    GYMS ||--o{ ROUTINES : ofrece
    PLANS |o--o{ CLIENTS : "plan actual (SET NULL)"
    CLIENTS ||--o{ ATTENDANCES : registra
    CLIENTS ||--o{ MEASUREMENTS : mide
    CLIENTS ||--o{ PAYMENTS : paga
    PLANS |o--o{ PAYMENTS : "plan pagado"
    USERS ||--o{ PAYMENTS : "registrado por"
    ROUTINES ||--o{ ROUTINE_PHOTOS : incluye
    USERS { text id PK  text username UK  text email UK  text password_hash  text role }
    GYMS { text id PK  text admin_user_id FK_UK  text name  text nit  text address  text description  text bank_account }
    PLANS { text id PK  text gym_id FK  text name  text description  int price_cop  int duration_months }
    CLIENTS { text id PK  text user_id FK_UK  text gym_id FK  text plan_id FK_null  text full_name  text document_id  text phone  text status  datetime joined_at  datetime membership_start  datetime membership_end  int missed_count }
    ATTENDANCES { text id PK  text client_id FK  datetime date  text muscles }
    MEASUREMENTS { text id PK  text client_id FK  real weight_kg  real height_m  datetime measured_at }
    ROUTINES { text id PK  text gym_id FK  text name  text muscle_group  text reps  text sets }
    ROUTINE_PHOTOS { text id PK  text routine_id FK  text relative_path  text description  int sort_order }
    PAYMENTS { text id PK  text client_id FK  text plan_id FK_null  int amount_cop  text method  datetime paid_at  datetime period_start  datetime period_end  text registered_by FK  text note }
    OUTBOX_OPS { int id PK  text entity  text entity_id  text op  text payload  datetime created_at }
```
Todas las tablas (salvo `OUTBOX_OPS`) llevan `created_at`, `updated_at` y `deleted_at` (borrado lógico) para poder sincronizar después.

## De dónde viene cada cosa

| Antes | Ahora | Qué cambió |
|---|---|---|
| Mongo `user` + `admin` + credenciales duplicadas en `client` | `users` (una sola fila por persona) | Se elimina la duplicación de contraseña/correo entre `user` y `client`. |
| Mongo `client` (con `asistencias[]` embebido) | `clients` + `attendances` | Las listas embebidas pasan a tablas hijas. |
| Mongo `client.nombrePlan` (copia) | `JOIN plans` | Ya no se copia el nombre del plan en cada cliente. |
| Mongo `rutina.fotosRutina[]` + URL de S3 | `routines` + `routine_photos` (ruta relativa en disco) | Archivos en el directorio de documentos de la app. |
| Mongo `gimnasios` (`fotos` byte[] sin usar) | `gyms` | Sin el campo sin uso. NIT y cuenta como texto. |
| Mongo `mediciones` | `measurements` | — |
| *(no existía)* historial de pagos | `payments` | Antes el pago activaba al cliente y no quedaba registro. |
| Postgres `dim_*` / `fact_*` + `SyncService` + Power BI | Consultas sobre las mismas tablas (`DashboardService`) | Se elimina el ETL por hora. |
| Redis (sesión 30 min) | `SessionStore` (Keychain/Keystore) | Misma expiración de 30 min de inactividad. |
| Precio `Double` | `price_cop` entero | Sin errores de redondeo con pesos. |

## Dónde quedó cada regla de negocio

| Regla (Spring) | Servicio Dart |
|---|---|
| `SecurityConfig.authenticationSuccessHandler` (a dónde ir tras el login) | `AuthService.login` → `LoginDestination` |
| `AuthController.registrarUsuario` | `AuthService.registerAdmin` |
| `ClienteService.crearCliente` | `ClientService.createClient` |
| Botón "Pagar" / `PaymentController.success` / webhook | `ClientService.registerPayment` |
| `detener`, `suspender`, `activar` | `stopMembership`, `suspend`, `activate` |
| `@Scheduled` + `verificarSuscripcionesExpiradas` | `ClientService.expireSubscriptions` |
| `PlanService.deletePlanById` | `PlanService.delete` (clientes quedan sin plan) |
| `ClienteService.registrarAsistencia` (inasistencias) | `AttendanceService.register` |
| `MedicionesService` (IMC) | `MeasurementService` + `ImcCalculator` |
| `RutinaService` + `S3Service` | `RoutineService` + `LocalFileStorage` |
| `DashboardService` | `DashboardService` (ingresos desde pagos reales) |

## Decisiones y desvíos respecto al plan inicial
- **Sin `freezed`** por ahora: las entidades son clases inmutables escritas a mano para tener un solo generador de código (Drift).
- **Sin SQLCipher todavía**: la BD no está cifrada. Las contraseñas sí están hasheadas (bcrypt) y la sesión va en Keychain/Keystore. El cifrado de la BD queda para la fase de endurecimiento.
- **Reglas nuevas** (no existían en el backend): una asistencia por día, solo con membresía activa; el cliente solo cambia de plan mientras está pendiente; un pago solo se registra si la membresía está pendiente.

## Cómo se prueba
`flutter test` usa una BD SQLite **en memoria** y un reloj controlable (`TestEnv`), así que las reglas de fechas (vencimientos, inasistencias) se prueban sin esperar días reales.
