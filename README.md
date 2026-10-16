# Elasticsearch Service

Search engine setup for the ecom platform (HLD 3.2: Elasticsearch for product search). This repository holds **no
application code**: it contains everything needed to run the Elasticsearch node the Product Service uses.

| | |
|---|---|
| Elasticsearch | 8.18.1 (matches the Java client in Spring Boot 3.5), single node, bundled JDK |
| Address | `http://localhost:9200`, bound to localhost only |
| Used by | Product Service: `GET /api/v1/products/search?keyword=...` |

## Index

| Index | Documents | Fields |
|---|---|---|
| `products` | One per non-deleted product | `name` (text, English analyzer, + `name.keyword`), `description` (text, English), `categoryName` (text + keyword), `price` |

- The **database stays the source of truth**. The index only answers "which product ids match, in what order";
  the Product Service then loads those products from its database (so deleted products never appear).
- The Product Service keeps the index in sync on every create/update/delete, rebuilds it from the database on
  startup, and admins can rebuild it with `POST /api/v1/products/search/reindex`.
- Search = fuzzy multi-match (`AUTO:4,7`: no typos under 4 letters, 1 for 4–6, 2 for 7+) **or** phrase prefix,
  boosting `name` ×3, `categoryName` ×2, `description` ×1. Examples: `phnoe` → phone, `pho` → phone, `jogging` →
  Running Shoes (description), `electronics` → the whole category.
- If Elasticsearch is down, search falls back to the database name search; the response header
  `X-Search-Engine: elasticsearch | database` shows which answered.

## Run locally (Windows with Git Bash, or Linux)

```bash
scripts/setup-elasticsearch.sh   # once: downloads Elasticsearch 8.18.1 into ./elasticsearch, verifies SHA-512
scripts/start-elasticsearch.sh   # foreground (Ctrl+C), data in ./data, logs in ./logs
scripts/stop-elasticsearch.sh    # stop it from another terminal
```

## Run with Docker (Linux / servers)

```bash
docker compose up -d
```

## Inspecting

```bash
scripts/es-cli.sh health            # cluster health (green = OK)
scripts/es-cli.sh indices           # indices and document counts
scripts/es-cli.sh mapping           # products field mapping
scripts/es-cli.sh search phnoe      # try a fuzzy search directly
```

## Service configuration (Product Service)

| Env var | Default |
|---|---|
| `ELASTICSEARCH_URL` | `http://localhost:9200` |
| `SEARCH_ELASTICSEARCH_ENABLED` | `true` (`false` = always use the database search) |

## Not for production as-is

Security (TLS, users, API keys) is **disabled** and there is one node with no replicas. For production enable
`xpack.security`, connect over HTTPS with an API key, and run at least 3 nodes (or Elastic Cloud / Amazon
OpenSearch Service) with 1 replica per shard.
