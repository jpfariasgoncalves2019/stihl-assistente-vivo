-- Corrigir a função apply_part_compat_staging para resolver ambiguidade de model_code
CREATE OR REPLACE FUNCTION public.apply_part_compat_staging()
RETURNS text
LANGUAGE plpgsql
AS $function$
DECLARE
    rec RECORD;
    part_id_var UUID;
    model_codes TEXT[];
    model_code_var TEXT;  -- Renomeado para evitar ambiguidade
    processed_count INTEGER := 0;
BEGIN
    -- Processar dados de stg_pecas
    FOR rec IN SELECT codigo_material, preco_real, descricao, modelos_compativeis FROM stg_pecas WHERE codigo_material IS NOT NULL
    LOOP
        -- Inserir ou atualizar parte
        INSERT INTO parts (part_code, description)
        VALUES (rec.codigo_material, rec.descricao)
        ON CONFLICT (part_code) DO UPDATE SET description = EXCLUDED.description
        RETURNING id INTO part_id_var;
        
        -- Se não conseguiu o ID do INSERT, buscar o existente
        IF part_id_var IS NULL THEN
            SELECT id INTO part_id_var FROM parts WHERE part_code = rec.codigo_material;
        END IF;
        
        -- Inserir preço se existir (sem conflict handling)
        IF rec.preco_real IS NOT NULL THEN
            -- Verificar se já existe preço para hoje
            IF NOT EXISTS (SELECT 1 FROM part_prices WHERE part_id = part_id_var AND valid_from = CURRENT_DATE AND source = 'staging') THEN
                INSERT INTO part_prices (part_id, price, currency, source, valid_from)
                VALUES (part_id_var, rec.preco_real, 'BRL', 'staging', CURRENT_DATE);
            END IF;
        END IF;
        
        -- Processar compatibilidades de modelos
        IF rec.modelos_compativeis IS NOT NULL THEN
            model_codes := string_to_array(replace(rec.modelos_compativeis, ' ', ''), '/');
            FOREACH model_code_var IN ARRAY model_codes
            LOOP
                IF trim(model_code_var) != '' THEN
                    INSERT INTO part_model_compat (part_id, model_code)
                    VALUES (part_id_var, trim(model_code_var))
                    ON CONFLICT (part_id, model_code) DO NOTHING;
                END IF;
            END LOOP;
        END IF;
        
        processed_count := processed_count + 1;
    END LOOP;

    -- Processar stg_motossera
    FOR rec IN SELECT codigo_material, preco_real, descricao, modelos_compativeis FROM stg_motossera WHERE codigo_material IS NOT NULL
    LOOP
        INSERT INTO parts (part_code, description)
        VALUES (rec.codigo_material, rec.descricao)
        ON CONFLICT (part_code) DO UPDATE SET description = EXCLUDED.description
        RETURNING id INTO part_id_var;
        
        IF part_id_var IS NULL THEN
            SELECT id INTO part_id_var FROM parts WHERE part_code = rec.codigo_material;
        END IF;
        
        IF rec.preco_real IS NOT NULL THEN
            IF NOT EXISTS (SELECT 1 FROM part_prices WHERE part_id = part_id_var AND valid_from = CURRENT_DATE AND source = 'staging') THEN
                INSERT INTO part_prices (part_id, price, currency, source, valid_from)
                VALUES (part_id_var, rec.preco_real, 'BRL', 'staging', CURRENT_DATE);
            END IF;
        END IF;
        
        IF rec.modelos_compativeis IS NOT NULL THEN
            model_codes := string_to_array(replace(rec.modelos_compativeis, ' ', ''), '/');
            FOREACH model_code_var IN ARRAY model_codes
            LOOP
                IF trim(model_code_var) != '' THEN
                    INSERT INTO part_model_compat (part_id, model_code)
                    VALUES (part_id_var, trim(model_code_var))
                    ON CONFLICT (part_id, model_code) DO NOTHING;
                END IF;
            END LOOP;
        END IF;
        
        processed_count := processed_count + 1;
    END LOOP;

    -- Processar stg_ro_adeiras_e_implementos
    FOR rec IN SELECT codigo_material, preco_real, descricao, modelos_compativeis FROM stg_ro_adeiras_e_implementos WHERE codigo_material IS NOT NULL
    LOOP
        INSERT INTO parts (part_code, description)
        VALUES (rec.codigo_material, rec.descricao)
        ON CONFLICT (part_code) DO UPDATE SET description = EXCLUDED.description
        RETURNING id INTO part_id_var;
        
        IF part_id_var IS NULL THEN
            SELECT id INTO part_id_var FROM parts WHERE part_code = rec.codigo_material;
        END IF;
        
        IF rec.preco_real IS NOT NULL THEN
            IF NOT EXISTS (SELECT 1 FROM part_prices WHERE part_id = part_id_var AND valid_from = CURRENT_DATE AND source = 'staging') THEN
                INSERT INTO part_prices (part_id, price, currency, source, valid_from)
                VALUES (part_id_var, rec.preco_real, 'BRL', 'staging', CURRENT_DATE);
            END IF;
        END IF;
        
        IF rec.modelos_compativeis IS NOT NULL THEN
            model_codes := string_to_array(replace(rec.modelos_compativeis, ' ', ''), '/');
            FOREACH model_code_var IN ARRAY model_codes
            LOOP
                IF trim(model_code_var) != '' THEN
                    INSERT INTO part_model_compat (part_id, model_code)
                    VALUES (part_id_var, trim(model_code_var))
                    ON CONFLICT (part_id, model_code) DO NOTHING;
                END IF;
            END LOOP;
        END IF;
        
        processed_count := processed_count + 1;
    END LOOP;
    
    RETURN 'Processados ' || processed_count || ' registros das tabelas staging para as tabelas principais.';
