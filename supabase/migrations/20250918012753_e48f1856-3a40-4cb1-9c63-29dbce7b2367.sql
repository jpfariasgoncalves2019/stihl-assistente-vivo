-- 0006_seed_aliases.sql
insert into part_aliases (part_code, alias) values
  ('*','carburador'),('1123-120-0600','carburador'),('1108-120-0613','carburador'),
  ('*','virabrequim'),('1123-030-0408','virabrequim'),
  ('*','filtro'),('*','filtro_ar'),('*','vela'),('*','bobina'),('*','embreagem'),
  ('*','kit_reparo_carburador'),('*','anel_de_trava'),('*','anel'),('*','bucha'),
  ('*','cabeçote'),('*','cabeçote_roçadeira'),('*','refil_de_fio'),('*','sabre'),('*','corrente');

insert into model_aliases (model_code, alias) values
  ('MS 170','ms170'),('MS 170','ms 170'),('MS 180','ms180'),('MS 180 C-BE','ms180cbe'),('MS 382','ms382'),
  ('MS 250','ms250'),('MS 08','08'),('MS 08','ms08'),('FS 55','fs55'),('FS 55 R','fs55r'),('FS 80','fs80'),
  ('FS 85','fs85'),('FS 160','fs160'),('FS 220','fs220'),('BR 420','br420'),('BG 86','bg86'),('TS 800','ts800'),
  ('MS 066','ms66'),('MS 650','ms650');