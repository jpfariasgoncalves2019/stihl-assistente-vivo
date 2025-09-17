-- =============================================================================
-- COMPLETAR POPULAÇÃO DE DADOS - STIHL ASSISTENTE VIRTUAL
-- =============================================================================

-- Limpar dados existentes para repovoar completamente (ordem correta para FK)
DELETE FROM oficina.part_compat;
DELETE FROM oficina.model_aliases;
DELETE FROM oficina.model_specs;
DELETE FROM oficina.part_prices;
DELETE FROM oficina.parts;
DELETE FROM oficina.models;

-- Resetar sequences
ALTER SEQUENCE oficina.models_id_seq RESTART WITH 1;

-- =============================================================================
-- MODELOS STIHL COMPLETOS
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
('BG45', 'STIHL', 'Soprador'),
('BG55', 'STIHL', 'Soprador'),
('BG85', 'STIHL', 'Soprador')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- ESPECIFICAÇÕES TÉCNICAS
-- =============================================================================

INSERT INTO oficina.model_specs (model_id, displacement_cc, power_kw, weight_kg, cutting_set) 
SELECT m.id, specs.displacement_cc, specs.power_kw, specs.weight_kg, specs.cutting_set
FROM oficina.models m
JOIN (VALUES
    ('MS08', 25.4, 1.0, 2.6, 'Barra 30cm + Corrente .325"'),
    ('MS025', 45.4, 1.8, 4.4, 'Barra 35cm + Corrente .325"'),
    ('MS230', 40.2, 1.7, 4.6, 'Barra 35cm + Corrente .325"'),
    ('MS250', 45.4, 2.3, 4.6, 'Barra 40cm + Corrente .325"'),
    ('MS290', 56.5, 2.8, 5.9, 'Barra 45cm + Corrente 3/8"'),
    ('MS390', 64.1, 3.4, 6.0, 'Barra 45cm + Corrente 3/8"'),
    ('MS440', 70.7, 4.0, 6.3, 'Barra 50cm + Corrente .404"'),
    ('MS460', 76.5, 4.4, 6.6, 'Barra 50cm + Corrente .404"'),
    ('FS38', 27.2, 0.65, 4.1, 'Cabeçote AutoCut'),
    ('FS45', 27.2, 0.75, 4.4, 'Cabeçote AutoCut'),
    ('FS55', 27.2, 0.75, 4.9, 'Cabeçote AutoCut'),
    ('FS55R', 27.2, 0.75, 5.1, 'Cabeçote AutoCut'),
    ('FS80', 27.2, 0.9, 5.6, 'Cabeçote TrimCut'),
    ('FS85', 27.2, 0.9, 5.6, 'Cabeçote TrimCut'),
    ('FS120', 30.8, 1.1, 6.8, 'Cabeçote PolyCut'),
    ('FS200', 35.2, 1.3, 7.4, 'Cabeçote PolyCut'),
    ('BG45', 27.2, 0.75, 4.1, 'Tubo soprador'),
    ('BG55', 27.2, 0.75, 4.4, 'Tubo soprador'),
    ('BG85', 27.2, 0.9, 7.5, 'Tubo soprador')
) AS specs(model_code, displacement_cc, power_kw, weight_kg, cutting_set)
ON m.model_code_std = specs.model_code
ON CONFLICT DO NOTHING;

-- Verificar população de modelos
SELECT 'MODELOS INSERIDOS' as status, COUNT(*) as total FROM oficina.models;
