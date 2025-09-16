-- Configurar secrets necessários primeiro
-- Este comando só funciona se OPENAI_API_KEY ainda não existir

-- Inserir dados mínimos para teste
INSERT INTO oficina.models (model_code_std, brand, category) VALUES
    ('MS250', 'STIHL', 'Motosserra'),
    ('FS55', 'STIHL', 'Roçadeira'),
    ('MS08', 'STIHL', 'Motosserra')
ON CONFLICT (brand, model_code_std) DO NOTHING;

-- Inserir algumas peças de exemplo
INSERT INTO oficina.parts (part_code, description, category) VALUES
    ('1108-120-0613', 'Carburador LA-S8A', 'Carburador'),
    ('4228/15', 'Carburador 4228/15', 'Carburador'),
    ('1123-030-0408', 'Virabrequim', 'Motor')
ON CONFLICT (part_code) DO NOTHING;

-- Inserir preços de exemplo
INSERT INTO oficina.part_prices (part_code, price_brl, price_list) VALUES
    ('1108-120-0613', 302.07, 'sugerida'),
    ('4228/15', 128.91, 'sugerida'),
    ('1123-030-0408', 368.84, 'sugerida')
ON CONFLICT (part_code, price_list) DO NOTHING;

-- Criar compatibilidades básicas
INSERT INTO oficina.part_compat (part_code, model_id) 
SELECT '1108-120-0613', id FROM oficina.models WHERE model_code_std = 'MS08'
ON CONFLICT DO NOTHING;

INSERT INTO oficina.part_compat (part_code, model_id) 
SELECT '4228/15', id FROM oficina.models WHERE model_code_std = 'FS55'
ON CONFLICT DO NOTHING;

INSERT INTO oficina.part_compat (part_code, model_id) 
SELECT '1123-030-0408', id FROM oficina.models WHERE model_code_std = 'MS250'
ON CONFLICT DO NOTHING;