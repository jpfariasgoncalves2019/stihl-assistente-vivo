-- =============================================================================
-- CORREÇÃO DA FUNÇÃO expand_terms
-- =============================================================================

-- Recriar a função expand_terms corrigindo o ORDER BY
CREATE OR REPLACE FUNCTION oficina.expand_terms(query_text TEXT)
RETURNS TEXT AS $$
DECLARE
    expanded_terms TEXT := query_text;
    alias_rec RECORD;
BEGIN
    -- Se não há query, retornar vazio
    IF query_text IS NULL OR trim(query_text) = '' THEN
        RETURN '';
    END IF;
    
    -- Buscar aliases similares e incluir no ORDER BY
    FOR alias_rec IN 
        SELECT DISTINCT canonical, similarity(alias, query_text) as sim_score
        FROM oficina.part_aliases 
        WHERE similarity(alias, query_text) > 0.3
        ORDER BY sim_score DESC
        LIMIT 3
    LOOP
        expanded_terms := expanded_terms || ' ' || alias_rec.canonical;
    END LOOP;
    
    RETURN expanded_terms;
END;
$$ LANGUAGE plpgsql STABLE;
