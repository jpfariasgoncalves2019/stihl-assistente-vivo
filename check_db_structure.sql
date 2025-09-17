-- =============================================================================
-- SCRIPT PARA VERIFICAR ESTRUTURA ATUAL DO BANCO SUPABASE
-- =============================================================================

-- 1. Verificar schemas existentes
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
ORDER BY schema_name;

-- 2. Verificar tabelas no schema 'oficina' (se existir)
SELECT table_name, table_type
FROM information_schema.tables 
WHERE table_schema = 'oficina'
ORDER BY table_name;

-- 3. Verificar tabelas no schema 'public'
SELECT table_name, table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name NOT LIKE 'pg_%'
ORDER BY table_name;

-- 4. Verificar colunas da tabela part_compat_staging (se existir)
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'oficina' 
AND table_name = 'part_compat_staging'
ORDER BY ordinal_position;

-- 5. Verificar funções no schema 'oficina' (se existir)
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'oficina'
ORDER BY routine_name;

-- 6. Verificar políticas RLS existentes
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies 
WHERE schemaname IN ('oficina', 'public')
ORDER BY schemaname, tablename, policyname;

-- 7. Verificar extensões instaladas
SELECT extname, extversion 
FROM pg_extension 
WHERE extname IN ('vector', 'pg_trgm', 'uuid-ossp');

-- 8. Contar registros nas tabelas principais (se existirem)
DO $$
DECLARE
    rec RECORD;
    sql_text TEXT;
    count_result INTEGER;
BEGIN
    FOR rec IN 
        SELECT table_schema, table_name 
        FROM information_schema.tables 
        WHERE table_schema IN ('oficina', 'public')
        AND table_name IN ('models', 'parts', 'part_prices', 'part_compat', 'attendant_prompts')
    LOOP
        sql_text := format('SELECT COUNT(*) FROM %I.%I', rec.table_schema, rec.table_name);
        EXECUTE sql_text INTO count_result;
        RAISE NOTICE 'Tabela %.%: % registros', rec.table_schema, rec.table_name, count_result;
    END LOOP;
END $$;

SELECT 'Análise da estrutura do banco concluída!' as status;
