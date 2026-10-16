#!/usr/bin/env bash
# Downloads Elasticsearch into ./elasticsearch and verifies its SHA-512 checksum. Safe to re-run.
# Uses the Windows zip under Git Bash, the Linux tarball elsewhere. Elasticsearch bundles its own JDK.
set -euo pipefail
ES_VERSION="${ES_VERSION:-8.18.1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if [ -d elasticsearch/bin ]; then echo "Elasticsearch already installed in $ROOT/elasticsearch"; exit 0; fi

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) FILE="elasticsearch-${ES_VERSION}-windows-x86_64.zip" ;;
  *)                    FILE="elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz" ;;
esac
URL="https://artifacts.elastic.co/downloads/elasticsearch/$FILE"
echo "Downloading $URL"
curl -fsSL -o "$FILE" "$URL"
curl -fsSL -o "$FILE.sha512" "$URL.sha512"
expected=$(cut -d' ' -f1 < "$FILE.sha512")
actual=$(sha512sum "$FILE" | cut -d' ' -f1)
if [ "$expected" != "$actual" ]; then
  echo "Checksum mismatch for $FILE" >&2; rm -f "$FILE" "$FILE.sha512"; exit 1
fi
echo "Checksum OK"

# Extract straight into ./elasticsearch (no rename: on Windows, antivirus scanning can block renaming a fresh folder)
mkdir -p elasticsearch
if [[ "$FILE" == *.zip ]]; then
  unzip -q "$FILE" -d elasticsearch.tmp
  # zip has a top-level elasticsearch-<version>/ folder; move its contents up one level
  (cd elasticsearch.tmp/elasticsearch-* && tar -cf - .) | (cd elasticsearch && tar -xf -)
  rm -rf elasticsearch.tmp
else
  tar -xzf "$FILE" --strip-components=1 -C elasticsearch
fi
rm -f "$FILE" "$FILE.sha512"
echo "Elasticsearch $ES_VERSION installed in $ROOT/elasticsearch"
