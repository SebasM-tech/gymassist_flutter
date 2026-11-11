#!/usr/bin/env bash
# Prepara el proyecto después de descomprimir o de reemplazar lib/.  Uso:  bash setup.sh
# Es seguro ejecutarlo varias veces.
set -e
cd "$(dirname "$0")"

echo "1/4  flutter pub get"
flutter pub get

# Plataformas (web, macos, android, ios) si todavía no existen.
if [ ! -f web/index.html ]; then
  echo "2/4  flutter create (agrega las plataformas que faltan; no toca lib/)"
  flutter create . --platforms=web,macos,android,ios --project-name gymassist
else
  echo "2/4  plataformas ya creadas"
fi

# Los archivos web de Drift deben coincidir con las versiones de pubspec.lock.
ver() { awk -v p="$1:" '$1==p {f=1} f && $1=="version:" {gsub(/"/,"",$2); print $2; exit}' pubspec.lock; }
DRIFT_V="$(ver drift)"; SQLITE_V="$(ver sqlite3)"
echo "3/4  archivos web de Drift (drift $DRIFT_V, sqlite3 $SQLITE_V)"
mkdir -p web
if [ ! -f "web/.drift-$DRIFT_V-sqlite3-$SQLITE_V" ]; then
  curl -fsSL -o web/sqlite3.wasm    "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$SQLITE_V/sqlite3.wasm"
  curl -fsSL -o web/drift_worker.js "https://github.com/simolus3/drift/releases/download/drift-$DRIFT_V/drift_worker.js"
  rm -f web/.drift-*; touch "web/.drift-$DRIFT_V-sqlite3-$SQLITE_V"
fi

echo "4/4  build_runner (genera app_database.g.dart)"
dart run build_runner build --delete-conflicting-outputs

echo
echo "Listo. Ejecuta:  flutter run -d chrome --dart-define=SEED_DEMO=true"
