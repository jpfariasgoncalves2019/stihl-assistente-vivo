#!/usr/bin/env python3
"""
STIHL Assistente Virtual - Conversor XLSX para CSVs do Catálogo
Arquivo: scripts/xlsx_to_catalog_csv.py

Este script converte a planilha "Lista Sugerida.xlsx" em CSVs normalizados
para importação no banco de dados STIHL.
"""

import argparse
import sys
from pathlib import Path
import pandas as pd
import re
from decimal import Decimal, InvalidOperation
from typing import Dict, List, Tuple, Optional

class XLSXConverter:
    def __init__(self, xlsx_path: str, output_dir: str = "out_csv"):
        self.xlsx_path = Path(xlsx_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        # Contadores para relatório
        self.stats = {
            'total_rows': 0,
            'valid_rows': 0,
            'invalid_rows': 0,
            'duplicates_removed': 0,
            'errors': []
        }
    
    def log_error(self, row_num: int, error: str, data: dict = None):
        """Registrar erro de processamento"""
        error_info = {
            'row': row_num,
            'error': error,
            'data': data
        }
        self.stats['errors'].append(error_info)
        print(f"  ⚠️  Linha {row_num}: {error}")
    
    def normalize_part_code(self, part_code: str) -> Optional[str]:
        """Normalizar código de peça"""
        if pd.isna(part_code) or not str(part_code).strip():
            return None
        
        # Converter para string e limpar
        code = str(part_code).strip().upper()
        
        # Remover caracteres inválidos, manter apenas alfanuméricos, hífen, barra e ponto
        code = re.sub(r'[^A-Z0-9\-/\.]', '', code)
        
        # Validar formato básico
        if len(code) < 3 or len(code) > 50:
            return None
        
        return code
    
    def normalize_price(self, price: any) -> Optional[Decimal]:
        """Normalizar preço para decimal"""
        if pd.isna(price):
            return None
        
        try:
            # Converter para string primeiro
            price_str = str(price).strip()
            
            # Remover símbolos de moeda e espaços
            price_str = re.sub(r'[R$\s]', '', price_str)
            
            # Substituir vírgula por ponto (padrão brasileiro)
            price_str = price_str.replace(',', '.')
            
            # Validar se contém apenas números e pontos
            if not re.match(r'^\d+(\.\d+)?$', price_str):
                return None
            
            decimal_price = Decimal(price_str)
            
            # Validar faixa razoável
            if decimal_price < 0 or decimal_price > 100000:
                return None
            
            return decimal_price
        
        except (InvalidOperation, ValueError):
            return None
    
    def normalize_model_code(self, model: str) -> Optional[str]:
        """Normalizar código de modelo"""
        if pd.isna(model) or not str(model).strip():
            return None
        
        # Converter para string e limpar
        model_str = str(model).strip().upper()
        
        # Remover caracteres especiais, manter alfanuméricos e espaços
        model_str = re.sub(r'[^A-Z0-9\s]', '', model_str)
        
        # Remover espaços extras
        model_str = re.sub(r'\s+', ' ', model_str).strip()
        
        # Validar comprimento
        if len(model_str) < 1 or len(model_str) > 50:
            return None
        
        return model_str
    
    def extract_category_from_model(self, model_code: str) -> str:
        """Extrair categoria baseada no código do modelo"""
        if not model_code:
            return 'Outros'
        
        model_upper = model_code.upper()
        
        # Padrões conhecidos STIHL
        if model_upper.startswith(('MS', 'MSA')):
            return 'Motosserra'
        elif model_upper.startswith(('FS', 'FSA')):
            return 'Roçadeira'
        elif model_upper.startswith(('BR', 'BRA')):
            return 'Soprador'
        elif model_upper.startswith(('BG', 'BGA')):
            return 'Soprador de Mão'
        elif model_upper.startswith(('HT', 'HTA')):
            return 'Podador'
        elif model_upper.startswith(('KM', 'KMA')):
            return 'Sistema Multifuncional'
        elif re.match(r'^\d+$', model_upper):
            return 'Motosserra'  # Modelos numéricos são geralmente motosserras
        else:
            return 'Equipamento'
    
    def process_xlsx(self) -> bool:
        """Processar arquivo XLSX"""
        if not self.xlsx_path.exists():
            print(f"✗ Arquivo não encontrado: {self.xlsx_path}")
            return False
        
        try:
            print(f"📊 Carregando {self.xlsx_path.name}...")
            
            # Tentar diferentes abas/sheets
            excel_file = pd.ExcelFile(self.xlsx_path)
            print(f"   Abas disponíveis: {excel_file.sheet_names}")
            
            # Usar primeira aba ou procurar por nomes comuns
            sheet_name = excel_file.sheet_names[0]
            for common_name in ['Lista', 'Catálogo', 'Peças', 'Sheet1']:
                if common_name in excel_file.sheet_names:
                    sheet_name = common_name
                    break
            
            df = pd.read_excel(self.xlsx_path, sheet_name=sheet_name)
            print(f"   Usando aba: {sheet_name}")
            print(f"   Colunas: {list(df.columns)}")
            
        except Exception as e:
            print(f"✗ Erro ao ler arquivo: {e}")
            return False
        
        # Detectar colunas automaticamente
        columns_map = self.detect_columns(df)
        if not columns_map:
            print("✗ Não foi possível detectar as colunas necessárias")
            return False
        
        print(f"   Mapeamento de colunas: {columns_map}")
        
        # Processar dados
        return self.process_data(df, columns_map)
    
    def detect_columns(self, df: pd.DataFrame) -> Optional[Dict[str, str]]:
        """Detectar mapeamento de colunas automaticamente"""
        columns_lower = [col.lower() if isinstance(col, str) else str(col).lower() 
                        for col in df.columns]
        
        mapping = {}
        
        # Detectar coluna de código de peça
        for i, col in enumerate(columns_lower):
            if any(term in col for term in ['codigo', 'code', 'peça', 'peca', 'part']):
                mapping['part_code'] = df.columns[i]
                break
        
        # Detectar coluna de descrição
        for i, col in enumerate(columns_lower):
            if any(term in col for term in ['descri', 'nome', 'description', 'desc']):
                mapping['description'] = df.columns[i]
                break
        
        # Detectar coluna de preço
        for i, col in enumerate(columns_lower):
            if any(term in col for term in ['preco', 'preço', 'price', 'valor', 'brl']):
                mapping['price'] = df.columns[i]
                break
        
        # Detectar coluna de modelo
        for i, col in enumerate(columns_lower):
            if any(term in col for term in ['modelo', 'model', 'compativel', 'compatible']):
                mapping['model'] = df.columns[i]
                break
        
        # Validar se encontrou pelo menos código e descrição
        if 'part_code' not in mapping or 'description' not in mapping:
            print("✗ Colunas essenciais não detectadas (código e descrição)")
            return None
        
        return mapping
    
    def process_data(self, df: pd.DataFrame, columns_map: Dict[str, str]) -> bool:
        """Processar os dados do DataFrame"""
        print(f"🔄 Processando {len(df)} linhas...")
        
        # Estruturas para os CSVs
        models_data = set()  # Para evitar duplicatas
        parts_data = {}
        prices_data = []
        compat_data = []
        
        # Processar linha por linha
        for idx, row in df.iterrows():
            self.stats['total_rows'] += 1
            
            try:
                # Extrair dados básicos
                part_code = self.normalize_part_code(row[columns_map['part_code']])
                description = str(row[columns_map['description']]).strip() if pd.notna(row[columns_map['description']]) else None
                
                # Validar dados essenciais
                if not part_code:
                    self.log_error(idx + 2, "Código de peça inválido", {'part_code': row[columns_map['part_code']]})
                    continue
                
                if not description:
                    self.log_error(idx + 2, "Descrição ausente")
                    continue
                
                # Dados da peça
                parts_data[part_code] = {
                    'part_code': part_code,
                    'description': description,
                    'category': self.extract_category_from_description(description)
                }
                
                # Processar preço se disponível
                if 'price' in columns_map and pd.notna(row[columns_map['price']]):
                    price = self.normalize_price(row[columns_map['price']])
                    if price:
                        prices_data.append({
                            'part_code': part_code,
                            'price_brl': price,
                            'price_list': 'sugerida'
                        })
                
                # Processar modelo/compatibilidade se disponível
                if 'model' in columns_map and pd.notna(row[columns_map['model']]):
                    models_list = self.parse_models(str(row[columns_map['model']]))
                    
                    for model_code in models_list:
                        # Adicionar modelo
                        models_data.add((model_code, 'STIHL', self.extract_category_from_model(model_code)))
                        
                        # Adicionar compatibilidade
                        compat_data.append({
                            'part_code': part_code,
                            'model_code_std': model_code
                        })
                
                self.stats['valid_rows'] += 1
                
            except Exception as e:
                self.log_error(idx + 2, f"Erro no processamento: {str(e)}")
                continue
        
        # Gerar CSVs
        return self.generate_csvs(models_data, parts_data, prices_data, compat_data)
    
    def extract_category_from_description(self, description: str) -> str:
        """Extrair categoria da descrição da peça"""
        desc_lower = description.lower()
        
        # Categorias baseadas em palavras-chave
        if any(term in desc_lower for term in ['carburador', 'carb']):
            return 'Carburador'
        elif any(term in desc_lower for term in ['corrente', 'chain']):
            return 'Corrente'
        elif any(term in desc_lower for term in ['barra', 'guide', 'guia']):
            return 'Barra'
        elif any(term in desc_lower for term in ['filtro', 'filter']):
            return 'Filtro'
        elif any(term in desc_lower for term in ['vela', 'spark', 'ignição']):
            return 'Ignição'
        elif any(term in desc_lower for term in ['cabeçote', 'cabecote', 'head']):
            return 'Cabeçote de Corte'
        elif any(term in desc_lower for term in ['fio', 'linha', 'nylon']):
            return 'Fio de Corte'
        elif any(term in desc_lower for term in ['pinhão', 'pinhao', 'sprocket']):
            return 'Transmissão'
        elif any(term in desc_lower for term in ['anel', 'ring', 'retenção']):
            return 'Vedação'
        else:
            return 'Peça'
    
    def parse_models(self, models_str: str) -> List[str]:
        """Parsear string de modelos (pode conter múltiplos)"""
        if not models_str.strip():
            return []
        
        # Separadores comuns
        separators = [',', ';', '/', '|', ' e ', ' E ']
        models_list = [models_str]
        
        for sep in separators:
            new_list = []
            for model in models_list:
                new_list.extend([m.strip() for m in model.split(sep)])
            models_list = new_list
        
        # Normalizar e filtrar
        normalized_models = []
        for model in models_list:
            normalized = self.normalize_model_code(model)
            if normalized:
                normalized_models.append(normalized)
        
        return normalized_models
    
    def generate_csvs(self, models_data: set, parts_data: dict, 
                     prices_data: list, compat_data: list) -> bool:
        """Gerar arquivos CSV"""
        try:
            # models.csv
            if models_data:
                models_df = pd.DataFrame(list(models_data), 
                                       columns=['model_code_std', 'brand', 'category'])
                models_path = self.output_dir / 'models.csv'
                models_df.to_csv(models_path, index=False)
                print(f"✅ {models_path}: {len(models_df)} modelos")
            
            # parts.csv
            if parts_data:
                parts_df = pd.DataFrame(list(parts_data.values()))
                parts_path = self.output_dir / 'parts.csv'
                parts_df.to_csv(parts_path, index=False)
                print(f"✅ {parts_path}: {len(parts_df)} peças")
            
            # part_prices.csv
            if prices_data:
                prices_df = pd.DataFrame(prices_data)
                prices_path = self.output_dir / 'part_prices.csv'
                prices_df.to_csv(prices_path, index=False)
                print(f"✅ {prices_path}: {len(prices_df)} preços")
            
            # part_compat.csv
            if compat_data:
                compat_df = pd.DataFrame(compat_data)
                compat_path = self.output_dir / 'part_compat.csv'
                compat_df.to_csv(compat_path, index=False)
                print(f"✅ {compat_path}: {len(compat_df)} compatibilidades")
            
            return True
            
        except Exception as e:
            print(f"✗ Erro ao gerar CSVs: {e}")
            return False
    
    def print_report(self):
        """Imprimir relatório final"""
        print(f"\n📊 RELATÓRIO DE CONVERSÃO")
        print(f"Total de linhas: {self.stats['total_rows']}")
        print(f"Linhas válidas: {self.stats['valid_rows']}")
        print(f"Linhas com erro: {len(self.stats['errors'])}")
        
        if self.stats['errors']:
            print(f"\n❌ ERROS ENCONTRADOS ({len(self.stats['errors'])} primeiros):")
            for error in self.stats['errors'][:10]:
                print(f"  Linha {error['row']}: {error['error']}")
            
            if len(self.stats['errors']) > 10:
                print(f"  ... e mais {len(self.stats['errors']) - 10} erros")

def main():
    parser = argparse.ArgumentParser(description='Converter XLSX para CSVs do catálogo STIHL')
    parser.add_argument('xlsx_file', help='Arquivo XLSX de entrada')
    parser.add_argument('--output-dir', default='out_csv', help='Diretório de saída (padrão: out_csv)')
    
    args = parser.parse_args()
    
    # Converter
    converter = XLSXConverter(args.xlsx_file, args.output_dir)
    
    success = converter.process_xlsx()
    converter.print_report()
    
    if success:
        print(f"\n🎉 Conversão concluída! Arquivos salvos em: {converter.output_dir}")
        print(f"\nPróximos passos:")
        print(f"1. Importar CSVs no banco de dados")
        print(f"2. Executar: SELECT oficina.apply_part_compat_staging();")
    else:
        print(f"\n❌ Conversão falhou!")
        sys.exit(1)

if __name__ == "__main__":
    main()