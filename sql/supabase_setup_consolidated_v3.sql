-- =============================================================================
-- STIHL Assistente Virtual - Configuração Completa do Banco de Dados
-- Arquivo: sql/supabase_setup_consolidated_v3.sql
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
-- Tabela: model_specs (especificações técnicas dos modelos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.model_specs (
    model_id INTEGER NOT NULL REFERENCES oficina.models(id) ON DELETE CASCADE,
    displacement_cc DECIMAL(6,2),
    power_kw DECIMAL(6,2),
    weight_kg DECIMAL(6,2),
    cutting_set VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (model_id)
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
-- Tabela: part_compat_staging (staging para import via CSV)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.part_compat_staging (
    id SERIAL PRIMARY KEY,
    part_code VARCHAR(50) NOT NULL,
    model_code_std VARCHAR(50) NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
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
-- Tabela: model_aliases (aliases/sinônimos de modelos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.model_aliases (
    id SERIAL PRIMARY KEY,
    alias VARCHAR(200) NOT NULL,
    model_id INTEGER NOT NULL REFERENCES oficina.models(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Índice trigram para busca de aliases de modelos
CREATE INDEX IF NOT EXISTS idx_model_aliases_alias_trgm 
ON oficina.model_aliases USING GIN (alias gin_trgm_ops);

-- =============================================================================
-- SCHEMA RAG SEGURO - Documentos técnicos (PDFs)
-- =============================================================================

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
-- Tabela: doc_chunks (chunks vetorizados dos documentos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS oficina.doc_chunks (
    id SERIAL PRIMARY KEY,
    doc_id INTEGER NOT NULL REFERENCES oficina.docs(id) ON DELETE CASCADE,
    page_number INTEGER NOT NULL,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    embedding VECTOR(1536), -- OpenAI ada-002 embeddings
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para busca vetorial
CREATE INDEX IF NOT EXISTS idx_doc_chunks_embedding_ivfflat 
ON oficina.doc_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

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

-- =============================================================================
-- FUNÇÕES AUXILIARES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Função: norm_text (normalização de texto)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oficina.norm_text(input_text TEXT)
RETURNS TEXT AS $$
BEGIN
    IF input_text IS NULL THEN
        RETURN '';
    END IF;
    
    RETURN TRIM(UPPER(unaccent(input_text)));
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- -----------------------------------------------------------------------------
-- Função: norm_model (normalização de códigos de modelo)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oficina.norm_model(model_code TEXT)
RETURNS TEXT AS $$
BEGIN
    IF model_code IS NULL THEN
        RETURN '';
    END IF;
    
    -- Remove espaços e normaliza
    RETURN TRIM(UPPER(REGEXP_REPLACE(model_code, '\s+', '', 'g')));
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- -----------------------------------------------------------------------------
-- Função: expand_terms (expansão via aliases)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oficina.expand_terms(query_text TEXT)
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := query_text;
    alias_rec RECORD;
BEGIN
    IF query_text IS NULL OR query_text = '' THEN
        RETURN '';
    END IF;

    -- Expande aliases de peças
    FOR alias_rec IN 
        SELECT DISTINCT canonical 
        FROM oficina.part_aliases 
        WHERE similarity(alias, query_text) > 0.3
        ORDER BY similarity(alias, query_text) DESC
        LIMIT 3
    LOOP
        result_text := result_text || ' ' || alias_rec.canonical;
    END LOOP;

    RETURN result_text;
END;
$$ LANGUAGE plpgsql STABLE;

-- -----------------------------------------------------------------------------
-- Função: apply_part_compat_staging (aplicar staging de compatibilidade)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION oficina.apply_part_compat_staging()
RETURNS INTEGER AS $$
DECLARE
    applied_count INTEGER := 0;
    staging_rec RECORD;
    model_id_found INTEGER;
BEGIN
    FOR staging_rec IN 
        SELECT DISTINCT part_code, model_code_std, note 
        FROM oficina.part_compat_staging
    LOOP
        -- Buscar model_id
        SELECT id INTO model_id_found 
        FROM oficina.models 
        WHERE oficina.norm_model(model_code_std) = oficina.norm_model(staging_rec.model_code_std)
        LIMIT 1;
        
        -- Se encontrou o modelo, inserir compatibilidade
        IF model_id_found IS NOT NULL THEN
            INSERT INTO oficina.part_compat (part_code, model_id, note)
            VALUES (staging_rec.part_code, model_id_found, staging_rec.note)
            ON CONFLICT (part_code, model_id) DO UPDATE SET
                note = EXCLUDED.note;
            
            applied_count := applied_count + 1;
        END IF;
    END LOOP;
    
    -- Limpar staging
    DELETE FROM oficina.part_compat_staging;
    
    RETURN applied_count;
END;
$$ LANGUAGE plpgsql;

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
    WITH expanded_query AS (
        SELECT 
            oficina.expand_terms(part_q) AS expanded_part_q,
            oficina.norm_model(model_q) AS normalized_model_q
    ),
    part_matches AS (
        SELECT DISTINCT
            p.part_code,
            p.description,
            pp.price_brl,
            COALESCE(
                CASE WHEN p.part_code ~* ('^' || part_q || '$') THEN 1.0
                     WHEN p.part_code ILIKE ('%' || part_q || '%') THEN 0.8
                     ELSE similarity(p.description, (SELECT expanded_part_q FROM expanded_query))
                END, 0.0
            ) as similarity_score
        FROM oficina.parts p
        LEFT JOIN oficina.part_prices pp ON p.part_code = pp.part_code 
            AND pp.price_list = 'sugerida'
        CROSS JOIN expanded_query eq
        WHERE (
            part_q = '' OR
            p.part_code ILIKE ('%' || part_q || '%') OR
            similarity(p.description, eq.expanded_part_q) > 0.2
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
        CROSS JOIN expanded_query eq
        WHERE (
            model_q = '' OR
            m.model_code_std IS NULL OR
            oficina.norm_model(m.model_code_std) = eq.normalized_model_q OR
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
    WITH model_matches AS (
        -- Busca direta em models
        SELECT 
            m.model_code_std,
            m.category,
            GREATEST(
                similarity(m.model_code_std, q),
                CASE WHEN m.model_code_std ILIKE ('%' || q || '%') THEN 0.8 ELSE 0.0 END
            ) as score
        FROM oficina.models m
        WHERE m.model_code_std ILIKE ('%' || q || '%') 
           OR similarity(m.model_code_std, q) > 0.2
        
        UNION ALL
        
        -- Busca via aliases
        SELECT 
            m.model_code_std,
            m.category,
            similarity(ma.alias, q) as score
        FROM oficina.model_aliases ma
        JOIN oficina.models m ON ma.model_id = m.id
        WHERE similarity(ma.alias, q) > 0.3
    )
    SELECT 
        mm.model_code_std::VARCHAR,
        mm.category::VARCHAR,
        MAX(mm.score)::REAL
    FROM model_matches mm
    GROUP BY mm.model_code_std, mm.category
    ORDER BY MAX(mm.score) DESC
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

-- -----------------------------------------------------------------------------
-- Wrapper: public.search_parts
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- Wrapper: public.search_docs_secure
-- -----------------------------------------------------------------------------
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
AS $function$
BEGIN
    RETURN QUERY SELECT * FROM oficina.search_docs_secure(model_q, part_q, top_k);
END;
$function$;

-- -----------------------------------------------------------------------------
-- Wrapper: public.suggest_models
-- -----------------------------------------------------------------------------
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
-- SCHEMA PÚBLICO - Prompts e Logs
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Função auxiliar para timestamps automáticos
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- Tabela: attendant_prompts (prompts do assistente)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.attendant_prompts (
    id SERIAL PRIMARY KEY,
    role VARCHAR(20) DEFAULT 'system',
    content TEXT NOT NULL,
    version VARCHAR(10) DEFAULT '1.0',
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger para updated_at
DROP TRIGGER IF EXISTS update_attendant_prompts_updated_at ON public.attendant_prompts;
CREATE TRIGGER update_attendant_prompts_updated_at
    BEFORE UPDATE ON public.attendant_prompts
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- Tabela: conversation_logs (logs das conversas)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversation_logs (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT now(),
    channel VARCHAR(20),
    user_ref_hash VARCHAR(64), -- SHA-256 do sender
    prompt_id INTEGER REFERENCES public.attendant_prompts(id),
    prompt_version VARCHAR(10),
    user_message TEXT, -- Mascarado (URLs/telefones removidos)
    model_detected VARCHAR(100),
    part_query TEXT,
    catalog_evidence JSONB, -- Resumo das evidências do catálogo
    tech_evidence JSONB,    -- Resumo das evidências técnicas
    response_text TEXT,
    took_ms INTEGER,
    error TEXT
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_conversation_logs_created_at 
ON public.conversation_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversation_logs_channel 
ON public.conversation_logs (channel);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Habilitar RLS nas tabelas sensíveis
ALTER TABLE oficina.docs ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.doc_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.doc_facts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendant_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_logs ENABLE ROW LEVEL SECURITY;

-- Políticas restritivas (negar acesso direto)
DROP POLICY IF EXISTS "Deny direct access to docs" ON oficina.docs;
CREATE POLICY "Deny direct access to docs" ON oficina.docs
    FOR ALL USING (false);

DROP POLICY IF EXISTS "Deny direct access to doc_chunks" ON oficina.doc_chunks;
CREATE POLICY "Deny direct access to doc_chunks" ON oficina.doc_chunks
    FOR ALL USING (false);

DROP POLICY IF EXISTS "Deny direct access to doc_facts" ON oficina.doc_facts;
CREATE POLICY "Deny direct access to doc_facts" ON oficina.doc_facts
    FOR ALL USING (false);

DROP POLICY IF EXISTS "Deny direct access to attendant_prompts" ON public.attendant_prompts;
CREATE POLICY "Deny direct access to attendant_prompts" ON public.attendant_prompts
    FOR ALL USING (false);

DROP POLICY IF EXISTS "Deny direct access to conversation_logs" ON public.conversation_logs;
CREATE POLICY "Deny direct access to conversation_logs" ON public.conversation_logs
    FOR ALL USING (false);

-- =============================================================================
-- SEEDS - Dados iniciais
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Aliases de peças mais comuns
-- -----------------------------------------------------------------------------
INSERT INTO oficina.part_aliases (alias, canonical, weight) VALUES
    ('anel de trava', 'anel de retenção', 1.0),
    ('anel de segurança', 'anel de retenção', 1.0),
    ('snap ring', 'anel de retenção', 0.8),
    ('circlip', 'anel de retenção', 0.8),
    ('refil de fio', 'fio de nylon', 1.0),
    ('fio de roçadeira', 'fio de nylon', 1.0),
    ('kit reparo carburador', 'kit de reparo do carburador', 1.0),
    ('cabeçote roçadeira', 'cabeçote de corte', 1.0),
    ('cabecote rocadeira', 'cabeçote de corte', 1.0),
    ('autocut', 'cabeçote autocut', 1.0),
    ('trimcut', 'cabeçote trimcut', 1.0),
    ('policut', 'cabeçote policut', 1.0),
    ('pinhao', 'pinhão', 1.0),
    ('coroa', 'coroa dentada', 1.0),
    ('corrente de motosserra', 'corrente', 1.0)
ON CONFLICT DO NOTHING;

-- -----------------------------------------------------------------------------
-- Prompt inicial do sistema
-- -----------------------------------------------------------------------------
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

FORMATO PARA MÚLTIPLAS OPÇÕES:
Liste cada item com:
- Código:
- Preço:
- Descrição:
- Informações técnicas (quando disponível):
  * Cilindrada [cm³]:
  * Potência:
  * Peso:
  * Conjunto de corte:

Seja sempre cordial e use linguagem natural brasileira.',
    '1.0',
    true
) ON CONFLICT DO NOTHING;

-- =============================================================================
-- COMENTÁRIOS FINAIS
-- =============================================================================
COMMENT ON SCHEMA oficina IS 'Schema principal para catálogo de peças e documentos STIHL';
COMMENT ON TABLE oficina.models IS 'Modelos de equipamentos STIHL';
COMMENT ON TABLE oficina.parts IS 'Catálogo de peças STIHL';
COMMENT ON TABLE oficina.part_compat IS 'Compatibilidade entre peças e modelos';
COMMENT ON TABLE oficina.doc_facts IS 'Fatos estruturados extraídos dos PDFs técnicos';
COMMENT ON TABLE public.attendant_prompts IS 'Prompts do assistente virtual';
COMMENT ON TABLE public.conversation_logs IS 'Logs das conversas com mascaramento de PII';

-- Finalizado
SELECT 'Configuração do banco STIHL Assistente Virtual concluída com sucesso!' as status;