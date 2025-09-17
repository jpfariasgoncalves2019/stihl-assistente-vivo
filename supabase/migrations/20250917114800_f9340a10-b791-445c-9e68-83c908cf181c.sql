-- 0004_rls_policies.sql

-- Enable RLS everywhere
alter table equipment_models enable row level security;
alter table parts enable row level security;
alter table part_prices enable row level security;
alter table part_model_compat enable row level security;
alter table part_aliases enable row level security;
alter table model_aliases enable row level security;
alter table assistant_prompts enable row level security;
alter table conversation_logs enable row level security;
alter table docs enable row level security;
alter table doc_chunks enable row level security;

-- Default: no one sees anything (service_role bypasses RLS).
-- Allow inserts to conversation_logs from authenticated users if needed, else service_role only.
create policy "conversation_logs_insert_auth" on conversation_logs
for insert to authenticated with check (true);

-- Absolutely no selects on docs and doc_chunks for non-service roles.
create policy "docs_no_select" on docs for select to authenticated using (false);
create policy "doc_chunks_no_select" on doc_chunks for select to authenticated using (false);

-- No selects on assistant_prompts either (front-ends don't fetch it directly)
create policy "assistant_prompts_no_select" on assistant_prompts for select to authenticated using (false);