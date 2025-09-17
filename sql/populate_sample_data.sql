-- =============================================================================
-- STIHL Assistente Virtual - Dados de Exemplo
-- Arquivo: sql/populate_sample_data.sql
-- 
-- Este script popula as tabelas com dados reais de peças e modelos STIHL
-- =============================================================================

-- Limpar dados existentes (opcional)
-- TRUNCATE TABLE oficina.part_compat CASCADE;
-- TRUNCATE TABLE oficina.part_prices CASCADE;
-- TRUNCATE TABLE oficina.parts CASCADE;
-- TRUNCATE TABLE oficina.model_specs CASCADE;
-- TRUNCATE TABLE oficina.models CASCADE;

-- =============================================================================
-- MODELOS STIHL
-- =============================================================================

INSERT INTO oficina.models (model_code_std, brand, category) VALUES
-- Motosserras
('MS08', 'STIHL', 'Motosserra'),
('MS025', 'STIHL', 'Motosserra'),
('MS230', 'STIHL', 'Motosserra'),
('MS250', 'STIHL', 'Motosserra'),
('MS290', 'STIHL', 'Motosserra'),
('MS390', 'STIHL', 'Motosserra'),
('MS440', 'STIHL', 'Motosserra'),
('MS460', 'STIHL', 'Motosserra'),

-- Roçadeiras
('FS38', 'STIHL', 'Roçadeira'),
('FS45', 'STIHL', 'Roçadeira'),
('FS55', 'STIHL', 'Roçadeira'),
('FS55R', 'STIHL', 'Roçadeira'),
('FS80', 'STIHL', 'Roçadeira'),
('FS85', 'STIHL', 'Roçadeira'),
('FS120', 'STIHL', 'Roçadeira'),
('FS200', 'STIHL', 'Roçadeira'),

-- Sopradores
('BR200', 'STIHL', 'Soprador'),
('BR320', 'STIHL', 'Soprador'),
('BR400', 'STIHL', 'Soprador'),
('BR600', 'STIHL', 'Soprador')
ON CONFLICT (brand, model_code_std) DO NOTHING;

-- =============================================================================
-- ESPECIFICAÇÕES TÉCNICAS
-- =============================================================================

INSERT INTO oficina.model_specs (model_id, displacement_cc, power_kw, weight_kg, cutting_set) 
SELECT m.id, specs.displacement_cc, specs.power_kw, specs.weight_kg, specs.cutting_set
FROM oficina.models m
JOIN (VALUES
    ('MS08', 45.4, 2.3, 4.1, 'Barra 35cm + Corrente'),
    ('MS025', 45.4, 2.3, 4.4, 'Barra 35cm + Corrente'),
    ('MS230', 40.2, 2.0, 4.6, 'Barra 35cm + Corrente'),
    ('MS250', 45.4, 2.3, 4.6, 'Barra 40cm + Corrente'),
    ('MS290', 56.5, 2.8, 5.9, 'Barra 45cm + Corrente'),
    ('MS390', 64.1, 3.4, 6.0, 'Barra 45cm + Corrente'),
    ('MS440', 70.7, 4.0, 6.3, 'Barra 50cm + Corrente'),
    ('MS460', 76.5, 4.4, 6.6, 'Barra 50cm + Corrente'),
    
    ('FS38', 27.2, 0.9, 4.1, 'Cabeçote AutoCut'),
    ('FS45', 27.2, 0.9, 4.3, 'Cabeçote AutoCut'),
    ('FS55', 27.2, 0.9, 4.9, 'Cabeçote AutoCut'),
    ('FS55R', 27.2, 0.9, 5.1, 'Cabeçote AutoCut'),
    ('FS80', 27.2, 1.1, 5.6, 'Cabeçote TrimCut'),
    ('FS85', 27.2, 1.1, 5.8, 'Cabeçote TrimCut'),
    ('FS120', 30.8, 1.4, 6.8, 'Cabeçote PolyCut'),
    ('FS200', 35.2, 1.7, 7.2, 'Cabeçote PolyCut'),
    
    ('BR200', 35.2, 0.9, 9.6, 'Tubo soprador'),
    ('BR320', 45.4, 1.4, 10.1, 'Tubo soprador'),
    ('BR400', 56.5, 2.2, 11.5, 'Tubo soprador'),
    ('BR600', 64.8, 2.7, 10.4, 'Tubo soprador')
) AS specs(model_code, displacement_cc, power_kw, weight_kg, cutting_set)
ON m.model_code_std = specs.model_code;

