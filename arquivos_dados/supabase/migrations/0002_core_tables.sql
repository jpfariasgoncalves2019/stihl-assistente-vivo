-- 0002_core_tables.sql

-- Normalized core
drop table if exists equipment_models cascade;
create table equipment_models (
  id uuid primary key default gen_random_uuid(),
  model_code text unique not null, -- e.g., 'MS 170', 'FS 55'
  family text not null,            -- 'motosserra','rocadeira','soprador', etc.
  display_name text,               -- marketing name, if any
  specs jsonb default '{}'::jsonb, -- arbitrary spec blob (cilindrada, potência, peso, conjunto_corte...)
  created_at timestamptz default now()
);

drop table if exists parts cascade;
create table parts (
  id uuid primary key default gen_random_uuid(),
  part_code text unique not null,     -- e.g., '1108-120-0613'
  description text not null,
  created_at timestamptz default now()
);

drop table if exists part_prices cascade;
create table part_prices (
  id uuid primary key default gen_random_uuid(),
  part_id uuid not null references parts(id) on delete cascade,
  price numeric not null,
  currency text not null default 'BRL',
  source text default 'planilha',
  valid_from date default current_date
);

drop table if exists part_model_compat cascade;
create table part_model_compat (
  part_id uuid not null references parts(id) on delete cascade,
  model_code text not null,
  primary key (part_id, model_code)
);

drop table if exists part_aliases cascade;
create table part_aliases (
  id uuid primary key default gen_random_uuid(),
  part_code text not null,
  alias text not null
);

drop table if exists model_aliases cascade;
create table model_aliases (
  id uuid primary key default gen_random_uuid(),
  model_code text not null,
  alias text not null
);

-- Prompt storage (avoid word 'bot')
drop table if exists assistant_prompts cascade;
create table assistant_prompts (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  persona text not null,       -- tone and style
  instructions text not null,  -- ground rules
  examples jsonb,              -- few-shot examples
  created_at timestamptz default now()
);

-- Conversation logs (no PII, minimal)
drop table if exists conversation_logs cascade;
create table conversation_logs (
  id bigserial primary key,
  channel text not null, -- web | telegram | whatsapp
  user_message text not null,
  resolved_part_code text,
  resolved_model_code text,
  answer_preview text,
  created_at timestamptz default now()
);