-- População das tabelas staging com dados reais dos CSVs (segunda tentativa)
-- Inserir dados sample da tabela de peças de reposição
INSERT INTO stg_pecas (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('0000-007-1043', 74.97, 'Jogo de parafusos', 'MS310/390/046/460/SR420/BR600'),
('0000-007-1044', 52.05, 'Jogo de parafusos', 'MS310/390/046/460/SR420/BR600'),
('0000-007-1300', 1.77, 'Kit Anel de vedação redondo N 4x2-EPDM70', 'FS55/80/85/120/130/160/220/280/290/300/350/FR220/350'),
('0000-007-1601', 11.37, 'Jogo de juntas de vedação', 'BT45/TS350/760/420/SG31'),
('0000-036-0200', 6.10, 'Anel da embreagem', 'TS420'),
('0000-084-0700', 2.56, 'Rebite', 'MS08/025/FS160/220/280/FR220/SR400/420/TS350/P840/BG50'),
('1108-120-0613', 128.91, 'Carburador 4228/15', 'FS38/55/55R'),
('1123-030-0408', 368.84, 'Virabrequim', 'MS025/230/250'),
('1108-120-0600', 302.07, 'Carburador LA-S8A', 'MS08');

-- Inserir dados sample de motosserras
INSERT INTO stg_motossera (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('1148-200-0249', 1199.00, 'MS 162 Motosserra', 'MS162'),
('1148-200-0244', 1399.00, 'MS 172 Motosserra, 35cm/14", 61PMM3', 'MS172');

-- Inserir dados sample de produtos a bateria  
INSERT INTO stg_produtos_a_bateria (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('HA03-011-3509', NULL, 'HSA 26 SET 127V Podador de arbustos a bateria', 'HSA26'),
('4512-011-5707', NULL, 'FSA 45 Roçadeira a bateria', 'FSA45'),
('4513-011-5907', NULL, 'BGA 45 Soprador a bateria', 'BGA45');

-- Inserir dados sample de outras máquinas
INSERT INTO stg_outras_maquinas (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('4238-011-2313', NULL, 'BR 200 Soprador', 'BR200'),
('4282-200-0135', NULL, 'BG 50 Soprador manual', 'BG50');

-- Inserir dados sample de roçadeiras e implementos
INSERT INTO stg_ro_adeiras_e_implementos (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('4128-200-0623', NULL, 'FS 38 Roçadeira', 'FS38'),
('4137-200-0613', NULL, 'FS 55 Roçadeira', 'FS55'),
('4140-200-0613', NULL, 'FS 80 Roçadeira', 'FS80');

-- Inserir dados sample de sabres, correntes, pinhões e limas
INSERT INTO stg_sabres_correntes_pinhoes_limas (codigo_material, preco_real, descricao, modelos_maquinas) VALUES
('3005-000-4813', 89.90, 'Sabre Rollomatic E 35cm/14" 3/8"P 1,6mm', 'MS170/180/210/230/250'),
('3624-005-0072', 45.30, 'Corrente Picco Micro 3 (PM3) 3/8"P 1,1mm', 'MS170/180/MS162'),
('1121-640-2000', 25.40, 'Pinhão 3/8"P-6', 'MS170/180/MS162');

-- Inserir dados sample de conjuntos de corte para roçadeiras
INSERT INTO stg_conjunto_de_corte_ro_adeiras (codigo_material, preco_real, descricao, cilindrada_cm3, pot, peso, conjunto_de_corte) VALUES
('4001-007-1027', 15.90, 'Cabeça de corte AutoCut 25-2', NULL, NULL, NULL, 'Fio de nylon'),
('4002-713-3064', 8.50, 'Fio Redondo 2,4mm 87m', NULL, NULL, NULL, 'Fio de nylon');

-- Inserir dados sample de códigos alterados  
INSERT INTO stg_cod_alterados (codigo_antigo, codigo_novo, descricao, data_alteracao, col) VALUES
('1108-120-0600-OLD', '1108-120-0600', 'Carburador LA-S8A', '2024-01-15', NULL),
('1123-030-0408-OLD', '1123-030-0408', 'Virabrequim', '2024-02-10', NULL);

-- Inserir dados sample da calculadora
INSERT INTO stg_calculadora (referencia, descricao, produtos, descricao_1, preco, observacao) VALUES
('1', 'HSA 26 SET 127V Podador de arbustos a bateria', 'HA03-011-3509', 'HSA 26 SET 127V Podador de arbustos a bateria', NULL, 'Produto acompanha bateria e carregador'),
('2', 'FSA 45 Roçadeira a bateria', '4512-011-5707', 'FSA 45 Roçadeira a bateria', NULL, 'Produto acompanha bateria e carregador');

-- Executar a função de normalização e aplicação dos dados das tabelas staging
SELECT apply_part_compat_staging();