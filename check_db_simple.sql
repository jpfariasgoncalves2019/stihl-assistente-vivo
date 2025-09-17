-- Verificação simples e direta da estrutura do banco

-- 1. Schemas existentes
SELECT 'SCHEMAS' as tipo, schema_name as nome
FROM information_schema.schemata 
WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'supabase_functions', 'extensions', 'graphql', 'graphql_public', 'net', 'pgsodium', 'pgsodium_masks', 'realtime', 'supabase_migrations', 'vault')
ORDER BY schema_name;

-- 2. Tabelas no schema oficina
SELECT 'TABELA_OFICINA' as tipo, table_name as nome
FROM information_schema.tables 
WHERE table_schema = 'oficina'
ORDER BY table_name;

-- 3. Tabelas no schema public (principais)
SELECT 'TABELA_PUBLIC' as tipo, table_name as nome
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('attendant_prompts', 'conversation_logs')
ORDER BY table_name;

-- 4. Verificar se schema oficina existe
SELECT CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'oficina') 
    THEN 'SCHEMA_OFICINA_EXISTE' 
    ELSE 'SCHEMA_OFICINA_NAO_EXISTE' 
END as status;

-- 5. Verificar extensões críticas
SELECT 'EXTENSAO' as tipo, extname as nome, extversion as versao
FROM pg_extension 
WHERE extname IN ('vector', 'pg_trgm', 'uuid-ossp');
