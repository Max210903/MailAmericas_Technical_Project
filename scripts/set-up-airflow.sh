#!/usr/bin/env bash
# Levanta y administra el stack de Airflow (docker/airflow/docker-compose.yml).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker/airflow/docker-compose.yml"
AIRFLOW_URL="http://localhost:8080"

# UID de quien ejecuta, para que airflow/logs no quede como root
export AIRFLOW_UID="$(id -u)"

log()  { printf '\033[1;34m[airflow]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

compose() { docker compose -f "$COMPOSE_FILE" "$@"; }

check_requirements() {
  command -v docker >/dev/null || fail "Docker no está instalado."
  docker compose version >/dev/null 2>&1 || fail "Falta el plugin 'docker compose'."
  docker info >/dev/null 2>&1 || fail "El daemon de Docker no responde (sudo systemctl start docker)."
  [[ "$(docker info --format '{{.OperatingSystem}}')" != *"Docker Desktop"* ]] \
    || fail "Se detectó Docker Desktop; este proyecto usa Docker Engine nativo."
}

create_dirs() {
  mkdir -p "$ROOT_DIR"/airflow/{dags,plugins,logs}
}

verify() {
  log "Verificando..."
  curl -sf "$AIRFLOW_URL/health" >/dev/null || fail "El webserver no responde en $AIRFLOW_URL/health"
  log "Versión: $(compose exec -T airflow-scheduler airflow version 2>/dev/null | tail -1)"
  log "Airflow listo en $AIRFLOW_URL (usuario: admin / contraseña: admin)"
}

case "${1:-}" in
  up)
    check_requirements
    create_dirs
    log "Construyendo y levantando el stack (la primera vez tarda unos minutos)..."
    compose up -d --build --wait
    verify
    ;;
  down)   compose down ;;
  clean)  compose down -v --rmi local ;;
  status) compose ps -a ;;
  logs)   compose logs -f ${2:+"$2"} ;;
  *)      echo "Uso: $0 {up|down|clean|status|logs [servicio]}"; exit 1 ;;
esac
