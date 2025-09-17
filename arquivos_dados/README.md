# Atendente STIHL (IA) — Setup Completo

> **Premissa:** atendimento 100% humanizado. **Nunca** enviar links, PDFs, nem mencionar "manual". Os PDFs servem **apenas** como base interna (RAG).

## 0) Requisitos
- Supabase CLI e projeto ativo
- Node/Deno (Edge Functions do Supabase usam Deno)
- Chave da OpenAI (com embeddings)

## 1) Estrutura de pastas
```
stihl-assistant/
├─ supabase/
│  └─ migrations/
│     ├─ 0001_extensions.sql
│     ├─ 0002_core_tables.sql
│     ├─ 0003_docs_rag.sql
│     ├─ 0004_rls_policies.sql
│     ├─ 0005_rpcs.sql
│     ├─ 0006_seed_aliases.sql
│     ├─ 0007_seed_assistant_prompt.sql
│     └─ 0008_staging_tables.sql
├─ data/
│  └─ csv/  (CSVs gerados da planilha)
├─ functions/
│  ├─ chat/
│  │  ├─ index.ts
│  │  └─ sanitizers.ts
│  └─ ingest/
│     └─ index.ts
├─ .env.local (exemplo em .env.example)
├─ deno.json
└─ Makefile
```

## 2) Banco de dados
1. Configure `.env.local` com as suas chaves (ver `.env.example`).
2. Rode as migrações:
   ```bash
   supabase db push --env-file .env.local
   ```

## 3) Importar planilha (CSVs)
Os CSVs gerados já estão em `data/csv`. Para popular _staging_ e depois normalizar:

```bash
make seed
```

> **Transformação para o modelo normalizado:** após importar `stg_pecas`, rode:
```sql
-- Inserir peças (parts) e preços (part_prices)
insert into parts (part_code, description)
select distinct codigo_material, descricao
from stg_pecas
where codigo_material is not null and descricao is not null
on conflict (part_code) do nothing;

insert into part_prices (part_id, price, currency)
select p.id, s.preco_real::numeric, 'BRL'
from stg_pecas s
join parts p on p.part_code = s.codigo_material
where s.preco_real ~ '^[0-9]+(\.[0-9]+)?$';

-- Compatibilidades (part_model_compat)
insert into part_model_compat (part_id, model_code)
select p.id, unnest(split_models(s.modelos_compativeis))
from stg_pecas s
join parts p on p.part_code = s.codigo_material
where s.modelos_compativeis is not null;
```

Se desejar, popule `equipment_models` a partir das abas de máquinas (roçadeiras, motosserras, etc.) usando _staging_ como base.

## 4) Buckets e RAG (privado)
- As migrações criam o bucket **tech_docs** privado e as tabelas `docs` e `doc_chunks`.
- Faça upload dos PDFs para `tech_docs` (UI do Supabase ou Storage API).
- Suba e rode a função de **ingestão**:
  ```bash
  supabase functions deploy ingest --no-verify-jwt
  curl -X POST "$SUPABASE_URL/functions/v1/ingest" -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "Content-Type: application/json" -d '{"prefix":""}'
  ```
  Isso indexa os PDFs **sem expor** conteúdo externamente.

## 5) Função `/chat`
- Deploy:
  ```bash
  supabase functions deploy chat --no-verify-jwt
  ```
- Chamada de exemplo:
  ```bash
  curl -s -X POST "$SUPABASE_URL/functions/v1/chat" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" -H "Content-Type: application/json" \
    -d '{"message":"Qual preço do carburador da FS55?","channel":"web"}'
  ```

## 6) Sanitização e estilo
- `sanitizers.ts` remove links e termos proibidos (pdf/manual).
- O _prompt_ principal está em `assistant_prompts` e já inserido nas seeds. Ajuste se desejar.

## 7) Exemplos de consultas (esperado)
- "Qual o valr do carburador da 08 ?"
  > O valor do carburador da Motosserra MS08 é R$ 302,07\nDescrição: Carburador LA-S8A\nCódigo: 1108-120-0613
- "Qual preço do carburador da fS55 ?"
  > O valor do carburador da Roçadeira FS55 é R$ 128,91\nDescrição: Carburador 4228/15\nCódigo: 1108-120-0613\nModelos compatíveis: FS38/55/55R
- "QUal valor do virabrequim da motosserra Ms 250?"
  > O valor do virabrequim da Motosserra MS250 é R$ 368,84\nDescrição: Virabrequim\nCódigo: 1123-030-0408\nModelos compatíveis: MS025/230/250
- "Qual valor da roçadeira FS80 ?"
  > Listar 3 opções com Código / Preço / Descrição e Informações Técnicas (Cilindrada [cm³], Potência, Peso, Conjunto de corte).

## 8) Observações importantes
- **RLS**: somente _service role_ (Edge Function) consegue ler `docs`/`doc_chunks`. Nenhum cliente tem acesso.
- **Sem alucinação**: se não houver dado, responda com transparência.
- **Sem links/PDFs**: bloqueado no sanitizador e no prompt.