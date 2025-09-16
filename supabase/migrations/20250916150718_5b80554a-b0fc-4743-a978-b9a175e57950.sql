-- Corrigir tipos de retorno nas funções SQL para compatibilidade TypeScript

-- Corrigir function oficina.search_parts
DROP FUNCTION IF EXISTS oficina.search_parts(TEXT, TEXT, INTEGER);
CREATE OR REPLACE FUNCTION oficina.search_parts(
    model_q TEXT DEFAULT '',
    part_q TEXT DEFAULT '', 
    limit_n INTEGER DEFAULT 5
)
RETURNS TABLE(
    part_code VARCHAR,
    description TEXT,
    price_brl NUMERIC,
    model VARCHAR,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        p.part_code::VARCHAR,
        p.description::TEXT,
        pp.price_brl::NUMERIC,
        COALESCE(m.model_code_std, 'Geral')::VARCHAR,
        CASE 
            WHEN p.part_code ILIKE ('%' || part_q || '%') THEN 0.9::REAL
            WHEN part_q != '' AND similarity(p.description, part_q) > 0.2 THEN similarity(p.description, part_q)::REAL
            ELSE 0.5::REAL
        END as rank
    FROM oficina.parts p
    LEFT JOIN oficina.part_prices pp ON p.part_code = pp.part_code 
        AND pp.price_list = 'sugerida'
    LEFT JOIN oficina.part_compat pc ON p.part_code = pc.part_code
    LEFT JOIN oficina.models m ON pc.model_id = m.id
    WHERE (
        part_q = '' OR
        p.part_code ILIKE ('%' || part_q || '%') OR
        p.description ILIKE ('%' || part_q || '%') OR
        similarity(p.description, part_q) > 0.2
    ) AND (
        model_q = '' OR
        m.model_code_std IS NULL OR
        m.model_code_std ILIKE ('%' || model_q || '%') OR
        similarity(m.model_code_std, model_q) > 0.3
    )
    ORDER BY rank DESC, pp.price_brl ASC NULLS LAST
    LIMIT limit_n;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = oficina, public;

-- Recriar wrapper público
DROP FUNCTION IF EXISTS public.search_parts(TEXT, TEXT, INTEGER);
CREATE OR REPLACE FUNCTION public.search_parts(
    model_q TEXT DEFAULT '',
    part_q TEXT DEFAULT '',
    limit_n INTEGER DEFAULT 5
)
RETURNS TABLE(
    part_code VARCHAR,
    description TEXT,
    price_brl NUMERIC,
    model VARCHAR,
    rank REAL
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = oficina, public
AS $function$
BEGIN
    RETURN QUERY SELECT * FROM oficina.search_parts(model_q, part_q, limit_n);
END;
$function$;