#!/usr/bin/env bash
# Starts the local single-node Elasticsearch on http://localhost:9200 in the foreground. Stop it with Ctrl+C
# (or scripts/stop-elasticsearch.sh). Data goes to ./data, logs to ./logs. Uses Elasticsearch's bundled JDK.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ES_HOME="$ROOT/elasticsearch"
if [ ! -d "$ES_HOME/bin" ]; then
  echo "Elasticsearch is not installed. Run scripts/setup-elasticsearch.sh first." >&2; exit 1
fi
mkdir -p "$ROOT/data" "$ROOT/logs"
cp "$ROOT/config/elasticsearch.yml" "$ES_HOME/config/elasticsearch.yml"

# Small heap: enough for the product catalog, friendly to a development machine
export ES_JAVA_OPTS="${ES_JAVA_OPTS:--Xms512m -Xmx512m}"
# Use the bundled JDK, not whatever JAVA_HOME points to
unset JAVA_HOME ES_JAVA_HOME

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    DATA=$(cygpath -w "$ROOT/data"); LOGS=$(cygpath -w "$ROOT/logs")
    exec cmd //c "$(cygpath -w "$ES_HOME/bin/elasticsearch.bat")" "-Epath.data=$DATA" "-Epath.logs=$LOGS" ;;
  *)
    exec "$ES_HOME/bin/elasticsearch" "-Epath.data=$ROOT/data" "-Epath.logs=$ROOT/logs" ;;
esac
