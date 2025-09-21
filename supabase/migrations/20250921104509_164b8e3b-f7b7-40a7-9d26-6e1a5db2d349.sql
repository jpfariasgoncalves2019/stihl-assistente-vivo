-- Popular tabela sabres, correntes, pinhões e limas
-- Primeiro limpar dados existentes desta categoria se houver
DELETE FROM stg_sabres_correntes_pinhoes_limas;

-- Popular dados da tabela staging
COPY stg_sabres_correntes_pinhoes_limas(codigo_material, preco_real, descricao, modelos_maquinas) 
FROM STDIN WITH CSV HEADER;
3002-001-9223,369.84,"Sabre D 53cm/21"" 1,6mm/0.063""",MS08/051/076
3002-001-9231,425.04,"Sabre D 63cm/25"" 1,6mm/0.063"" 404""",MS051/076/08
3002-001-8041,491.28,"Sabre D 75cm/30"" 1,6mm/0.063""",MS051/076
3003-001-9207,259.44,"Sabre D 33cm/13"" 1,6mm/0.063"" 3/8""",MS310/361/260/362/382
3003-001-9213,298.09,"Sabre D 40cm/16"" 1,6mm/0.063"" 3/8""",MS310/362/382/460/650/660
3003-001-9221,353.29,"Sabre D 50cm/20"" 1,6mm/0.063""",MS034/038/066/460/650/660/362/382
3003-001-5631,425.04,"Sabre D 63cm/25"" 1,6mm/0.063""",MS460/650/660
3003-001-9241,491.28,"Sabre D 75cm/30"" 1,6mm/0.063""",MS064/066/650/660
3003-000-8453,694.79,"Sabre D 90cm/36"" 1,6mm/0.063""",MS651/661
3003-001-9406,282.45,"Sabre S 32cm/13"" 1,6mm/0.063"" 3/8""",MS310/260/361/382
3003-001-9413,312.99,"Sabre S 40cm/16"" 1,6mm/0.063"" 3/8""",MS310/260/361/362/382
3003-001-9421,370.92,"Sabre S 50cm/20"" 1,6mm/0.063"" 3/8""",MS310/260/361/362/382/460/650/660
3003-001-9431,446.29,"Sabre S 63cm/25"" 1,6mm/0.063"" 3/8""",M460/650/660
3003-001-6041,515.85,"Sabre S 75cm/30"" 1,6mm/0.063"" 3/8""",MS650/660
3005-000-3905,160.72,"Sabre R 30cm/12"" 1,1mm/0.043"" 3/8"" P",HT75/133/KA85R/KM55R/KM85R/MS170/MS180/180C/MS193T/MSE141
3005-003-3909,165.32,"Sabre R 35cm/14"" 1,1mm/0.043"" 3/8"" P",MS180/MS172
3003-008-6813,218.95,"Sabre R 40cm/16"" 1,6mm/0.063"" .325""",MS260
3003-000-5221,264.96,"Sabre R 50cm/20"" 1,6mm/0.063"" 3/8""",MS310/260/361/362/382/460/650/660
3005-008-3405,154.32,"Sabre L01 30cm/12"" 1,1mm/0.043"" 1/4""P",MSA120/160/200/160T/HTA85/HT133/HT75
3005-008-3409,187.95,"Sabre L01 35cm/14"" 1,1mm/0.043"" 1/4""P",MSA200
3005-000-4413,212.91,"Sabre L04 40cm/16"" 1,1mm/0.043"" 3/8"" P",MSA 220.0 C-B
3005-000-4805,187.95,"Sabre L04 30cm/12"" 1,3mm/0.050"" 3/8""P",MS210/230/250/MSE170/HT70K
3005-000-4809,193.2,"Sabre L04 35cm/14"" 1,3mm/0.050"" 3/8""P",MS210/230/250/MSE170/MSA220
3005-000-4813,212.91,"Sabre L04 40cm/16"" 1,3mm/0.050"" 3/8""P",MS/182/210/212/230/250/MSE170
3003-000-5306,219.44,"Sabre L04 32cm/13"" 1,6mm/0.063"" .325""",MS260
3005-000-4817,235.02,"Sabre L04 45cm/18"" 1,3mm/0.050"" 3/8""P",MS212
3003-000-5213,240.45,"Sabre L06 40cm/16"" 1,6mm/0.063"" 3/8""",MS310/260/361/362/382/460/650/660
3003-000-5231,318.77,"Sabre L06 63cm/25"" 1,6mm/0.063"" 3/8""",MS460/650/660
3007-003-0101,72.44,"Sabre L 10cm/4"" 1,1mm/0.043""",GTA 26
3005-008-4905,168.99,"Sabre L 30cm/12"" 1,1mm/0.043""",MS162
3003-008-3317,232.61,"Sabre L04 45cm/18"" 1,3mm/0.050"" .325""",MSA300.0
3003-008-3321,252.31,"Sabre L04 50cm/20"" 1,3mm/0.050"" .325""",MSA300.0
3005-000-3105,286.24,"Sabre C 30cm/12"" 1,1mm/0.043"" 1/4"" P",
3003-650-2551,133.25,"Cabeça do sabre 3/8"" 11Z 1,6","Novos Sabres Rollomatic Super - 32/40/50/63/75cm (1,6mm)"
3003-650-9922,85.09,"Estrela reversora 3/8"" 10Z 1,6",MS361/381
3003-650-9935,85.09,"Estrela reversora 3/8 11Z 1,6","Novos Sabres Rollomatic Super - 32/40/50/63/75cm (1,6mm)"
3005-650-9903,85.09,"Estrela reversora 9d 1,3",MS011/025
0000-974-0503,3.48,Rebite de cabeça embutida,MS034/038/066
3651-000-1640,2797.68,35 RM Rapid Micro Rolo de corrente,
\.

-- Estender a função apply_part_compat_staging para processar stg_sabres_correntes_pinhoes_limas
CREATE OR REPLACE FUNCTION apply_sabres_correntes_staging()
RETURNS text
LANGUAGE plpgsql
AS $function$
DECLARE
    rec RECORD;
    part_id_var UUID;
    model_codes TEXT[];
    model_code_var TEXT;
    processed_count INTEGER := 0;
BEGIN
    -- Processar dados de stg_sabres_correntes_pinhoes_limas
    FOR rec IN SELECT codigo_material, preco_real, descricao, modelos_maquinas 
               FROM stg_sabres_correntes_pinhoes_limas 
               WHERE codigo_material IS NOT NULL AND trim(codigo_material) != ''
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
            -- Verificar se já existe preço para hoje
            IF NOT EXISTS (SELECT 1 FROM part_prices WHERE part_id = part_id_var AND valid_from = CURRENT_DATE AND source = 'sabres_staging') THEN
                INSERT INTO part_prices (part_id, price, currency, source, valid_from)
                VALUES (part_id_var, rec.preco_real, 'BRL', 'sabres_staging', CURRENT_DATE);
            END IF;
        END IF;
        
        -- Processar compatibilidades de modelos se houver
        IF rec.modelos_maquinas IS NOT NULL AND trim(rec.modelos_maquinas) != '' THEN
            model_codes := string_to_array(replace(rec.modelos_maquinas, ' ', ''), '/');
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

    RETURN 'Processados ' || processed_count || ' registros de sabres, correntes, pinhões e limas.';
END;
$function$;

-- Executar a função para popular as tabelas principais
SELECT apply_sabres_correntes_staging();