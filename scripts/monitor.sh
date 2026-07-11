#!/bin/bash

# ============================================================
# Monitor de disponibilidad para Kubernetes (Amazon EKS).
# Detecta incidentes, intenta la recuperación automática y
# notifica el estado del servicio.
# ============================================================

set -euo pipefail

# ============================================================
# Variables globales
# ============================================================

AWS_REGION="${AWS_REGION}"
CLUSTER_NAME="${CLUSTER_NAME}"

NAMESPACE="${NAMESPACE}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME}"

HEALTH_URL="${HEALTH_URL}"

WAIT_SECONDS="${WAIT_SECONDS}"
MAX_RECOVERY_ATTEMPTS="${MAX_RECOVERY_ATTEMPTS}"

MAIL_TO="${MAIL_TO}"

# ============================================================
# Variables del incidente
# ============================================================

INCIDENT_ID=""
INCIDENT_START=""
INCIDENT_TIMESTAMP=""
HTTP_STATUS=""
# ============================================================
# Función: log
# Registra mensajes con fecha y hora
# ============================================================

log() {

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"

}

# ============================================================
# Función: generate_incident
# Genera el identificador del incidente
# ============================================================

generate_incident() {

    INCIDENT_ID="INC-$(date '+%Y%m%d-%H%M%S')"

    INCIDENT_START=$(date '+%Y-%m-%d %H:%M:%S')

    INCIDENT_TIMESTAMP=$(date +%s)

    log "==========================================="
    log "INCIDENTE DETECTADO"
    log "ID        : $INCIDENT_ID"
    log "Fecha     : $INCIDENT_START"
    log "Cluster   : $CLUSTER_NAME"
    log "Namespace : $NAMESPACE"
    log "Deployment: $DEPLOYMENT_NAME"
    log "==========================================="

}
# ============================================================
# Función: health_check
# Verifica el estado del endpoint de salud
# Devuelve:
#   0 = Servicio disponible
#   1 = Servicio no disponible
# ============================================================

health_check() {

    log "Verificando disponibilidad del servicio..."

    HTTP_STATUS=$(curl \
        --silent \
        --output /dev/null \
        --write-out "%{http_code}" \
        "$HEALTH_URL")

    log "HTTP Status: $HTTP_STATUS"

    if [ "$HTTP_STATUS" = "200" ]; then

        log "Servicio disponible."

        return 0

    fi

    log "Servicio NO disponible."

    return 1

}
# ============================================================
# Función: restart_backend
# Reinicia el Deployment del Backend y espera
# a que Kubernetes complete el rollout.
# ============================================================

restart_backend() {

    log "==========================================="
    log "Iniciando recuperación automática..."
    log "Deployment : $DEPLOYMENT_NAME"
    log "Namespace  : $NAMESPACE"
    log "==========================================="

    log "Estado actual del Deployment"

    kubectl get deployment "$DEPLOYMENT_NAME" \
        -n "$NAMESPACE"

    echo ""

    log "Ejecutando rollout restart..."

    kubectl rollout restart deployment/"$DEPLOYMENT_NAME" \
        -n "$NAMESPACE"

    echo ""

    log "Esperando que finalice el despliegue..."

    kubectl rollout status deployment/"$DEPLOYMENT_NAME" \
        -n "$NAMESPACE"

    echo ""

    log "Recuperación finalizada."

}


# ============================================================
# Programa Principal
# ============================================================

log "==========================================="
log "Iniciando monitor de disponibilidad..."
log "==========================================="

# ------------------------------------------------------------
# Primera verificación del servicio
# ------------------------------------------------------------

if health_check; then

    log "El servicio se encuentra operativo."

    log "Finalizando monitor."

    exit 0

fi

# ------------------------------------------------------------
# Se detectó un incidente
# ------------------------------------------------------------

generate_incident

./scripts/notify.sh \
    DOWN \
    "$INCIDENT_ID" \
    "$CLUSTER_NAME" \
    "$NAMESPACE" \
    "$DEPLOYMENT_NAME" \
    "$HTTP_STATUS" \
    "$INCIDENT_START"

log "Se iniciará el proceso de recuperación automática."
# ------------------------------------------------------------
# PRIMER CICLO DE RECUPERACIÓN
# ------------------------------------------------------------

log "==========================================="
log "PRIMER INTENTO FALLIDO"
log "Iniciando segundo intento de recuperación..."
log "==========================================="

restart_backend

log "Esperando $WAIT_SECONDS segundos..."

sleep "$WAIT_SECONDS"

log "Verificando nuevamente el servicio..."

if health_check; then

    RECOVERY_TIMESTAMP=$(date +%s)

    RECOVERY_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    DOWNTIME=$((RECOVERY_TIMESTAMP - INCIDENT_TIMESTAMP))

    log "==========================================="
    log "SERVICIO RECUPERADO"
    log "Tiempo de indisponibilidad : ${DOWNTIME} segundos"
    log "==========================================="

    ./scripts/notify.sh \
        RECOVERED \
        "$INCIDENT_ID" \
        "$CLUSTER_NAME" \
        "$NAMESPACE" \
        "$DEPLOYMENT_NAME" \
        "$HTTP_STATUS" \
        "$RECOVERY_TIME" \
        "$DOWNTIME"

    exit 0

fi

# ------------------------------------------------------------
# SEGUNDO CICLO DE RECUPERACIÓN
# ------------------------------------------------------------

log "==========================================="
log "PRIMER INTENTO FALLIDO"
log "Se iniciará un segundo ciclo."
log "==========================================="

restart_backend

log "Esperando $WAIT_SECONDS segundos..."

sleep "$WAIT_SECONDS"

log "Realizando última verificación..."

if health_check; then

    RECOVERY_TIMESTAMP=$(date +%s)

    RECOVERY_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    DOWNTIME=$((RECOVERY_TIMESTAMP - INCIDENT_TIMESTAMP))

    log "==========================================="
    log "SERVICIO RECUPERADO"
    log "Tiempo de indisponibilidad : ${DOWNTIME} segundos"
    log "==========================================="

    ./scripts/notify.sh \
        RECOVERED \
        "$INCIDENT_ID" \
        "$CLUSTER_NAME" \
        "$NAMESPACE" \
        "$DEPLOYMENT_NAME" \
        "$HTTP_STATUS" \
        "$RECOVERY_TIME" \
        "$DOWNTIME"

    exit 0

fi

# ------------------------------------------------------------
# EL SERVICIO NO PUDO RECUPERARSE
# ------------------------------------------------------------

log "==========================================="
log "RECUPERACIÓN AUTOMÁTICA FALLIDA"
log "Se requiere intervención manual."
log "==========================================="

./scripts/notify.sh \
    CRITICAL \
    "$INCIDENT_ID" \
    "$CLUSTER_NAME" \
    "$NAMESPACE" \
    "$DEPLOYMENT_NAME" \
    "$HTTP_STATUS" \
    "$INCIDENT_START"

exit 1
