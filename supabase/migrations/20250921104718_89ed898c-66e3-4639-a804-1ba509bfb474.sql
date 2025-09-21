-- Popular tabela sabres, correntes, pinhões e limas
-- Primeiro limpar dados existentes desta categoria se houver
DELETE FROM stg_sabres_correntes_pinhoes_limas;

-- Inserir dados de sabres
INSERT INTO stg_sabres_correntes_pinhoes_limas (codigo_material, preco_real, descricao, modelos_maquinas) VALUES
('3002-001-9223', 369.84, 'Sabre D 53cm/21" 1,6mm/0.063"', 'MS08/051/076'),
('3002-001-9231', 425.04, 'Sabre D 63cm/25" 1,6mm/0.063" 404"', 'MS051/076/08'),
('3002-001-8041', 491.28, 'Sabre D 75cm/30" 1,6mm/0.063"', 'MS051/076'),
('3003-001-9207', 259.44, 'Sabre D 33cm/13" 1,6mm/0.063" 3/8"', 'MS310/361/260/362/382'),
('3003-001-9213', 298.09, 'Sabre D 40cm/16" 1,6mm/0.063" 3/8"', 'MS310/362/382/460/650/660'),
('3003-001-9221', 353.29, 'Sabre D 50cm/20" 1,6mm/0.063"', 'MS034/038/066/460/650/660/362/382'),
('3003-001-5631', 425.04, 'Sabre D 63cm/25" 1,6mm/0.063"', 'MS460/650/660'),
('3003-001-9241', 491.28, 'Sabre D 75cm/30" 1,6mm/0.063"', 'MS064/066/650/660'),
('3003-000-8453', 694.79, 'Sabre D 90cm/36" 1,6mm/0.063"', 'MS651/661'),
('3003-001-9406', 282.45, 'Sabre S 32cm/13" 1,6mm/0.063" 3/8"', 'MS310/260/361/382'),
('3003-001-9413', 312.99, 'Sabre S 40cm/16" 1,6mm/0.063" 3/8"', 'MS310/260/361/362/382'),
('3003-001-9421', 370.92, 'Sabre S 50cm/20" 1,6mm/0.063" 3/8"', 'MS310/260/361/362/382/460/650/660'),
('3003-001-9431', 446.29, 'Sabre S 63cm/25" 1,6mm/0.063" 3/8"', 'M460/650/660'),
('3003-001-6041', 515.85, 'Sabre S 75cm/30" 1,6mm/0.063" 3/8"', 'MS650/660'),
('3005-000-3905', 160.72, 'Sabre R 30cm/12" 1,1mm/0.043" 3/8" P', 'HT75/133/KA85R/KM55R/KM85R/MS170/MS180/180C/MS193T/MSE141'),
('3005-003-3909', 165.32, 'Sabre R 35cm/14" 1,1mm/0.043" 3/8" P', 'MS180/MS172'),
('3003-008-6813', 218.95, 'Sabre R 40cm/16" 1,6mm/0.063" .325"', 'MS260'),
('3003-000-5221', 264.96, 'Sabre R 50cm/20" 1,6mm/0.063" 3/8"', 'MS310/260/361/362/382/460/650/660'),
('3005-008-3405', 154.32, 'Sabre L01 30cm/12" 1,1mm/0.043" 1/4"P', 'MSA120/160/200/160T/HTA85/HT133/HT75'),
('3005-008-3409', 187.95, 'Sabre L01 35cm/14" 1,1mm/0.043" 1/4"P', 'MSA200'),
('3005-000-4413', 212.91, 'Sabre L04 40cm/16" 1,1mm/0.043" 3/8" P', 'MSA 220.0 C-B'),
('3005-000-4805', 187.95, 'Sabre L04 30cm/12" 1,3mm/0.050" 3/8"P', 'MS210/230/250/MSE170/HT70K'),
('3005-000-4809', 193.2, 'Sabre L04 35cm/14" 1,3mm/0.050" 3/8"P', 'MS210/230/250/MSE170/MSA220'),
('3005-000-4813', 212.91, 'Sabre L04 40cm/16" 1,3mm/0.050" 3/8"P', 'MS/182/210/212/230/250/MSE170'),
('3003-000-5306', 219.44, 'Sabre L04 32cm/13" 1,6mm/0.063" .325"', 'MS260'),
('3005-000-4817', 235.02, 'Sabre L04 45cm/18" 1,3mm/0.050" 3/8"P', 'MS212'),
('3003-000-5213', 240.45, 'Sabre L06 40cm/16" 1,6mm/0.063" 3/8"', 'MS310/260/361/362/382/460/650/660'),
('3003-000-5231', 318.77, 'Sabre L06 63cm/25" 1,6mm/0.063" 3/8"', 'MS460/650/660'),
('3007-003-0101', 72.44, 'Sabre L 10cm/4" 1,1mm/0.043"', 'GTA 26'),
('3005-008-4905', 168.99, 'Sabre L 30cm/12" 1,1mm/0.043"', 'MS162'),
('3003-008-3317', 232.61, 'Sabre L04 45cm/18" 1,3mm/0.050" .325"', 'MSA300.0'),
('3003-008-3321', 252.31, 'Sabre L04 50cm/20" 1,3mm/0.050" .325"', 'MSA300.0'),
('3005-000-3105', 286.24, 'Sabre C 30cm/12" 1,1mm/0.043" 1/4" P', ''),
-- Acessórios de sabres
('3003-650-2551', 133.25, 'Cabeça do sabre 3/8" 11Z 1,6', 'Novos Sabres Rollomatic Super - 32/40/50/63/75cm (1,6mm)'),
('3003-650-9922', 85.09, 'Estrela reversora 3/8" 10Z 1,6', 'MS361/381'),
('3003-650-9935', 85.09, 'Estrela reversora 3/8 11Z 1,6', 'Novos Sabres Rollomatic Super - 32/40/50/63/75cm (1,6mm)'),
('3005-650-9903', 85.09, 'Estrela reversora 9d 1,3', 'MS011/025'),
('0000-974-0503', 3.48, 'Rebite de cabeça embutida', 'MS034/038/066');