END;
$function$;

-- Agora executar a população das tabelas staging e processamento
INSERT INTO stg_pecas (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('1108-120-0600', 302.07, 'Carburador LA-S8A', 'MS08'),
('1108-120-0613', 128.91, 'Carburador 4228/15', 'FS38/55/55R'),
('1123-030-0408', 368.84, 'Virabrequim', 'MS025/230/250'),
('0000-007-1043', 74.97, 'Jogo de parafusos', 'MS310/390/046/460/SR420/BR600'),
('0000-007-1300', 1.77, 'Kit Anel de vedação redondo N 4x2-EPDM70', 'FS55/80/85/120/130/160/220/280/290/300/350/FR220/350'),
('3005-000-4813', 89.90, 'Sabre Rollomatic E 35cm/14" 3/8"P 1,6mm', 'MS170/180/210/230/250'),
('3624-005-0072', 45.30, 'Corrente Picco Micro 3 (PM3) 3/8"P 1,1mm', 'MS170/180/MS162'),
('1121-640-2000', 25.40, 'Pinhão 3/8"P-6', 'MS170/180/MS162'),
('4001-007-1027', 15.90, 'Cabeça de corte AutoCut 25-2', 'FS55/80/120/130'),
('4002-713-3064', 8.50, 'Fio Redondo 2,4mm 87m', 'FS55/80/120/130/160/220');

INSERT INTO stg_motossera (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('1148-200-0249', 1199.00, 'MS 162 Motosserra', 'MS162'),
('1148-200-0244', 1399.00, 'MS 172 Motosserra', 'MS172'),
('1140-200-0607', 1899.00, 'MS 250 Motosserra', 'MS250'),
('1141-200-0617', 2499.00, 'MS 290 Motosserra', 'MS290');

INSERT INTO stg_ro_adeiras_e_implementos (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('4128-200-0623', 459.00, 'FS 38 Roçadeira', 'FS38'),
('4137-200-0613', 569.00, 'FS 55 Roçadeira', 'FS55'),
('4140-200-0613', 899.00, 'FS 80 Roçadeira', 'FS80'),
('4144-200-0615', 1299.00, 'FS 120 Roçadeira', 'FS120');

-- Executar a função de processamento
SELECT apply_part_compat_staging();