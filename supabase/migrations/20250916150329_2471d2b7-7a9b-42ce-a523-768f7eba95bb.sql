-- =============================================================================
-- STIHL Assistente Virtual - Configuração Completa do Banco de Dados
-- Executar apenas UMA VEZ na configuração inicial
-- =============================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS vector;

-- =============================================================================
-- SCHEMA OFICINA - Catálogo de peças e modelos
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS oficina;

-- -----------------------------------------------------------------------------
-- Tabela: models (modelos STIHL)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.models (
    id SERIAL PRIMARY KEY,
    model_code_std VARCHAR(50) NOT NULL,
    brand VARCHAR(20) DEFAULT 'STIHL' NOT NULL,
    category VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(brand, model_code_std)
);

-- -----------------------------------------------------------------------------
-- Tabela: parts (catálogo de peças)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.parts (
    part_code VARCHAR(50) PRIMARY KEY,
    description TEXT NOT NULL,
    category VARCHAR(100),
    extra JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índice trigram para busca por descrição
CREATE INDEX IF NOT EXISTS idx_parts_description_trgm 
ON oficina.parts USING GIN (description gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- Tabela: part_prices (preços das peças)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.part_prices (
    part_code VARCHAR(50) NOT NULL REFERENCES oficina.parts(part_code) ON DELETE CASCADE,
    price_brl DECIMAL(10,2) NOT NULL,
    price_list VARCHAR(50) DEFAULT 'sugerida' NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (part_code, price_list)
);

-- -----------------------------------------------------------------------------
-- Tabela: part_compat (compatibilidade peças x modelos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.part_compat (
    part_code VARCHAR(50) NOT NULL REFERENCES oficina.parts(part_code) ON DELETE CASCADE,
    model_id INTEGER NOT NULL REFERENCES oficina.models(id) ON DELETE CASCADE,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (part_code, model_id)
);

-- -----------------------------------------------------------------------------
-- Tabela: part_aliases (aliases/sinônimos de peças)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.part_aliases (
    id SERIAL PRIMARY KEY,
    alias VARCHAR(200) NOT NULL,
    canonical VARCHAR(200) NOT NULL,
    weight DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Índice trigram para busca de aliases
CREATE INDEX IF NOT EXISTS idx_part_aliases_alias_trgm 
ON oficina.part_aliases USING GIN (alias gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- Tabela: docs (metadados dos documentos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.docs (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    title VARCHAR(500),
    model_code VARCHAR(50),
    storage_path TEXT,
    page_count INTEGER,
    uploaded_at TIMESTAMPTZ DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- Tabela: doc_facts (fatos estruturados extraídos dos PDFs)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.doc_facts (
    id SERIAL PRIMARY KEY,
    doc_id INTEGER NOT NULL REFERENCES oficina.docs(id) ON DELETE CASCADE,
    page INTEGER NOT NULL,
    fact_type VARCHAR(50) DEFAULT 'part_info',
    model_code VARCHAR(50),
    part_code VARCHAR(50),
    part_desc TEXT,
    heading TEXT,
    item_number INTEGER,
    extra_data JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para busca eficiente
CREATE INDEX IF NOT EXISTS idx_doc_facts_model_code ON oficina.doc_facts (model_code);
CREATE INDEX IF NOT EXISTS idx_doc_facts_part_code ON oficina.doc_facts (part_code);
CREATE INDEX IF NOT EXISTS idx_doc_facts_part_desc_trgm 
ON oficina.doc_facts USING GIN (part_desc gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- Função: search_parts (busca principal de peças)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oficina.search_parts(
    model_q TEXT DEFAULT '',
    part_q TEXT DEFAULT '', 
    limit_n INTEGER DEFAULT 5
)
RETURNS TABLE(
    part_code VARCHAR,
    description TEXT,
    price_brl DECIMAL,
    model VARCHAR,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    WITH part_matches AS (
        SELECT DISTINCT
            p.part_code,
            p.description,
            pp.price_brl,
            COALESCE(
                CASE WHEN p.part_code ILIKE ('%' || part_q || '%') THEN 0.9
                     ELSE similarity(p.description, part_q)
                END, 0.0
            ) as similarity_score
        FROM oficina.parts p
        LEFT JOIN oficina.part_prices pp ON p.part_code = pp.part_code 
            AND pp.price_list = 'sugerida'
        WHERE (
            part_q = '' OR
            p.part_code ILIKE ('%' || part_q || '%') OR
            similarity(p.description, part_q) > 0.2
        )
    ),
    model_filtered AS (
        SELECT 
            pm.*,
            CASE 
                WHEN model_q = '' THEN 'Geral'
                ELSE COALESCE(m.model_code_std, 'Geral')
            END as model_match
        FROM part_matches pm
        LEFT JOIN oficina.part_compat pc ON pm.part_code = pc.part_code
        LEFT JOIN oficina.models m ON pc.model_id = m.id
        WHERE (
            model_q = '' OR
            m.model_code_std IS NULL OR
            m.model_code_std ILIKE ('%' || model_q || '%') OR
            similarity(m.model_code_std, model_q) > 0.3
        )
    )
    SELECT 
        mf.part_code::VARCHAR,
        mf.description,
        mf.price_brl,
        mf.model_match::VARCHAR,
        mf.similarity_score::REAL
    FROM model_filtered mf
    ORDER BY mf.similarity_score DESC, mf.price_brl ASC
    LIMIT limit_n;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER 
SET search_path = oficina, public;

-- -----------------------------------------------------------------------------
-- Função: suggest_models (sugestão de modelos)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oficina.suggest_models(
    q TEXT,
    limit_n INTEGER DEFAULT 3
)
RETURNS TABLE(
    model_code_std VARCHAR,
    category VARCHAR,
    similarity_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.model_code_std::VARCHAR,
        m.category::VARCHAR,
        GREATEST(
            similarity(m.model_code_std, q),
            CASE WHEN m.model_code_std ILIKE ('%' || q || '%') THEN 0.8 ELSE 0.0 END
        )::REAL as score
    FROM oficina.models m
    WHERE m.model_code_std ILIKE ('%' || q || '%') 
       OR similarity(m.model_code_std, q) > 0.2
    ORDER BY score DESC
    LIMIT limit_n;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER 
SET search_path = oficina, public;

-- -----------------------------------------------------------------------------
-- Função: search_docs_secure (busca segura em documentos)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oficina.search_docs_secure(
    model_q TEXT DEFAULT '',
    part_q TEXT DEFAULT '',
    top_k INTEGER DEFAULT 5
)
RETURNS TABLE(
    heading TEXT,
    item_number INTEGER,
    model_code VARCHAR,
    part_code VARCHAR,
    part_desc TEXT,
    page INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        df.heading,
        df.item_number,
        df.model_code::VARCHAR,
        df.part_code::VARCHAR,
        df.part_desc,
        df.page
    FROM oficina.doc_facts df
    WHERE (
        (model_q = '' OR df.model_code ILIKE ('%' || model_q || '%') 
                    OR similarity(df.model_code, model_q) > 0.3)
        AND 
        (part_q = '' OR df.part_code ILIKE ('%' || part_q || '%') 
                    OR df.part_desc ILIKE ('%' || part_q || '%')
                    OR similarity(df.part_desc, part_q) > 0.3)
    )
    ORDER BY 
        GREATEST(
            COALESCE(similarity(df.model_code, model_q), 0),
            COALESCE(similarity(df.part_desc, part_q), 0)
        ) DESC
    LIMIT top_k;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER 
SET search_path = oficina, public;

-- =============================================================================
-- WRAPPERS PÚBLICOS (Service Role apenas)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.search_parts(
    model_q TEXT DEFAULT '',
    part_q TEXT DEFAULT '',
    limit_n INTEGER DEFAULT 5
)
RETURNS TABLE(
    part_code VARCHAR,
    description TEXT,
    price_brl DECIMAL,
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

CREATE OR REPLACE FUNCTION public.search_docs_secure(
    model_q TEXT DEFAULT '',
    part_q TEXT DEFAULT '',
    top_k INTEGER DEFAULT 5
)
RETURNS TABLE(
    heading TEXT,
    item_number INTEGER,
    model_code VARCHAR,
    part_code VARCHAR,
    part_desc TEXT,
    page INTEGER
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = oficina, public
AS $function$;

CREATE OR REPLACE FUNCTION public.suggest_models(
    q TEXT,
    limit_n INTEGER DEFAULT 3
)
RETURNS TABLE(
    model_code_std VARCHAR,
    category VARCHAR,
    similarity_score REAL
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = oficina, public
AS $function$
BEGIN
    RETURN QUERY SELECT * FROM oficina.suggest_models(q, limit_n);
END;
$function$;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Habilitar RLS nas tabelas sensíveis
ALTER TABLE oficina.docs ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.doc_facts ENABLE ROW LEVEL SECURITY;

-- Políticas restritivas (negar acesso direto)
CREATE POLICY "Deny direct access to docs" ON oficina.docs FOR ALL USING (false);
CREATE POLICY "Deny direct access to doc_facts" ON oficina.doc_facts FOR ALL USING (false);

-- =============================================================================
-- SEEDS - Dados iniciais críticos
-- =============================================================================

-- Aliases de peças mais comuns
INSERT INTO oficina.part_aliases (alias, canonical, weight) VALUES
    ('anel de trava', 'anel de retenção', 1.0),
    ('anel de segurança', 'anel de retenção', 1.0),
    ('refil de fio', 'fio de nylon', 1.0),
    ('fio de roçadeira', 'fio de nylon', 1.0),
    ('kit reparo carburador', 'kit de reparo do carburador', 1.0),
    ('cabeçote roçadeira', 'cabeçote de corte', 1.0),
    ('cabecote rocadeira', 'cabeçote de corte', 1.0),
    ('pinhao', 'pinhão', 1.0),
    ('corrente de motosserra', 'corrente', 1.0)
ON CONFLICT DO NOTHING;

-- Prompt inicial do sistema  
INSERT INTO public.attendant_prompts (role, content, version, is_active) VALUES (
    'system',
    'Você é um especialista em peças e equipamentos STIHL. Responda sempre de forma humanizada, direta e prestativa, nunca como um robô.

REGRAS CRÍTICAS:
- NUNCA mencione: pdf, pdfs, manual, manuais, arquivo, arquivos, link, links, url, download, baixar
- Se não souber algo, seja honesto e ofereça atendimento humano
- Sempre priorize: preço em BRL, código da peça, descrição e modelos compatíveis
- Em caso de ambiguidade, faça UMA pergunta curta para esclarecer
- NÃO alucine informações - use apenas dados do catálogo

FORMATO DE RESPOSTA QUANDO HOUVER PREÇO:
"O valor do [peça] da [categoria/modelo] é R$ [valor]
Descrição: [descrição completa]
Código: [código]
Compatíveis: [lista de modelos]"

Seja sempre cordial e use linguagem natural brasileira.',
    '1.0',
    true
) ON CONFLICT DO NOTHING;

-- Finalizado
SELECT 'Configuração inicial do STIHL Assistente Virtual concluída!' as status;