-- Inserir dados de correntes
INSERT INTO stg_sabres_correntes_pinhoes_limas (codigo_material, preco_real, descricao, modelos_maquinas) VALUES
-- Corrente 35 RM
('3651-000-1640', 2797.68, '35 RM Rapid Micro Rolo de corrente', 'Corrente para máquinas da concorrência'),
-- Corrente 36 RM
('3652-000-0052', 100.8, '36 RM Rapid Micro Corrente', 'MS310/260/361/382'),
('3652-000-0060', 116.31, '36 RM Rapid Micro Corrente', 'MS310/260/361/382/460'),
('3652-000-0072', 139.57, '36 RM Rapid Micro Corrente', 'MS382/460/650/660'),
('3652-000-0084', 162.83, '36 RM Rapid Micro Corrente', 'MS460/650/660'),
('3652-000-0096', 186.1, '36 RM Rapid Micro Corrente', 'MS650/651/660/661'),
('3652-000-0098', 189.96, '36 RM Rapid Micro Corrente', 'MS650/660'),
('3652-000-1640', 2797.42, '36 RM Rapid Micro Rolo de corrente', 'MS310/361/362/382/462/651/661'),
-- Corrente 36 RMX
('3653-000-1640', 2797.68, '36 RMX Rapid Micro Rolo de corrente', 'Dentes com ângulo de afiação com 10º'),
-- Corrente 36 RS
('3621-000-0050', 96.93, '36 RS Rapid Super Corrente', 'MS310/260/361/362/382'),
('3621-000-0052', 100.8, '36 RS Rapid Super Corrente', 'MS310/260/361/362/382'),
('3621-000-0060', 116.32, '36 RS Rapid Super Corrente', 'MS310/361/460/362/382'),
('3621-000-0072', 139.58, '36 RS Rapid Super Corrente', 'MS362/382/460/650/660'),
('3621-000-0084', 162.84, '36 RS Rapid Super Corrente', 'MS462/651/661'),
('3621-000-0096', 186.1, '36 RS Rapid Super Corrente', 'MS462/651/661'),
('3621-000-0098', 189.98, '36 RS Rapid Super Corrente', 'MS462/651/661'),
('3621-000-1640', 2797.42, '36 RS Rapid Super Rolo de corrente', 'MS310/361/362/382/462/651/661'),
-- Corrente 36 RM3
('3664-000-1640', 2797.37, '36 RM3 Rapid Micro Rolo de corrente', '3/8 1,6mm MS310/361/362/382/462/651/661'),
-- Corrente 36 RS3
('3626-000-1640', 2797.37, '36 RS3 Rapid Super Rolo de corrente', '3/8 1,6mm MS310/361/362/382/462/651/661'),
-- Corrente 63 PM
('3613-000-0044', 78.92, '63 PM Picco Micro Corrente', 'MSE170/MS210/230/250'),
('3613-000-0050', 89.66, '63 PM Picco Micro Corrente', 'MS210/230/250'),
('3613-000-0055', 98.63, '63 PM Picco Micro Corrente', 'MS230/250'),
('3613-000-1640', 2587.59, '63 PM Picco Micro Rolo de corrente', '3/8 Picco 1,3mm, MSE 170 C-BQ, MS 210/230/250'),
-- Corrente 63 PMY
('3615-000-1640', 2849.01, '63 PMY Picco Micro Rolo de corrente​', 'MS 182, MS 212, MS 230, MS 250 e MSA 220 C-BE'),
-- Corrente 63 PM3
('3636-000-1640', 2587.56, '63 PM3 Picco Micro Rolo de corrente', '3/8 Picco 1,3mm MS182/212/230/250'),
('3636-000-0055', 98.6, '63 PM3 Picco Micro Corrente', 'MS182/212'),
('3636-000-0061', 109.37, '63 PM3 Picco Micro Corrente', 'MS212'),
-- Corrente 26 RS
('3639-000-0056', 114.45, '26 RS Rapid Super Corrente', 'MS260 - Sabres 32 cm - 0.325'),
('3639-000-0067', 113.65, '26 RS Rapid Super Corrente', 'MS260 - Sabres 40 cm - 0.325'),
('3639-000-1840', 3075.45, '26 RS Rapid Super Rolo de corrente', '0.325 MS260'),
-- Corrente 61 PMM3
('3610-000-0044', 77.67, '61 PMM3 Picco Micro Mini Corrente', 'MS162/170/180/193T/HT75/131/MSE141'),
('3610-000-0050', 88.26, '61 PMM3 Picco Micro Mini Corrente', 'MS172/172C/180'),
('3610-000-1640', 2760.44, '61 PMM3 Picco Micro Mini Rolo de', '3/8 Picco 1,1 mm HT75/131/KA85R/KM55R/KM85R/MS170/ MS180/180C/MS193T'),
-- Corrente 71 PM3
('3670-000-0028', 51.84, '71 PM3 Picco Micro Corrente', 'GTA 26'),
('3670-000-0064', 124.95, '71 PM3 Picco Micro Corrente', 'MSA 60/70/160/200/160T/HTA85/HT133/HT75'),
('3670-000-0065', 120.33, '71 PM3 Picco Micro Corrente', 'MSA 161'),
('3670-000-0072', 133.31, '71 PM3 Picco Micro Corrente', 'MSA200'),
('3670-000-1200', 2078.63, '71 PM3 Picco Micro Rolo de corrente', 'MSA120/140/160/200/HT75/133'),
-- Corrente 63 PS3
('3616-000-0050', 124.95, '63 PS3 Picco Super Corrente', 'MSA220'),
-- Corrente 36 RDR
('3944-000-0072', 1289.78, '36 RDR Rapid Duro Corrente', 'Kit Resgaste MS 460 - para sabre de 50cm/20'),
-- Corrente 61 PS3
('3699-000-0055', 112.73, '61 PS3 Pro Picco Super Corrente', 'MSA 220.0 C-B'),
-- Corrente 36 RH
('3132-000-1640', 2867.32, '36 RH Rapid Hexa Rolo de corrente', '3/8 1,6mm MS 361/382/462/651/661'),
-- Corrente 23 RS Pro
('3690-000-0074', 125.54, '23 RS Pro Rapid Super Corrente', 'MSA300.0'),
('3690-000-0081', 137.38, '23 RS Pro Rapid Super Corrente', 'MSA300.0'),
-- Caixa para corrente e emendas
('0000-900-2141', 23.96, 'Kit de Caixas para correntes c/10 unid', 'Contém 10 unidades'),
('3522-660-6000', 91.06, 'Kit peças da corrente 3/8 35RM', '35 RM RAPID MICRO (20 pares elos + elos c/ reb.)'),
('3610-660-6000', 14.88, 'Kit peças da corrente 3/8 PMM (9 pares)', '61 PMMC3 PICCO MICRO (MS170/180/192T/HT75)'),
('3686-660-6000', 13.31, 'Kit peças da corrente .325', 'MS260 (Elo de ligação com e sem rebite 8 peças)'),
('3669-660-6000', 23.28, 'Kit peças da corrente 1/4 Picco', 'MSA160/200'),
('3997-660-6000', 14.02, 'Kit peças da corrente 3/8 PM', '63 PM PICCO MICRO (MSE160) (elo de ligação com e sem rebite 9 pares)'),
('3603-662-1050', 4.06, 'Jogo peças do elo de tração .325 R 1,6', 'MS260 - .325 - Contém 10 elos de tração'),
('3669-662-1050', 5.24, 'Jogo peças do elo de tração 1/4 PM 1,1', '1/4 P - Contém 10 elos de tração'),
('3639-007-1000', 16.95, 'Jogo .325 RS dente de corte direito', 'MS260'),
('3639-007-1001', 16.95, 'Jogo .325 RS dente de corte esquerdo', 'MS260');

