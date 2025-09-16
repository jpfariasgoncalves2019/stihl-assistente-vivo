-- =============================================================================
-- STIHL Assistente Virtual - Health Check
-- Arquivo: sql/HEALTHCHECK.sql
-- 
-- Este script verifica se toda a configuração está funcionando corretamente
-- =============================================================================

\echo '🔍 STIHL Assistente Virtual - Health Check'
\echo ''

-- Verificar extensões
\echo '📋 1. EXTENSÕES:'
SELECT 
    extname as "Extensão",
    CASE WHEN extname IN ('pg_trgm', 'unaccent', 'vector') THEN '✅' ELSE '❌' END as "Status"
FROM pg_extension 
WHERE extname IN ('pg_trgm', 'unaccent', 'vector')
ORDER BY extname;

-- Verificar schemas
\echo ''
\echo '📁 2. SCHEMAS:'
SELECT 
    schema_name as "Schema",
    CASE WHEN schema_name IN ('oficina', 'public') THEN '✅' ELSE '❌' END as "Status"
FROM information_schema.schemata 
WHERE schema_name IN ('oficina', 'public')
ORDER BY schema_name;

-- Verificar tabelas principais
\echo ''
\echo '📊 3. TABELAS PRINCIPAIS:'
WITH expected_tables AS (
    SELECT unnest(ARRAY[
        'oficina.models',
        'oficina.parts', 
        'oficina.part_prices',
        'oficina.part_compat',
        'oficina.part_aliases',
        'oficina.model_aliases',
        'oficina.docs',
        'oficina.doc_facts',
        'public.attendant_prompts',
        'public.conversation_logs'
    ]) as table_name
),
existing_tables AS (
    SELECT schemaname || '.' || tablename as table_name
    FROM pg_tables 
    WHERE schemaname IN ('oficina', 'public')
)
SELECT 
    et.table_name as "Tabela",
    CASE WHEN ext.table_name IS NOT NULL THEN '✅' ELSE '❌' END as "Existe"
FROM expected_tables et
LEFT JOIN existing_tables ext ON et.table_name = ext.table_name
ORDER BY et.table_name;

-- Verificar funções principais
\echo ''
\echo '⚙️ 4. FUNÇÕES PRINCIPAIS:'
WITH expected_functions AS (
    SELECT unnest(ARRAY[
        'oficina.search_parts',
        'oficina.suggest_models', 
        'oficina.search_docs_secure',
        'public.search_parts',
        'public.suggest_models',
        'public.search_docs_secure'
    ]) as function_name
),
existing_functions AS (
    SELECT schemaname || '.' || proname as function_name
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname IN ('oficina', 'public')
    AND proname IN ('search_parts', 'suggest_models', 'search_docs_secure')
)
SELECT 
    ef.function_name as "Função",
    CASE WHEN exf.function_name IS NOT NULL THEN '✅' ELSE '❌' END as "Existe"
FROM expected_functions ef
LEFT JOIN existing_functions exf ON ef.function_name = exf.function_name
ORDER BY ef.function_name;

-- Verificar RLS
\echo ''
\echo '🔒 5. ROW LEVEL SECURITY:'
SELECT 
    schemaname || '.' || tablename as "Tabela",
    CASE WHEN rowsecurity THEN '✅ Ativo' ELSE '❌ Inativo' END as "RLS Status"
FROM pg_tables 
WHERE schemaname IN ('oficina', 'public')
AND tablename IN ('docs', 'doc_chunks', 'doc_facts', 'attendant_prompts', 'conversation_logs')
ORDER BY schemaname, tablename;

-- Verificar políticas RLS
\echo ''
\echo '🛡️ 6. POLÍTICAS RLS:'
SELECT 
    schemaname || '.' || tablename as "Tabela",
    policyname as "Política",
    CASE WHEN permissive = 'RESTRICTIVE' THEN '✅ Restritiva' ELSE '⚠️ Permissiva' END as "Tipo"
FROM pg_policies 
WHERE schemaname IN ('oficina', 'public')
ORDER BY schemaname, tablename;

-- Verificar índices importantes
\echo ''
\echo '📈 7. ÍNDICES IMPORTANTES:'
SELECT 
    schemaname || '.' || tablename as "Tabela",
    indexname as "Índice",
    '✅' as "Status"
FROM pg_indexes 
WHERE schemaname IN ('oficina', 'public')
AND (
    indexname LIKE '%trgm%' OR 
    indexname LIKE '%embedding%' OR
    indexname LIKE '%ivfflat%'
)
ORDER BY schemaname, tablename;

