-- =============================================================================
-- CORREÇÃO RÁPIDA PARA DADOS DUPLICADOS
-- =============================================================================

-- Limpar apenas as tabelas com FK para evitar conflitos
TRUNCATE oficina.part_compat RESTART IDENTITY CASCADE;
TRUNCATE oficina.model_aliases RESTART IDENTITY CASCADE;
TRUNCATE oficina.model_specs RESTART IDENTITY CASCADE;
TRUNCATE oficina.part_prices RESTART IDENTITY CASCADE;

-- Verificar contagem atual
SELECT 
    'models' as tabela, COUNT(*) as registros FROM oficina.models
UNION ALL
SELECT 
    'parts' as tabela, COUNT(*) as registros FROM oficina.parts
UNION ALL  
SELECT 
    'model_specs' as tabela, COUNT(*) as registros FROM oficina.model_specs
UNION ALL
SELECT 
    'part_prices' as tabela, COUNT(*) as registros FROM oficina.part_prices
UNION ALL
SELECT 
    'part_compat' as tabela, COUNT(*) as registros FROM oficina.part_compat;
