-- =============================================================================
-- LIMPEZA COMPLETA E REPOPULAÇÃO - STIHL ASSISTENTE VIRTUAL
-- =============================================================================

-- Desabilitar temporariamente as verificações de FK para limpeza
SET session_replication_role = replica;

-- Limpar todas as tabelas na ordem correta
TRUNCATE oficina.part_compat RESTART IDENTITY CASCADE;
TRUNCATE oficina.model_aliases RESTART IDENTITY CASCADE;
TRUNCATE oficina.model_specs RESTART IDENTITY CASCADE;
TRUNCATE oficina.part_prices RESTART IDENTITY CASCADE;
TRUNCATE oficina.parts RESTART IDENTITY CASCADE;
TRUNCATE oficina.models RESTART IDENTITY CASCADE;

-- Reabilitar verificações de FK
SET session_replication_role = DEFAULT;

-- =============================================================================
-- INSERIR APENAS OS MODELOS BÁSICOS PARA TESTE
-- =============================================================================

INSERT INTO oficina.models (model_code_std, brand, category) VALUES
('MS250', 'STIHL', 'Motosserra'),
('FS55', 'STIHL', 'Roçadeira'),
('BG55', 'STIHL', 'Soprador')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- INSERIR ALGUMAS PEÇAS BÁSICAS
-- =============================================================================

INSERT INTO oficina.parts (part_code, description, category) VALUES
('1123-120-0603', 'Carburador Walbro WJ-67A', 'Carburador'),
('4002-710-2108', 'Cabeçote AutoCut 25-2', 'Cabeçote de Corte'),
('0000-400-7005', 'Vela de Ignição NGK CMR6H', 'Vela')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- INSERIR PREÇOS BÁSICOS
-- =============================================================================

INSERT INTO oficina.part_prices (part_code, price_brl, price_list) VALUES
('1123-120-0603', 285.50, 'sugerida'),
('4002-710-2108', 125.80, 'sugerida'),
('0000-400-7005', 28.90, 'sugerida')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- INSERIR COMPATIBILIDADES BÁSICAS
-- =============================================================================

INSERT INTO oficina.part_compat_staging (part_code, model_code_std) VALUES
('1123-120-0603', 'MS250'),
('4002-710-2108', 'FS55'),
('0000-400-7005', 'MS250'),
('0000-400-7005', 'FS55'),
('0000-400-7005', 'BG55')
ON CONFLICT DO NOTHING;

-- Aplicar compatibilidades
SELECT oficina.apply_part_compat_staging();

-- =============================================================================
-- VERIFICAÇÃO FINAL
-- =============================================================================

SELECT 
    'models' as tabela, COUNT(*) as registros FROM oficina.models
UNION ALL
SELECT 
    'parts' as tabela, COUNT(*) as registros FROM oficina.parts
UNION ALL  
SELECT 
    'part_prices' as tabela, COUNT(*) as registros FROM oficina.part_prices
UNION ALL
SELECT 
    'part_compat' as tabela, COUNT(*) as registros FROM oficina.part_compat;

SELECT 'Dados básicos inseridos com sucesso!' as status;
