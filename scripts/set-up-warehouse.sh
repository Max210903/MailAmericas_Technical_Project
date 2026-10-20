#!/usr/bin/env bash
# Levanta y administra el warehouse Postgres (docker/warehouse/docker-compose.yml).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker/warehouse/docker-compose.yml"
WAREHOUSE_NET="mailamericas-warehouse-net"
AIRFLOW_CONTAINERS=(mailamericas-airflow-scheduler mailamericas-airflow-webserver)
DB_USER="${WAREHOUSE_DB_USER:-warehouse}"

log()  { printf '\033[1;32m[warehouse]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

compose() { docker compose -f "$COMPOSE_FILE" "$@"; }

# Sin permiso sobre el socket de Docker (usuario fuera del grupo docker): se reejecuta con sudo
if [[ $EUID -ne 0 ]] && grep -qi "permission denied" <<<"$(docker info 2>&1)"; then
  log "Tu usuario no está en el grupo docker: se reejecuta con sudo"
  exec sudo -E bash "$0" "$@"
fi

check_requirements() {
  command -v docker >/dev/null || fail "Docker no está instalado."
  docker compose version >/dev/null 2>&1 || fail "Falta el plugin 'docker compose'."
  docker info >/dev/null 2>&1 || fail "El daemon de Docker no responde (sudo systemctl start docker)."
  [[ "$(docker info --format '{{.OperatingSystem}}')" != *"Docker Desktop"* ]] \
    || fail "Se detectó Docker Desktop; este proyecto usa Docker Engine nativo."
}

# Conecta los contenedores de Airflow que estén corriendo a la red del warehouse (idempotente)
connect_airflow() {
  for c in "${AIRFLOW_CONTAINERS[@]}"; do
    docker container inspect "$c" >/dev/null 2>&1 || continue
    if docker inspect -f '{{json .NetworkSettings.Networks}}' "$c" | grep -q "\"$WAREHOUSE_NET\""; then
      continue
    fi
    docker network connect "$WAREHOUSE_NET" "$c"
    log "Conectado $c a $WAREHOUSE_NET"
  done
}

# Desconecta Airflow antes de bajar el warehouse, para que Compose pueda borrar la red
disconnect_airflow() {
  docker network inspect "$WAREHOUSE_NET" >/dev/null 2>&1 || return 0
  for c in "${AIRFLOW_CONTAINERS[@]}"; do
    docker network disconnect "$WAREHOUSE_NET" "$c" >/dev/null 2>&1 || true
  done
}

verify() {
  log "Verificando..."
  local schemas
  schemas="$(compose exec -T warehouse-db psql -U "$DB_USER" -d warehouse -Atc \
    "select string_agg(schema_name, ', ' order by schema_name) from information_schema.schemata
     where schema_name in ('raw','staging','intermediate','marts')")"
  [[ "$schemas" == "intermediate, marts, raw, staging" ]] || fail "Esquemas incompletos: '$schemas'"
  log "Esquemas: $schemas"
  log "Warehouse listo en localhost:5432 (base: warehouse / usuario: $DB_USER)"
}

case "${1:-}" in
  up)
    check_requirements
    log "Levantando el warehouse..."
    compose up -d --wait
    verify
    connect_airflow
    ;;
  down)   disconnect_airflow; compose down ;;
  clean)  disconnect_airflow; compose down -v ;;
  status) compose ps -a ;;
  logs)   compose logs -f ;;
  psql)   compose exec warehouse-db psql -U "$DB_USER" -d warehouse ;;
  *)      echo "Uso: $0 {up|down|clean|status|logs|psql}"; exit 1 ;;
esac