-- Inserir dados de pinhões e roletes
INSERT INTO stg_sabres_correntes_pinhoes_limas (codigo_material, preco_real, descricao, modelos_maquinas) VALUES
('4128-640-7303', 236.09, 'Jogo de pinhões', 'FS120/160/220/250/280'),
('4130-640-7301', 97.89, 'Jogo de pinhões', 'FS44/85/85R/120/250/FR85/220/350/HLImpl'),
('4133-640-7300', 121.25, 'Jogo de pinhões', 'FCB-KM'),
('4140-640-7300', 86.09, 'Jogo de pinhões', 'FS55'),
('4182-640-7300', 421.27, 'Jogo de pinhões', 'HTImpl'),
('4230-640-7305', 354.42, 'Jogo de pinhões', 'HL135'),
('4138-640-7301', 443.22, 'Jogo de pinhões 0,8', 'HT75'),
('4182-640-7303', 398.39, 'Jogo de pinhões 1,27', 'HT75'),
('0000-642-1236', 37.65, 'Rolete do pinhão 0.325 7d', 'MS260'),
('0000-640-2002', 29.38, 'Pinhão da corrente 3/8P 6 Z', 'HT70K'),
('1121-007-1037', 151.87, 'Jogo de rolete anular 0.325 7d', 'MS260'),
('1122-007-1002', 172.51, 'Jogo de rolete anular 0.404 7d', 'MS064/066/660/650'),
('1119-007-1003', 156.59, 'Jogo de rolete anular 3/8 7d', 'MS038/380/381'),
('1121-007-1041', 151.87, 'Jogo de rolete anular 3/8 7d', 'MS260'),
('1122-007-1000', 172.51, 'Jogo de rolete anular 3/8 7d', 'MS650/660'),
('1125-007-1041', 162.19, 'Jogo de rolete anular 3/8 7d', 'MS036/360'),
('1119-007-2500', 162.97, 'Jogo de rolete anular 3/8 7d', 'MS361/362/382/046/460/462'),
('1108-640-2026', 153.43, 'Jogo de rolete anular 3/8 8d', 'MS08'),
('1111-640-2026', 185.17, 'Jogo de rolete anular 3/8 8d', 'MS051/076'),
('1122-007-1001', 172.51, 'Jogo de rolete anular 3/8 8d', 'MS064/066/660/650'),
('1119-007-2501', 162.97, 'Jogo de rolete anular 3/8 8d', 'MS382'),
('1123-640-2073', 75.37, 'Pinhão da corrente 3/8P 6 Z', 'MS210/025/230/250'),
('1125-640-2004', 87.3, 'Pinhão da corrente 3/8 7d', 'MS310/039/390'),
('1123-640-2003', 75.37, 'Pinhão da corrente 3/8P 6 Z', 'MS180/MS170'),
('1137-640-2005', 88.38, 'Pinhão da corrente 3/8P 6 Z', 'MS193T'),
('4138-642-1201', 43.19, 'Pinhão da corrente 3/8P 6 Z', 'HTImpl'),
('1206-642-1301', 65.94, 'Pinhão da corrente 3/8P 7 Z', 'E14/160'),
('1137-640-2007', 88.38, 'Pinhão da corrente 3/8P 7 Z', 'MS193T'),
('4230-642-0405', 37.56, 'Pinhão de acionamento', 'HLImpl'),
('4231-642-0400', 45.16, 'Pinhão de acionamento', 'SP81');

