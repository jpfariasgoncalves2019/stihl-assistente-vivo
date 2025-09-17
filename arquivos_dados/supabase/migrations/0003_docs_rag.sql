-- 0003_docs_rag.sql
-- Private storage bucket for PDFs (no public links)
-- Run with service role or postgres
select storage.create_bucket('tech_docs', public => false);

drop table if exists docs cascade;
create table docs (
  id uuid primary key default gen_random_uuid(),
  source_path text not null,         -- storage path (bucket key)
  filename text not null,
  model_code text,                   -- optional: MS 170, FS 55...
  checksum text not null,
  page_count int,
  created_at timestamptz default now(),
  unique (checksum)
);

drop table if exists doc_chunks cascade;
create table doc_chunks (
  id uuid primary key default gen_random_uuid(),
  doc_id uuid not null references docs(id) on delete cascade,
  page_number int not null,
  chunk_index int not null,
  content text not null,               -- stored securely; never exposed to clients
  embedding vector(1536),              -- adjust dimension to the embedding model used
  token_count int,
  created_at timestamptz default now(),
  unique (doc_id, page_number, chunk_index)
);

-- Helper view exposing ONLY minimal metadata (no text, no paths)
drop view if exists doc_public_view;
create view doc_public_view as
  select d.id as doc_id, d.model_code, d.page_count, d.created_at
  from docs d;

-- RPC to semantic search chunks (server-side usage only)
drop function if exists match_doc_chunks(text, int);
create function match_doc_chunks(query_embedding vector(1536), match_count int default 5)
returns table(
  doc_id uuid,
  page_number int,
  chunk_index int,
  similarity float4
)
language sql stable parallel safe as $$
  select c.doc_id, c.page_number, c.chunk_index,
         1 - (c.embedding <=> query_embedding) as similarity
  from doc_chunks c
  order by c.embedding <-> query_embedding
  limit match_count;
$$;