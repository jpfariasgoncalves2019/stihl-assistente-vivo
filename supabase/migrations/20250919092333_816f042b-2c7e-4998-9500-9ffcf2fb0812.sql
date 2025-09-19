-- Criar função para processar dados de staging e popular tabelas principais
CREATE OR REPLACE FUNCTION apply_part_compat_staging()
RETURNS TEXT AS $$
DECLARE
    rec RECORD;
    part_id_var UUID;
    model_codes TEXT[];
    model_code TEXT;
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
        
        -- Inserir preço se existir
        IF rec.preco_real IS NOT NULL THEN
            INSERT INTO part_prices (part_id, price, currency, source, valid_from)
            VALUES (part_id_var, rec.preco_real, 'BRL', 'staging', CURRENT_DATE)
            ON CONFLICT (part_id, valid_from) DO UPDATE SET price = EXCLUDED.price;
        END IF;
        
        -- Processar compatibilidades de modelos
        IF rec.modelos_compativeis IS NOT NULL THEN
            model_codes := string_to_array(replace(rec.modelos_compativeis, ' ', ''), '/');
            FOREACH model_code IN ARRAY model_codes
            LOOP
                IF trim(model_code) != '' THEN
                    INSERT INTO part_model_compat (part_id, model_code)
                    VALUES (part_id_var, trim(model_code))
                    ON CONFLICT (part_id, model_code) DO NOTHING;
                END IF;
            END LOOP;
        END IF;
        
        processed_count := processed_count + 1;
    END LOOP;

    -- Processar outros staging tables de forma similar
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
            INSERT INTO part_prices (part_id, price, currency, source, valid_from)
            VALUES (part_id_var, rec.preco_real, 'BRL', 'staging', CURRENT_DATE)
            ON CONFLICT (part_id, valid_from) DO UPDATE SET price = EXCLUDED.price;
        END IF;
        
        IF rec.modelos_compativeis IS NOT NULL THEN
            model_codes := string_to_array(replace(rec.modelos_compativeis, ' ', ''), '/');
            FOREACH model_code IN ARRAY model_codes
            LOOP
                IF trim(model_code) != '' THEN
                    INSERT INTO part_model_compat (part_id, model_code)
                    VALUES (part_id_var, trim(model_code))
                    ON CONFLICT (part_id, model_code) DO NOTHING;
                END IF;
            END LOOP;
        END IF;
        
        processed_count := processed_count + 1;
    END LOOP;

    -- Processar outras tabelas staging (produtos_a_bateria, outras_maquinas, etc.)
    FOR rec IN SELECT codigo_material, preco_real, descricao, modelos_compativeis FROM stg_produtos_a_bateria WHERE codigo_material IS NOT NULL
    LOOP
        INSERT INTO parts (part_code, description)
        VALUES (rec.codigo_material, rec.descricao)
        ON CONFLICT (part_code) DO UPDATE SET description = EXCLUDED.description
        RETURNING id INTO part_id_var;
        
        IF part_id_var IS NULL THEN
            SELECT id INTO part_id_var FROM parts WHERE part_code = rec.codigo_material;
        END IF;
        
        IF rec.preco_real IS NOT NULL THEN
            INSERT INTO part_prices (part_id, price, currency, source, valid_from)
            VALUES (part_id_var, rec.preco_real, 'BRL', 'staging', CURRENT_DATE)
            ON CONFLICT (part_id, valid_from) DO UPDATE SET price = EXCLUDED.price;
        END IF;
        
        IF rec.modelos_compativeis IS NOT NULL THEN
            model_codes := string_to_array(replace(rec.modelos_compativeis, ' ', ''), '/');
            FOREACH model_code IN ARRAY model_codes
            LOOP
                IF trim(model_code) != '' THEN
                    INSERT INTO part_model_compat (part_id, model_code)
                    VALUES (part_id_var, trim(model_code))
                    ON CONFLICT (part_id, model_code) DO NOTHING;
                END IF;
            END LOOP;
        END IF;
        
        processed_count := processed_count + 1;
    END LOOP;
    
    RETURN 'Processados ' || processed_count || ' registros das tabelas staging para as tabelas principais.';
END;
$$ LANGUAGE plpgsql;