-- Inserir dados de acessórios de afiação
INSERT INTO stg_sabres_correntes_pinhoes_limas (codigo_material, preco_real, descricao, modelos_maquinas) VALUES
-- Cabos da lima
('0000-881-4500', 36.33, 'Cabo de lima com ângulos de afiação', 'Limas redonda e chata'),
('0000-881-4502', 39.01, 'Cabo da lima FH1', 'Limas redonda'),
('0000-881-4503', 39.01, 'Cabo da lima FH3', 'Lima chata'),
('0000-881-4504', 12.38, 'Cabo da lima', 'Limas redondas de 3,2 – 5,5 mm de diâmetro'),
-- Limas
('0814-252-3356', 16.79, 'Lima chata 150x16x2,7', 'Para correntes 3/8'),
('5605-771-3206', 13.12, 'Lima redonda 3,2x150', 'MSA120/140/160/161T/200/HT133'),
('5605-771-4806', 9.01, 'Lima redonda 4,8x200', 'MS260'),
('5605-771-4006', 9.01, 'Lima redonda 4x200', '3/8 PMM 1.1mm e PM 1.3mm'),
('5605-771-5206', 9.01, 'Lima redonda 5,2x200', '3/8 RS e RM 1.6mm'),
('5605-771-5506', 9.01, 'Lima redonda 5,5x200', '404 e serra circular especial de FS'),
('5607-772-5201', 82.96, 'Lima hexagonal 5,2x200 1 por pacote', 'Uso exclusivo na corrente 36 RH Rapid Hexa'),
('0000-881-7100', 2.48, 'Embalagem de limas', 'Embalagem de papel para armazenagem individual de limas redondas e chata'),
-- Suporte de lima
('5605-750-4300', 79.01, 'Suporte de limas 1/4 Picco', 'PM 1,1mm 1/4 - MSA160/200'),
('5605-750-4327', 109, 'Suporte para lima 1/4, 3/8 P', 'PM 1,3mm 3/8'),
('5605-750-4328', 109, 'Suporte para lima .325', 'MS260'),
('5605-750-4329', 109, 'Suporte para lima 3/8', 'RM/RS 1,6mm 3/8'),
('5605-750-4330', 109, 'Suporte para lima .404', 'RC 1,6mm 0.404'),
('5605-750-4343', 109, 'Suporte para lima', 'FS86/88/106/108/160/220/FR106/108'),
-- Suporte 2 em 1
('5605-750-4303', 309, 'Suporte de limas 2-in-1 3/8 P', 'MS170/180/210/230/250/HT75/131'),
('5605-750-4304', 309, 'Suporte de limas 2-in-1 .325', 'MS260'),
('5605-750-4305', 309, 'Suporte de limas 2-in-1 3/8', 'MS310/361/382/462/651/661'),
('5605-750-4306', 309, 'Suporte de limas 2-in-1 1/4P', 'MSA120/140/160/200'),
('0000-893-6401', 16.66, 'Lima redonda de reposição(4306)', 'Suporte de limas 2-in-1 1/4P'),
('0814-252-3001', 87.08, 'Lima chata 200x9x6', 'Para Suporte de limas 2-in-1'),
-- Jogo de afiação
('5605-007-1028', 169, 'Jogo de afiação', 'MS260'),
('5605-007-1030', 169, 'Jogo de afiação .404', 'MS051/08'),
('5605-007-1000', 169, 'Jogo de afiação 1/4 Picco', 'MSA160C/200C'),
('5605-007-1027', 169, 'Jogo de afiação 1/4, 3/8 P', 'MS170/180/210/230/250/HT75/131'),
('5605-007-1029', 169, 'Jogo de afiação 3/8', 'MS310/361/382/462/651/661'),
-- Condução da lima
('5614-000-7500', 119, 'Condução da lima FF 1 3/8', 'MS260/310/361/381/460/650/660'),
('5614-000-7501', 119, 'Condução da lima FF 1 .325', 'MS260'),
('5614-000-7502', 119, 'Condução da lima FF 1 3/8 P', 'MSE170/MS210/230/250'),
('5614-000-7503', 119, 'Condução da lima FF 1 3/8 P M.', 'MS170/180/210/230/250/HT75/131'),
('5614-000-7504', 119, 'Condução da lima FF 1 1/4 P', 'MSA160C/200C'),
('5614-000-7505', 119, 'Condução da lima FF 1 .404', 'MS051/08'),
-- Afiador elétrico
('5203-200-0010', 4399.01, 'USG Afiador completo 220 V/60 Hz', ''),
('5203-200-0011', 4399.01, 'USG Afiador completo 127 V/60 Hz', ''),
-- Rebitador e Desrebitador
('5805-012-7500', 1546.72, 'Desrebitador NG 4', ''),
('5805-012-7510', 1823.29, 'Rebitador NG 5', '');

