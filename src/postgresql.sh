#!/bin/sh -eux

_setpriv() {
    setpriv --clear-groups --reuid snap_daemon --regid snap_daemon -- "$@"
}

_data="$(snapctl get postgresql.db)"
_port="$(snapctl get postgresql.port)"
_data="$(snapctl get postgresql.data)"
PGDATA="${_data:-$SNAP_COMMON/postgresql/database}"

export _data _port _data PGDATA

log() {
    printf '%s: %s\n' "$1" "$2"
}

createdb() {
    [ "$(snapctl get postgresql.db)" = "created" ] && exit 0

    log "INFO" "Creating postgresql database"

    # Wait for cluster to be available
    # TODO: more reliable way of knowing when postgres is available
    sleep 10

    [ -e "${PGDATA}/postgresql.conf" ] || {
    _setpriv createdb                  \
        --no-password                  \
        --host=127.0.0.1               \
        --port="${_port:-5433}"        \
        --username="${user:-postgres}" \
        "${_dbname:-immich}"
    }

    snapctl set postgresql.db=created
    snapctl stop --disable "${SNAP_INSTANCE_NAME}.createdb"
}

start() {
    log "INFO" "Starting postgresql database"
    _setpriv postgres                  \
        -h 127.0.0.1                   \
        -p "${_port:-5433}"            \
        -k "${SNAP_COMMON}/postgresql" \
        -D "${PGDATA}"
}

stop() {
    log "WARN" "Stopping postgresql database"
    pg_pid="$(head -1 "${PGDATA}/postmaster.pid")"
    kill -INT "$pg_pid"
}

reload() {
    log "INFO" "Restarting postgresql database"
    stop && start
}

"$@"
