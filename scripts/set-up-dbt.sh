#!/usr/bin/env bash
# Prepara y ejecuta dbt dentro del contenedor del scheduler de Airflow (dbt vive en esa imagen).
set -euo pipefail

SCHEDULER="mailamericas-airflow-scheduler"
DBT_DIR="/opt/airflow/dbt"

log()  { printf '\033[1;35m[dbt]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

check_scheduler() {
  [[ "$(docker inspect -f '{{.State.Running}}' "$SCHEDULER" 2>/dev/null)" == "true" ]] \
    || fail "El scheduler de Airflow no está corriendo. Ejecuta primero: ./scripts/set-up-airflow.sh up"
}

# Ejecuta dbt en el contenedor, desde la carpeta del proyecto (DBT_PROFILES_DIR ya viene del compose)
dbt_exec() {
  local tty=()
  [[ -t 0 && -t 1 ]] && tty=(-it)
  docker exec "${tty[@]}" -w "$DBT_DIR" "$SCHEDULER" dbt "$@"
}

usage() {
  cat <<EOF
Uso:
  $0 up                 Instala paquetes (dbt deps), valida el proyecto (dbt parse) y prueba la conexión
  $0 <comando dbt>      Ejecuta cualquier comando de dbt, por ejemplo:
                          $0 build --select staging
                          $0 test
EOF
}

case "${1:-}" in
  up)
    check_scheduler
    log "Instalando paquetes..."
    dbt_exec deps
    log "Validando el proyecto..."
    dbt_exec parse
    # Solo la conexión: el debug completo falla porque la imagen de Airflow no incluye git
    log "Probando la conexión al warehouse..."
    dbt_exec debug --connection
    log "dbt listo"
    ;;
  ""|-h|--help) usage ;;
  *)
    check_scheduler
    dbt_exec "$@"
    ;;
esac
