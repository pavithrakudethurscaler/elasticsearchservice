#!/usr/bin/env bash
# Small helper for inspecting the local Elasticsearch (plain HTTP on localhost:9200).
#   scripts/es-cli.sh health                  cluster health
#   scripts/es-cli.sh indices                 list indices with document counts
#   scripts/es-cli.sh mapping [index]         field mapping (default: products)
#   scripts/es-cli.sh search <text> [index]   run the same kind of fuzzy search the Product Service uses
set -euo pipefail
ES="${ELASTICSEARCH_URL:-http://localhost:9200}"
c() { curl -s --noproxy '*' "$@"; echo; }

case "${1:-}" in
  health)  c "$ES/_cluster/health?pretty" ;;
  indices) c "$ES/_cat/indices?v&h=index,health,docs.count,store.size" ;;
  mapping) c "$ES/${2:-products}/_mapping?pretty" ;;
  search)  c -H 'Content-Type: application/json' "$ES/${3:-products}/_search?pretty" -d "{
             \"query\": {\"multi_match\": {\"query\": \"$2\", \"fields\": [\"name^3\", \"categoryName^2\", \"description\"],
             \"fuzziness\": \"AUTO:4,7\"}}, \"_source\": [\"name\", \"categoryName\", \"price\"]}" ;;
  *) echo "usage: $0 health | indices | mapping [index] | search <text> [index]" >&2; exit 1 ;;
esac
