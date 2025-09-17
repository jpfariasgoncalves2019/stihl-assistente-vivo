-- 0005_rpcs.sql

-- Simple tokenizer/normalizer in SQL (Portuguese-friendly)
drop function if exists normalize_text(text);
create function normalize_text(t text) returns text language sql immutable as $$
  select
    lower(
      translate(
        regexp_replace(t, '\s+', ' ', 'g'),
        'ÁÂÃÀÄáâãàäÉÊÈËéêèëÍÎÌÏíîìïÓÔÕÒÖóôõòöÚÛÙÜúûùüÇç',
        'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCc'
      )
    )
$$;

-- Split message into words
drop function if exists tokenize(text);
create function tokenize(t text) returns text[] language sql immutable as $$
  select regexp_split_to_array(normalize_text(t), '[^a-z0-9]+');
$$;

-- Resolve model aliases to model_code (best-effort)
drop function if exists resolve_model(text);
create function resolve_model(q text) returns text language plpgsql stable as $$
declare
  tok text[] := tokenize(q);
  candidate text;
begin
  -- try exact alias match
  select model_code into candidate
  from model_aliases
  where alias = any(tok)
  limit 1;
  if candidate is not null then return candidate; end if;

  -- try pattern like ms170, ms 170, fs55 etc
  select regexp_replace(m, '(ms|fs|br|bg|ts)\s*(\d+[a-z\-]*)', '\1 \2')
  from regexp_matches(normalize_text(q), '(ms|fs|br|bg|ts)\s*([0-9a-z\-]+)') as r(m, x)
  limit 1
  into candidate;
  return candidate;
end $$;

-- Resolve part alias to something like 'carburador'
drop function if exists resolve_part(text);
create function resolve_part(q text) returns text language plpgsql stable as $$
declare
  tok text[] := tokenize(q);
  p text;
begin
  select part_code from part_aliases where alias = any(tok) limit 1 into p;
  if p is not null then return p; end if;
  -- else return a generic keyword hit
  select alias from part_aliases where alias = any(tok) limit 1 into p;
  return p;
end $$;

-- Fulltext-ish match on parts using description and aliases
drop function if exists search_parts(q text, limit_k int);
create function search_parts(q text, limit_k int default 10)
returns table(
  part_code text,
  description text,
  price numeric,
  matched boolean
) language sql stable as $$
  with tokens as (
    select unnest(tokenize(q)) t
  ),
  base as (
    select p.part_code, p.description,
           (select price from part_prices pr where pr.part_id = p.id order by valid_from desc limit 1) as price
    from parts p
  ),
  ali as (
    select a.part_code
    from part_aliases a
    join tokens t on t.t = a.alias
  )
  select b.part_code, b.description, b.price, (b.part_code in (select part_code from ali)) as matched
  from base b
  where normalize_text(b.description) ilike '%' || normalize_text(q) || '%'
     or b.part_code in (select part_code from ali)
  order by matched desc, b.part_code
  limit limit_k;
$$;

-- Expand models from "modelos_compativeis" field (slash-separated)
drop function if exists split_models(text);
create function split_models(s text) returns text[] language sql immutable as $$
  select regexp_split_to_array(replace(s, ' ', ''), '/');
$$;

-- Helper to fetch all parts for a model_code via compat table
drop function if exists parts_for_model(mcode text, limit_k int);
create function parts_for_model(mcode text, limit_k int default 50)
returns table(
  part_code text,
  description text,
  price numeric
) language sql stable as $$
  select p.part_code, p.description,
         (select price from part_prices pr where pr.part_id = p.id order by valid_from desc limit 1) as price
  from parts p
  join part_model_compat pm on pm.part_id = p.id
  where pm.model_code = mcode
  order by p.part_code
  limit limit_k;
$$;