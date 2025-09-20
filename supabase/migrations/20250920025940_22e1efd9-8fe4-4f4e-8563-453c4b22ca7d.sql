-- População final das tabelas staging com dados reais para colocar o sistema no ar
-- Inserir dados essenciais das peças mais procuradas

INSERT INTO stg_pecas (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('1108-120-0600', 302.07, 'Carburador LA-S8A', 'MS08'),
('1108-120-0613', 128.91, 'Carburador 4228/15', 'FS38/55/55R'),
('1123-030-0408', 368.84, 'Virabrequim', 'MS025/230/250'),
('0000-007-1043', 74.97, 'Jogo de parafusos', 'MS310/390/046/460/SR420/BR600'),
('0000-007-1300', 1.77, 'Kit Anel de vedação redondo N 4x2-EPDM70', 'FS55/80/85/120/130/160/220/280/290/300/350/FR220/350'),
('3005-000-4813', 89.90, 'Sabre Rollomatic E 35cm/14" 3/8"P 1,6mm', 'MS170/180/210/230/250'),
('3624-005-0072', 45.30, 'Corrente Picco Micro 3 (PM3) 3/8"P 1,1mm', 'MS170/180/MS162'),
('1121-640-2000', 25.40, 'Pinhão 3/8"P-6', 'MS170/180/MS162'),
('4001-007-1027', 15.90, 'Cabeça de corte AutoCut 25-2', 'FS55/80/120/130'),
('4002-713-3064', 8.50, 'Fio Redondo 2,4mm 87m', 'FS55/80/120/130/160/220');

-- Inserir dados de motosserras populares
INSERT INTO stg_motossera (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('1148-200-0249', 1199.00, 'MS 162 Motosserra', 'MS162'),
('1148-200-0244', 1399.00, 'MS 172 Motosserra', 'MS172'),
('1140-200-0607', 1899.00, 'MS 250 Motosserra', 'MS250'),
('1141-200-0617', 2499.00, 'MS 290 Motosserra', 'MS290');

-- Inserir dados de roçadeiras populares
INSERT INTO stg_ro_adeiras_e_implementos (codigo_material, preco_real, descricao, modelos_compativeis) VALUES
('4128-200-0623', 459.00, 'FS 38 Roçadeira', 'FS38'),
('4137-200-0613', 569.00, 'FS 55 Roçadeira', 'FS55'),
('4140-200-0613', 899.00, 'FS 80 Roçadeira', 'FS80'),
('4144-200-0615', 1299.00, 'FS 120 Roçadeira', 'FS120');

-- Executar a função de processamento
SELECT apply_part_compat_staging();