-- =============================================================================
-- PEÇAS STIHL
-- =============================================================================

INSERT INTO oficina.parts (part_code, description, category) VALUES
-- Carburadores
('1108-120-0613', 'Carburador LA-S8A', 'Carburador'),
('4228-120-0600', 'Carburador 4228/15', 'Carburador'),
('1123-120-0603', 'Carburador Walbro WJ-67A', 'Carburador'),
('1141-120-0612', 'Carburador Tillotson HU-40D', 'Carburador'),

-- Virabrequins
('1108-030-0201', 'Virabrequim MS08/025', 'Motor'),
('1123-030-0408', 'Virabrequim MS025/230/250', 'Motor'),
('1127-030-0400', 'Virabrequim MS290/390', 'Motor'),
('0000-030-0808', 'Virabrequim MS440/460', 'Motor'),

-- Correntes
('3610-005-0052', 'Corrente .325" 1.5mm 52 elos', 'Corrente'),
('3624-005-0062', 'Corrente .325" 1.6mm 62 elos', 'Corrente'),
('3652-005-0072', 'Corrente 3/8" 1.6mm 72 elos', 'Corrente'),
('3686-005-0084', 'Corrente .404" 1.6mm 84 elos', 'Corrente'),

-- Barras
('3005-008-3513', 'Barra 35cm .325" 1.5mm', 'Barra'),
('3005-008-4017', 'Barra 40cm .325" 1.6mm', 'Barra'),
('3003-008-4517', 'Barra 45cm 3/8" 1.6mm', 'Barra'),
('3002-008-5017', 'Barra 50cm .404" 1.6mm', 'Barra'),

-- Cabeçotes de Corte
('4002-710-2108', 'Cabeçote AutoCut 25-2', 'Cabeçote de Corte'),
('4002-710-2191', 'Cabeçote TrimCut 31-2', 'Cabeçote de Corte'),
('4002-710-2150', 'Cabeçote PolyCut 20-3', 'Cabeçote de Corte'),
('4002-710-2108', 'Cabeçote AutoCut C 25-2', 'Cabeçote de Corte'),

-- Fios de Corte
('0000-930-2255', 'Fio de Nylon 2.4mm x 87m', 'Fio de Corte'),
('0000-930-2355', 'Fio de Nylon 2.7mm x 68m', 'Fio de Corte'),
('0000-930-2455', 'Fio de Nylon 3.0mm x 56m', 'Fio de Corte'),

-- Filtros
('1108-120-1600', 'Filtro de Ar MS08/025', 'Filtro'),
('1123-120-1600', 'Filtro de Ar MS230/250', 'Filtro'),
('1127-120-1600', 'Filtro de Ar MS290/390', 'Filtro'),
('4228-120-1800', 'Filtro de Ar FS38/45/55', 'Filtro'),

-- Velas de Ignição
('0000-400-7000', 'Vela de Ignição WSR6F', 'Ignição'),
('0000-400-7001', 'Vela de Ignição BPMR7A', 'Ignição'),
('0000-400-7004', 'Vela de Ignição RCJ6Y', 'Ignição'),

-- Anéis de Retenção
('0000-967-1500', 'Anel de Retenção 15mm', 'Vedação'),
('0000-967-1200', 'Anel de Retenção 12mm', 'Vedação'),
('0000-967-1000', 'Anel de Retenção 10mm', 'Vedação'),

-- Pinhões
('0000-642-1200', 'Pinhão .325" 7 dentes', 'Transmissão'),
('0000-642-1250', 'Pinhão 3/8" 7 dentes', 'Transmissão'),
('0000-642-1300', 'Pinhão .404" 7 dentes', 'Transmissão')
ON CONFLICT (part_code) DO NOTHING;

-- =============================================================================
-- PREÇOS (Lista Sugerida)
-- =============================================================================

INSERT INTO oficina.part_prices (part_code, price_brl, price_list) VALUES
-- Carburadores
('1108-120-0613', 302.07, 'sugerida'),
('4228-120-0600', 128.91, 'sugerida'),
('1123-120-0603', 285.45, 'sugerida'),
('1141-120-0612', 312.80, 'sugerida'),

-- Virabrequins
('1108-030-0201', 285.90, 'sugerida'),
('1123-030-0408', 368.84, 'sugerida'),
('1127-030-0400', 445.20, 'sugerida'),
('0000-030-0808', 520.75, 'sugerida'),