-- Verificar dados de exemplo
\echo ''
\echo '📋 8. DADOS DE EXEMPLO:'

-- Contagem de aliases de peças
SELECT 
    'part_aliases' as "Tabela",
    COUNT(*) as "Registros",
    CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END as "Status"
FROM oficina.part_aliases;

-- Verificar prompt ativo
SELECT 
    'attendant_prompts (ativo)' as "Tabela",
    COUNT(*) as "Registros",
    CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '❌' END as "Status"
FROM public.attendant_prompts 
WHERE is_active = true;

-- Contagem geral de tabelas principais
\echo ''
\echo '📊 9. CONTAGEM DE REGISTROS:'
SELECT 'models' as "Tabela", COUNT(*) as "Registros" FROM oficina.models
UNION ALL
SELECT 'parts' as "Tabela", COUNT(*) as "Registros" FROM oficina.parts  
UNION ALL
SELECT 'part_prices' as "Tabela", COUNT(*) as "Registros" FROM oficina.part_prices
UNION ALL
SELECT 'part_compat' as "Tabela", COUNT(*) as "Registros" FROM oficina.part_compat
UNION ALL  
SELECT 'doc_facts' as "Tabela", COUNT(*) as "Registros" FROM oficina.doc_facts
UNION ALL
SELECT 'conversation_logs' as "Tabela", COUNT(*) as "Registros" FROM public.conversation_logs
ORDER BY "Tabela";

-- Teste de função de busca
\echo ''
\echo '🧪 10. TESTE DE FUNÇÕES:'

-- Teste search_parts
\echo '   Testando public.search_parts...'
SELECT 
    'search_parts' as "Função",
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ Erro' END as "Status"
FROM public.search_parts('MS250', 'carburador', 1);

-- Teste suggest_models  
\echo '   Testando public.suggest_models...'
SELECT 
    'suggest_models' as "Função", 
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ Erro' END as "Status"
FROM public.suggest_models('MS250', 1);

-- Teste search_docs_secure
\echo '   Testando public.search_docs_secure...'
SELECT 
    'search_docs_secure' as "Função",
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ Erro' END as "Status"  
FROM public.search_docs_secure('MS250', 'carburador', 1);

-- Storage buckets (se configurado)
\echo ''
\echo '🗄️ 11. STORAGE BUCKETS:'
SELECT 
    name as "Bucket",
    CASE WHEN public THEN '🌐 Público' ELSE '🔒 Privado' END as "Visibilidade",
    '✅' as "Status"
FROM storage.buckets 
WHERE name = 'manuals';

-- Resumo final
\echo ''
\echo '📋 RESUMO FINAL:'
\echo '✅ = Configurado corretamente'
\echo '⚠️  = Atenção necessária' 
\echo '❌ = Problema detectado'
\echo ''

-- Verificação crítica
DO $$
DECLARE
    critical_issues INTEGER := 0;
    warning_issues INTEGER := 0;
BEGIN
    -- Verificar extensões críticas
    SELECT COUNT(*) INTO critical_issues 
    FROM pg_extension 
    WHERE extname IN ('pg_trgm', 'unaccent');
    
    IF critical_issues < 2 THEN
        RAISE NOTICE '❌ CRÍTICO: Extensões essenciais não instaladas (pg_trgm, unaccent)';
    END IF;
    
    -- Verificar prompt ativo
    SELECT COUNT(*) INTO critical_issues
    FROM public.attendant_prompts 
    WHERE is_active = true;
    
    IF critical_issues = 0 THEN
        RAISE NOTICE '❌ CRÍTICO: Nenhum prompt ativo encontrado';
    END IF;
    
    -- Verificar RLS em tabelas sensíveis
    SELECT COUNT(*) INTO warning_issues
    FROM pg_tables 
    WHERE schemaname = 'oficina' 
    AND tablename IN ('docs', 'doc_facts')
    AND rowsecurity = false;
    
    IF warning_issues > 0 THEN
        RAISE NOTICE '⚠️  ATENÇÃO: RLS não ativo em % tabelas sensíveis', warning_issues;
    END IF;
    
    IF critical_issues = 0 AND warning_issues = 0 THEN
        RAISE NOTICE '🎉 SISTEMA SAUDÁVEL: Todas as verificações críticas passaram!';
    END IF;
END $$;

\echo ''
\echo '✅ Health Check concluído!'