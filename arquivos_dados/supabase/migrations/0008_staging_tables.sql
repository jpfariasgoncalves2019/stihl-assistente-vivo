-- 0008_staging_tables.sql
-- Raw/staging tables mirroring the spreadsheet for one-shot import.
drop table if exists stg_pecas cascade;
create table stg_pecas (
  codigo_material text,
  preco_real numeric,
  descricao text,
  modelos_compativeis text
);

drop table if exists stg_motossera cascade;
create table stg_motossera (
  like stg_pecas including all
) inherits (); -- placeholder generic shape

drop table if exists stg_ro_adeiras_e_implementos cascade;
create table stg_ro_adeiras_e_implementos (
  like stg_pecas including all
);

drop table if exists stg_produtos_a_bateria cascade;
create table stg_produtos_a_bateria (
  like stg_pecas including all
);

drop table if exists stg_outras_maquinas cascade;
create table stg_outras_maquinas (
  like stg_pecas including all
);

drop table if exists stg_sabres_correntes_pinhoes_limas cascade;
create table stg_sabres_correntes_pinhoes_limas (
  codigo_material text,
  preco_real numeric,
  descricao text,
  modelos_maquinas text
);

drop table if exists stg_conjunto_de_corte_ro_adeiras cascade;
create table stg_conjunto_de_corte_ro_adeiras (
  codigo_material text,
  preco_real numeric,
  descricao text,
  cilindrada_cm3 text,
  pot text,
  peso text,
  conjunto_de_corte text
);

drop table if exists stg_cod_alterados cascade;
create table stg_cod_alterados (
  codigo_antigo text,
  codigo_novo text,
  descricao text,
  data_alteracao text,
  col text
);

drop table if exists stg_calculadora cascade;
create table stg_calculadora (
  referencia text,
  descricao text,
  produtos text,
  descricao_1 text,
  preco text,
  observacao text
);