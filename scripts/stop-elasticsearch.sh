#!/usr/bin/env bash
# Stops the local Elasticsearch started by start-elasticsearch.sh (the process listening on port 9200).
set -euo pipefail
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    PID=$(netstat -ano | awk '$2 ~ /:9200$/ && $4 == "LISTENING" {print $5; exit}')
    [ -z "$PID" ] && { echo "Elasticsearch is not running"; exit 0; }
    taskkill //PID "$PID" //F >/dev/null && echo "Stopped Elasticsearch (pid $PID)" ;;
  *)
    PID=$(lsof -ti tcp:9200 -sTCP:LISTEN || true)
    [ -z "$PID" ] && { echo "Elasticsearch is not running"; exit 0; }
    kill "$PID" && echo "Stopped Elasticsearch (pid $PID)" ;;
esac