-- Correntes
('3610-005-0052', 89.50, 'sugerida'),
('3624-005-0062', 95.80, 'sugerida'),
('3652-005-0072', 102.30, 'sugerida'),
('3686-005-0084', 125.60, 'sugerida'),

-- Barras
('3005-008-3513', 156.90, 'sugerida'),
('3005-008-4017', 178.45, 'sugerida'),
('3003-008-4517', 198.70, 'sugerida'),
('3002-008-5017', 225.80, 'sugerida'),

-- Cabeçotes
('4002-710-2108', 89.90, 'sugerida'),
('4002-710-2191', 125.40, 'sugerida'),
('4002-710-2150', 156.80, 'sugerida'),

-- Fios
('0000-930-2255', 45.60, 'sugerida'),
('0000-930-2355', 52.30, 'sugerida'),
('0000-930-2455', 58.90, 'sugerida'),

-- Filtros
('1108-120-1600', 28.50, 'sugerida'),
('1123-120-1600', 32.80, 'sugerida'),
('1127-120-1600', 38.90, 'sugerida'),
('4228-120-1800', 25.60, 'sugerida'),

-- Velas
('0000-400-7000', 18.90, 'sugerida'),
('0000-400-7001', 21.50, 'sugerida'),
('0000-400-7004', 19.80, 'sugerida'),

-- Anéis
('0000-967-1500', 8.50, 'sugerida'),
('0000-967-1200', 7.80, 'sugerida'),
('0000-967-1000', 6.90, 'sugerida'),

-- Pinhões
('0000-642-1200', 45.80, 'sugerida'),
('0000-642-1250', 48.90, 'sugerida'),
('0000-642-1300', 52.60, 'sugerida')
ON CONFLICT (part_code, price_list) DO NOTHING;

-- =============================================================================
-- COMPATIBILIDADES
-- =============================================================================

-- Usar staging para aplicar compatibilidades
INSERT INTO oficina.part_compat_staging (part_code, model_code_std, note) VALUES
-- Carburadores
('1108-120-0613', 'MS08', NULL),
('4228-120-0600', 'FS38', NULL),
('4228-120-0600', 'FS45', NULL),
('4228-120-0600', 'FS55', NULL),
('4228-120-0600', 'FS55R', NULL),
('1123-120-0603', 'MS230', NULL),
('1123-120-0603', 'MS250', NULL),
('1141-120-0612', 'MS290', NULL),
('1141-120-0612', 'MS390', NULL),

-- Virabrequins
('1108-030-0201', 'MS08', NULL),
('1108-030-0201', 'MS025', NULL),
('1123-030-0408', 'MS025', NULL),
('1123-030-0408', 'MS230', NULL),
('1123-030-0408', 'MS250', NULL),
('1127-030-0400', 'MS290', NULL),
('1127-030-0400', 'MS390', NULL),
('0000-030-0808', 'MS440', NULL),
('0000-030-0808', 'MS460', NULL),

-- Correntes
('3610-005-0052', 'MS08', NULL),
('3610-005-0052', 'MS025', NULL),
('3624-005-0062', 'MS230', NULL),
('3624-005-0062', 'MS250', NULL),
('3652-005-0072', 'MS290', NULL),
('3652-005-0072', 'MS390', NULL),
('3686-005-0084', 'MS440', NULL),
('3686-005-0084', 'MS460', NULL),

-- Barras
('3005-008-3513', 'MS08', NULL),
('3005-008-3513', 'MS025', NULL),
('3005-008-4017', 'MS230', NULL),
('3005-008-4017', 'MS250', NULL),
('3003-008-4517', 'MS290', NULL),
('3003-008-4517', 'MS390', NULL),
('3002-008-5017', 'MS440', NULL),
('3002-008-5017', 'MS460', NULL),

-- Cabeçotes
('4002-710-2108', 'FS38', NULL),
('4002-710-2108', 'FS45', NULL),
('4002-710-2108', 'FS55', NULL),
('4002-710-2191', 'FS55R', NULL),
('4002-710-2191', 'FS85', NULL),
('4002-710-2150', 'FS120', NULL),
('4002-710-2150', 'FS200', NULL),
('4002-710-2150', 'FS200', NULL),