-- Estender a função apply_part_compat_staging para processar stg_sabres_correntes_pinhoes_limas
CREATE OR REPLACE FUNCTION apply_sabres_correntes_staging()
RETURNS text
LANGUAGE plpgsql
AS $function$
DECLARE
    rec RECORD;
    part_id_var UUID;
    model_codes TEXT[];
    model_code_var TEXT;
    processed_count INTEGER := 0;
BEGIN
    -- Processar dados de stg_sabres_correntes_pinhoes_limas
    FOR rec IN SELECT codigo_material, preco_real, descricao, modelos_maquinas 
               FROM stg_sabres_correntes_pinhoes_limas 
               WHERE codigo_material IS NOT NULL AND trim(codigo_material) != ''
    LOOP
        -- Inserir ou atualizar parte
        INSERT INTO parts (part_code, description)
        VALUES (rec.codigo_material, rec.descricao)
        ON CONFLICT (part_code) DO UPDATE SET description = EXCLUDED.description
        RETURNING id INTO part_id_var;
        
        -- Se não conseguiu o ID do INSERT, buscar o existente
        IF part_id_var IS NULL THEN
            SELECT id INTO part_id_var FROM parts WHERE part_code = rec.codigo_material;
        END IF;
        
        -- Inserir preço se existir
        IF rec.preco_real IS NOT NULL THEN
            -- Verificar se já existe preço para hoje
            IF NOT EXISTS (SELECT 1 FROM part_prices WHERE part_id = part_id_var AND valid_from = CURRENT_DATE AND source = 'sabres_staging') THEN
                INSERT INTO part_prices (part_id, price, currency, source, valid_from)
                VALUES (part_id_var, rec.preco_real, 'BRL', 'sabres_staging', CURRENT_DATE);
            END IF;
        END IF;
        
        -- Processar compatibilidades de modelos se houver
        IF rec.modelos_maquinas IS NOT NULL AND trim(rec.modelos_maquinas) != '' THEN
            model_codes := string_to_array(replace(rec.modelos_maquinas, ' ', ''), '/');
            FOREACH model_code_var IN ARRAY model_codes
            LOOP
                IF trim(model_code_var) != '' THEN
                    INSERT INTO part_model_compat (part_id, model_code)
                    VALUES (part_id_var, trim(model_code_var))
                    ON CONFLICT (part_id, model_code) DO NOTHING;
                END IF;
            END LOOP;
        END IF;
        
        processed_count := processed_count + 1;
    END LOOP;

    RETURN 'Processados ' || processed_count || ' registros de sabres, correntes, pinhões e limas.';
END;
$function$;

-- Executar a função para popular as tabelas principais
SELECT apply_sabres_correntes_staging();