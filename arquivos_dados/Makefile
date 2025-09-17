SHELL := /bin/bash

.PHONY: init db:push seed functions:deploy ingest

init:
	supabase start || true
	supabase stop || true

db:push:
	supabase db reset --env-file .env.local --db-url $$SUPABASE_DB_URL || true
	supabase db push --env-file .env.local

seed:
	# Import CSVs into staging
	psql $$SUPABASE_DB_URL -c "\\copy stg_pecas from 'data/csv/pe_as_de_reposi_ao.csv' with (format csv, header true, encoding 'UTF8');"
	psql $$SUPABASE_DB_URL -c "\\copy stg_sabres_correntes_pinhoes_limas from 'data/csv/sabres_correntes_pinh_es_limas.csv' with (format csv, header true, encoding 'UTF8');"
	psql $$SUPABASE_DB_URL -c "\\copy stg_cod_alterados from 'data/csv/cod_alterados.csv' with (format csv, header true, encoding 'UTF8');"

functions:deploy:
	supabase functions deploy chat --no-verify-jwt
	supabase functions deploy ingest --no-verify-jwt

ingest:
	curl -s -X POST "$$SUPABASE_URL/functions/v1/ingest" -H "Authorization: Bearer $$SUPABASE_ANON_KEY" -H 'Content-Type: application/json' -d '{"prefix":""}' | jq