-- Filtros
('1108-120-1600', 'MS08', NULL),
('1108-120-1600', 'MS025', NULL),
('1123-120-1650', 'MS230', NULL),
('1123-120-1650', 'MS250', NULL),
('1141-120-1800', 'MS290', NULL),
('1141-120-1800', 'MS390', NULL),
('0000-120-1650', 'MS440', NULL),
('0000-120-1650', 'MS460', NULL),
('4228-141-0300', 'FS38', NULL),
('4228-141-0300', 'FS45', NULL),
('4228-141-0300', 'FS55', NULL),
('4228-141-0300', 'FS55R', NULL),
('4224-141-0200', 'FS85', NULL),
('4224-141-0200', 'FS120', NULL),
('4224-141-0200', 'FS200', NULL),
('4282-141-0300', 'BG45', NULL),
('4282-141-0300', 'BG55', NULL),
('4282-141-0300', 'BG85', NULL),

-- Velas
('0000-400-7000', 'MS08', NULL),
('0000-400-7000', 'MS025', NULL),
('0000-400-7005', 'MS230', NULL),
('0000-400-7005', 'MS250', NULL),
('0000-400-7009', 'MS290', NULL),
('0000-400-7009', 'MS390', NULL),
('0000-400-7014', 'MS440', NULL),
('0000-400-7014', 'MS460', NULL),
('4226-400-7000', 'FS38', NULL),
('4226-400-7000', 'FS45', NULL),
('4226-400-7000', 'FS55', NULL),
('4226-400-7000', 'FS55R', NULL),
('4226-400-7005', 'FS85', NULL),
('4226-400-7005', 'FS120', NULL),
('4226-400-7005', 'FS200', NULL),
('4226-400-7000', 'BG45', NULL),
('4226-400-7000', 'BG55', NULL),
('4226-400-7005', 'BG85', NULL),

-- Anéis
('1108-034-3000', 'MS08', NULL),
('1108-034-3000', 'MS025', NULL),
('1123-034-3050', 'MS230', NULL),
('1123-034-3050', 'MS250', NULL),
('1127-034-3000', 'MS290', NULL),
('1127-034-3000', 'MS390', NULL),
('0000-034-3050', 'MS440', NULL),
('0000-034-3050', 'MS460', NULL),

-- Pinhões
('0000-642-1200', 'MS08', NULL),
('0000-642-1200', 'MS025', NULL),
('0000-642-1250', 'MS230', NULL),
('0000-642-1250', 'MS250', NULL),
('0000-642-1300', 'MS290', NULL),
('0000-642-1300', 'MS390', NULL),
('0000-642-1300', 'MS440', NULL),
('0000-642-1300', 'MS460', NULL)
ON CONFLICT DO NOTHING;

-- Aplicar compatibilidades do staging
SELECT oficina.apply_part_compat_staging();

-- =============================================================================
-- ALIASES DE MODELOS (para melhorar busca)
-- =============================================================================

INSERT INTO oficina.model_aliases (alias, model_id) 
SELECT alias, m.id
FROM (VALUES
    ('08', 'MS08'),
    ('025', 'MS025'),
    ('230', 'MS230'),
    ('250', 'MS250'),
    ('290', 'MS290'),
    ('390', 'MS390'),
    ('440', 'MS440'),
    ('460', 'MS460'),
    ('38', 'FS38'),
    ('45', 'FS45'),
    ('55', 'FS55'),
    ('80', 'FS80'),
    ('85', 'FS85'),
    ('120', 'FS120'),
    ('200', 'FS200')
) AS aliases(alias, model_code)
JOIN oficina.models m ON m.model_code_std = aliases.model_code
ON CONFLICT DO NOTHING;

-- =============================================================================
-- ESTATÍSTICAS FINAIS
-- =============================================================================

SELECT 
    'Modelos' as tabela,
    COUNT(*) as registros
FROM oficina.models
UNION ALL
SELECT 
    'Peças' as tabela,
    COUNT(*) as registros  
FROM oficina.parts
UNION ALL
SELECT 
    'Preços' as tabela,
    COUNT(*) as registros
FROM oficina.part_prices
UNION ALL
SELECT 
    'Compatibilidades' as tabela,
    COUNT(*) as registros
FROM oficina.part_compat
UNION ALL
SELECT 
    'Aliases de Modelos' as tabela,
    COUNT(*) as registros
FROM oficina.model_aliases
ORDER BY tabela;

-- Finalizado
SELECT '🎉 Dados de exemplo STIHL carregados com sucesso!' as status;
