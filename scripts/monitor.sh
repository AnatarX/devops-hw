#!/usr/bin/env bash
# ./monitor.sh docker
# exit: 0 - active, 1 - не active, 2 - ошибка

set -euo pipefail

readonly SYSLOG="${SYSLOG_FILE:-/var/log/syslog}"
readonly LOG_LINES=10

if [[ -t 1 ]]; then
  RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
else
  RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

info()  { echo "${BOLD}==>${RESET} $*"; }
warn()  { echo "${YELLOW}WARN:${RESET} $*" >&2; }
error() { echo "${RED}ERROR:${RESET} $*" >&2; }

usage() {
  echo "Usage: $(basename "$0") <service>" >&2
  echo "Example: $(basename "$0") docker" >&2
}

if [[ $# -ne 1 || -z "${1:-}" ]]; then
  usage
  exit 2
fi

service="${1%.service}"

if ! command -v systemctl >/dev/null 2>&1; then
  error "systemctl не найден: скрипт работает только в системах с systemd"
  exit 2
fi

load_state=$(systemctl show -p LoadState --value "${service}.service" 2>/dev/null || true)
if [[ -z "$load_state" || "$load_state" == "not-found" ]]; then
  error "сервис '${service}' не найден"
  exit 2
fi

status=$(systemctl is-active "${service}" 2>/dev/null || true)
rc=0

if [[ "$status" == "active" ]]; then
  info "Сервис ${BOLD}${service}${RESET}: ${GREEN}${status}${RESET}"
else
  rc=1
  info "Сервис ${BOLD}${service}${RESET}: ${RED}${status:-unknown}${RESET}"
  info "Последние ${LOG_LINES} строк лога (journalctl -u ${service}):"

  journal=$(journalctl -u "${service}" -n "${LOG_LINES}" --no-pager 2>&1 || true)
  if [[ -z "$journal" || "$journal" == "-- No entries --" ]]; then
    warn "лог сервиса пуст или недоступен (попробуйте запустить через sudo)"
  else
    echo "$journal"
  fi
fi

# префиксы времени за последние 60 минут (оба формата syslog)

last_hour_prefixes() {
  local i
  for i in $(seq 0 59); do
    LC_ALL=C date -d "-${i} min" '+%b %e %H:%M'
    LC_ALL=C date -d "-${i} min" '+%Y-%m-%dT%H:%M'
  done
}

if [[ -r "$SYSLOG" ]]; then
  # grep без совпадений = код 1, поэтому || true
  report=$({ grep -F -f <(last_hour_prefixes) "$SYSLOG" || true; } \
    | awk '{ line = tolower($0) }
           line ~ /error/ && line !~ /level=(debug|info|warn)/ {
             n++; src = ($1 ~ /^[0-9][0-9][0-9][0-9]-/) ? $3 : $5; sub(/\[[0-9]+\]/, "", src); sub(/:$/, "", src); by[src]++
           }
           END {
             print n + 0
             for (s in by) printf "    %5d  %s\n", by[s], s
           }')
  errors=$(head -n 1 <<<"$report")
  info "Ошибок в ${SYSLOG} за последний час: ${BOLD}${errors}${RESET}"
  if (( errors > 0 )); then
    echo "    по источникам:"
    tail -n +2 <<<"$report" | sort -rn | awk 'NR <= 5'
  fi
elif [[ -e "$SYSLOG" ]]; then
  warn "нет прав на чтение ${SYSLOG} (запустите через sudo или добавьте пользователя в группу adm)"
else
  warn "${SYSLOG} не найден, считаем ошибки по journald (приоритет err и выше)"
  errors=$({ journalctl --since "1 hour ago" -p err --no-pager -q 2>/dev/null || true; } \
    | awk 'END { print NR }')
  info "Ошибок в журнале за последний час: ${BOLD}${errors}${RESET}"
fi

exit "$rc"
