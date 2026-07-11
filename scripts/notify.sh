#!/bin/bash

# ============================================================
# DevOps Monitor - Sistema de Notificaciones
#
# Responsable:
#   Envío de correos electrónicos del monitor de disponibilidad.
#
# Tipos de notificación:
#   - DOWN
#   - RECOVERED
#   - CRITICAL
#
# ============================================================

set -euo pipefail

# ============================================================
# Variables SMTP
# ============================================================

SMTP_SERVER="${SMTP_SERVER}"
SMTP_PORT="${SMTP_PORT}"
SMTP_USERNAME="${SMTP_USERNAME}"
SMTP_PASSWORD="${SMTP_PASSWORD}"

MAIL_TO="${MAIL_TO}"

# ============================================================
# Variables del Incidente
# ============================================================

EVENT_TYPE="${1}"

INCIDENT_ID="${2}"

CLUSTER_NAME="${3}"

NAMESPACE="${4}"

DEPLOYMENT_NAME="${5}"

HTTP_STATUS="${6}"

EVENT_TIME="${7}"

DOWNTIME="${8:-N/A}"

# ============================================================
# Función Log
# ============================================================

log() {

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"

}
# ============================================================
# Construcción del correo
# ============================================================

case "$EVENT_TYPE" in

    DOWN)

        SUBJECT="🚨 [$INCIDENT_ID] Servicio fuera de línea"

        BODY=$(cat <<EOF
Se ha detectado una interrupción en el servicio.

Incidente:
$INCIDENT_ID

Hora de detección:
$EVENT_TIME

Cluster:
$CLUSTER_NAME

Namespace:
$NAMESPACE

Deployment:
$DEPLOYMENT_NAME

Estado HTTP:
$HTTP_STATUS

El sistema iniciará automáticamente el proceso de recuperación.

----------------------------------------------------
Este mensaje fue generado automáticamente por
DevOps Monitor - Tienda Perritos
----------------------------------------------------
EOF
)

    ;;

    RECOVERED)

        SUBJECT="✅ [$INCIDENT_ID] Servicio recuperado automáticamente"

        BODY=$(cat <<EOF
El incidente $INCIDENT_ID ha sido resuelto automáticamente.

Hora de recuperación:
$EVENT_TIME

Tiempo de indisponibilidad:
$DOWNTIME segundos

Cluster:
$CLUSTER_NAME

Namespace:
$NAMESPACE

Deployment:
$DEPLOYMENT_NAME

No fue necesaria intervención manual.

----------------------------------------------------
Este mensaje fue generado automáticamente por
DevOps Monitor - Tienda Perritos
----------------------------------------------------
EOF
)

    ;;

    CRITICAL)

        SUBJECT="🚨 [$INCIDENT_ID] Intervención manual requerida"

        BODY=$(cat <<EOF
No fue posible recuperar automáticamente el servicio.

Incidente:
$INCIDENT_ID

Hora del incidente:
$EVENT_TIME

Cluster:
$CLUSTER_NAME

Namespace:
$NAMESPACE

Deployment:
$DEPLOYMENT_NAME

Estado HTTP:
$HTTP_STATUS

Se requiere intervención de un administrador.

----------------------------------------------------
Este mensaje fue generado automáticamente por
DevOps Monitor - Tienda Perritos
----------------------------------------------------
EOF
)

    ;;

    *)

        log "Tipo de evento desconocido."

        exit 1

    ;;

esac
# ============================================================
# Envío del correo
# ============================================================

log "==========================================="
log "Preparando envío de correo..."
log "==========================================="

log "Servidor SMTP : $SMTP_SERVER"
log "Puerto        : $SMTP_PORT"
log "Destinatarios : $MAIL_TO"

# ============================================================
# TODO:
#
# Implementación SMTP.
#
# Próxima versión:
#
# 1. Autenticación con Gmail
# 2. Construcción del mensaje RFC822
# 3. Envío mediante SMTP TLS
#
# ============================================================

log "Asunto:"
log "$SUBJECT"

echo ""

log "Contenido del correo:"

echo "$BODY"

echo ""

log "==========================================="
log "Notificación preparada correctamente."
log "==========================================="

exit 0
