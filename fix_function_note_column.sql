-- =============================================================================
-- CORREÇÃO DA FUNÇÃO apply_part_compat_staging
-- =============================================================================

-- Recriar a função sem referência à coluna 'note'
CREATE OR REPLACE FUNCTION oficina.apply_part_compat_staging()
RETURNS INTEGER AS $$
DECLARE
    applied_count INTEGER := 0;
    staging_rec RECORD;
    model_id_found INTEGER;
BEGIN
    FOR staging_rec IN 
        SELECT DISTINCT part_code, model_code_std 
        FROM oficina.part_compat_staging
    LOOP
        -- Buscar model_id
        SELECT id INTO model_id_found 
        FROM oficina.models 
        WHERE oficina.norm_model(model_code_std) = oficina.norm_model(staging_rec.model_code_std)
        LIMIT 1;
        
        -- Se encontrou o modelo, inserir compatibilidade
        IF model_id_found IS NOT NULL THEN
            INSERT INTO oficina.part_compat (part_code, model_id)
            VALUES (staging_rec.part_code, model_id_found)
            ON CONFLICT (part_code, model_id) DO NOTHING;
            
            applied_count := applied_count + 1;
        END IF;
    END LOOP;
    
    -- Limpar staging
    DELETE FROM oficina.part_compat_staging;
    
    RETURN applied_count;
END;
$$ LANGUAGE plpgsql;
