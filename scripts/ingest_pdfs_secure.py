#!/usr/bin/env python3
"""
STIHL Assistente Virtual - Ingestão Segura de PDFs
Arquivo: scripts/ingest_pdfs_secure.py

Este script processa PDFs de vistas explodidas STIHL e extrai informações estruturadas
para a tabela doc_facts, sem armazenar texto bruto acessível pelos clientes.
"""

import argparse
import os
import sys
import re
import hashlib
from pathlib import Path
from typing import List, Dict, Optional, Tuple
import fitz  # PyMuPDF
import psycopg
from psycopg.rows import dict_row
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

class PDFProcessor:
    def __init__(self, db_url: str):
        self.db_url = db_url
        self.conn = None
        
    def connect_db(self):
        """Conectar ao banco de dados"""
        try:
            self.conn = psycopg.connect(self.db_url, row_factory=dict_row)
            print(f"✓ Conectado ao banco de dados")
        except Exception as e:
            print(f"✗ Erro ao conectar ao banco: {e}")
            sys.exit(1)
    
    def extract_model_from_filename(self, filename: str) -> str:
        """Extrair código do modelo do nome do arquivo"""
        # Remover extensão
        name = Path(filename).stem.upper()
        
        # Padrões comuns: MS250, FS55, 08, etc.
        model_patterns = [
            r'(MS\s*\d+[A-Z]*)',
            r'(FS\s*\d+[A-Z]*)', 
            r'(BR\s*\d+[A-Z]*)',
            r'(BG\s*\d+[A-Z]*)',
            r'(\b\d{2,3}[A-Z]*\b)',  # Modelos só numéricos como 08, 250
        ]
        
        for pattern in model_patterns:
            match = re.search(pattern, name)
            if match:
                return re.sub(r'\s+', '', match.group(1))  # Remove espaços
        
        # Fallback: usar nome do arquivo limpo
        return re.sub(r'[^A-Z0-9]', '', name)[:20]
    
    def is_heading_line(self, text: str) -> bool:
        """Detectar se uma linha é um cabeçalho de seção"""
        text = text.strip()
        
        # Padrões típicos de cabeçalhos em vistas explodidas
        heading_patterns = [
            r'^[A-Z][a-z\s]+$',  # Ex: "Motor", "Carburador"
            r'^\d+\.\s*[A-Z][a-z\s]+',  # Ex: "1. Motor principal"
            r'^[A-Z\s]{10,}$',  # Texto em maiúsculas longo
            r'^[A-Z][a-z\s]+(:|;)$',  # Cabeçalho com dois pontos
        ]
        
        return any(re.match(pattern, text) for pattern in heading_patterns)
    
    def parse_part_line(self, line: str) -> Optional[Dict]:
        """Parsear uma linha que pode conter informação de peça"""
        line = line.strip()
        if not line or len(line) < 10:
            return None
        
        # Padrões para linhas de peça em vistas explodidas:
        # "1   1108-120-0613   Carburador LA-S8A"
        # "2   4228/15         Carburador"
        # "10  Anel de retenção  0000-967-1500"
        
        patterns = [
            # Item + Código + Descrição
            r'^(\d+)\s+([A-Z0-9\-/\.]{8,})\s+(.+)$',
            # Item + Descrição + Código
            r'^(\d+)\s+(.+?)\s+([A-Z0-9\-/\.]{8,})$',
            # Apenas Código + Descrição (sem item number)
            r'^([A-Z0-9\-/\.]{8,})\s+(.+)$',
        ]
        
        for i, pattern in enumerate(patterns):
            match = re.match(pattern, line)
            if match:
                groups = match.groups()
                
                if i == 0:  # Item + Código + Descrição
                    return {
                        'item_number': int(groups[0]),
                        'part_code': self.normalize_part_code(groups[1]),
                        'part_desc': groups[2].strip()
                    }
                elif i == 1:  # Item + Descrição + Código
                    return {
                        'item_number': int(groups[0]),
                        'part_code': self.normalize_part_code(groups[2]),
                        'part_desc': groups[1].strip()
                    }
                elif i == 2:  # Código + Descrição
                    return {
                        'item_number': None,
                        'part_code': self.normalize_part_code(groups[0]),
                        'part_desc': groups[1].strip()
                    }
        
        return None
    
    def normalize_part_code(self, code: str) -> str:
        """Normalizar código de peça"""
        # Remove espaços e normaliza hífens/barras
        normalized = re.sub(r'\s+', '', code.upper())
        return normalized
    
    def extract_facts_from_pdf(self, pdf_path: str) -> List[Dict]:
        """Extrair fatos estruturados de um PDF"""
        facts = []
        
        try:
            doc = fitz.open(pdf_path)
            model_code = self.extract_model_from_filename(pdf_path)
            
            print(f"  📄 Processando {Path(pdf_path).name} (modelo: {model_code})")
            
            current_heading = None
            
            for page_num in range(len(doc)):
                page = doc[page_num]
                
                # Extrair texto linha por linha
                text_dict = page.get_text("dict")
                lines = []
                
                for block in text_dict.get("blocks", []):
                    if "lines" in block:
                        for line in block["lines"]:
                            line_text = ""
                            for span in line["spans"]:
                                line_text += span["text"]
                            if line_text.strip():
                                lines.append(line_text.strip())
                
                # Processar cada linha
                for line in lines:
                    # Verificar se é cabeçalho
                    if self.is_heading_line(line):
                        current_heading = line.strip()
                        continue
                    
                    # Tentar parsear como linha de peça
                    part_info = self.parse_part_line(line)
                    if part_info:
                        fact = {
                            'page': page_num + 1,
                            'fact_type': 'part_info',
                            'model_code': model_code,
                            'part_code': part_info['part_code'],
                            'part_desc': part_info['part_desc'],
                            'heading': current_heading,
                            'item_number': part_info['item_number']
                        }
                        facts.append(fact)
            
            doc.close()
            
        except Exception as e:
            print(f"  ✗ Erro ao processar {pdf_path}: {e}")
        
        return facts
    
    def upload_to_storage(self, pdf_path: str, bucket: str) -> Optional[str]:
        """Upload do PDF para Supabase Storage"""
        # Esta função seria implementada com a biblioteca supabase-py
        # Por simplicidade, retornamos um path simulado
        filename = Path(pdf_path).name
        storage_path = f"manuals/{filename}"
        
        print(f"  📤 Upload simulado para bucket '{bucket}': {storage_path}")
        return storage_path
    
    def save_doc_metadata(self, pdf_path: str, model_code: str, storage_path: Optional[str] = None) -> int:
        """Salvar metadados do documento"""
        filename = Path(pdf_path).name
        
        # Contar páginas
        try:
            doc = fitz.open(pdf_path)
            page_count = len(doc)
            doc.close()
        except:
            page_count = None
        
        query = """
        INSERT INTO oficina.docs (filename, title, model_code, storage_path, page_count)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (filename) DO UPDATE SET
            title = EXCLUDED.title,
            model_code = EXCLUDED.model_code,
            storage_path = EXCLUDED.storage_path,
            page_count = EXCLUDED.page_count
        RETURNING id
        """
        
        with self.conn.cursor() as cur:
            cur.execute(query, (filename, filename, model_code, storage_path, page_count))
            result = cur.fetchone()
            self.conn.commit()
            return result['id']
    
    def save_facts(self, doc_id: int, facts: List[Dict], replace: bool = False):
        """Salvar fatos estruturados no banco"""
        if replace:
            # Remover fatos existentes do documento
            with self.conn.cursor() as cur:
                cur.execute("DELETE FROM oficina.doc_facts WHERE doc_id = %s", (doc_id,))
        
        if not facts:
            return
        
        query = """
        INSERT INTO oficina.doc_facts 
        (doc_id, page, fact_type, model_code, part_code, part_desc, heading, item_number)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT DO NOTHING
        """
        
        with self.conn.cursor() as cur:
            for fact in facts:
                cur.execute(query, (
                    doc_id,
                    fact['page'],
                    fact['fact_type'],
                    fact['model_code'],
                    fact['part_code'],
                    fact['part_desc'],
                    fact['heading'],
                    fact['item_number']
                ))
            
            self.conn.commit()
            print(f"  💾 {len(facts)} fatos salvos no banco")
    
    def upsert_parts(self, facts: List[Dict]):
        """Fazer upsert das peças encontradas na tabela parts"""
        unique_parts = {}
        
        for fact in facts:
            part_code = fact['part_code']
            if part_code not in unique_parts:
                unique_parts[part_code] = {
                    'description': fact['part_desc'],
                    'category': 'Vista Explodida'
                }
        
        query = """
        INSERT INTO oficina.parts (part_code, description, category)
        VALUES (%s, %s, %s)
        ON CONFLICT (part_code) DO UPDATE SET
            description = CASE 
                WHEN LENGTH(EXCLUDED.description) > LENGTH(parts.description) 
                THEN EXCLUDED.description 
                ELSE parts.description 
            END
        """
        
        with self.conn.cursor() as cur:
            for part_code, info in unique_parts.items():
                cur.execute(query, (part_code, info['description'], info['category']))
            
            self.conn.commit()
            print(f"  🔧 {len(unique_parts)} peças atualizadas no catálogo")
    
    def link_compatibility(self, facts: List[Dict]):
        """Criar links de compatibilidade baseados nos fatos"""
        query_model = "SELECT id FROM oficina.models WHERE oficina.norm_model(model_code_std) = oficina.norm_model(%s) LIMIT 1"
        query_compat = """
        INSERT INTO oficina.part_compat (part_code, model_id, note)
        VALUES (%s, %s, %s)
        ON CONFLICT (part_code, model_id) DO NOTHING
        """
        
        model_cache = {}
        
        with self.conn.cursor() as cur:
            for fact in facts:
                model_code = fact['model_code']
                part_code = fact['part_code']
                
                # Cache do model_id
                if model_code not in model_cache:
                    cur.execute(query_model, (model_code,))
                    result = cur.fetchone()
                    model_cache[model_code] = result['id'] if result else None
                
                model_id = model_cache[model_code]
                if model_id:
                    note = f"Extraído de vista explodida - {fact.get('heading', '')}"
                    cur.execute(query_compat, (part_code, model_id, note.strip()))
            
            self.conn.commit()
            compatible_parts = len([f for f in facts if model_cache.get(f['model_code'])])
            print(f"  🔗 {compatible_parts} compatibilidades criadas")
    
    def process_pdfs(self, pdf_dir: str, bucket: Optional[str] = None, 
                    upload: bool = False, replace: bool = False, 
                    upsert_parts: bool = False, link_compat: bool = False):
        """Processar todos os PDFs de um diretório"""
        pdf_path = Path(pdf_dir)
        
        if not pdf_path.exists():
            print(f"✗ Diretório não encontrado: {pdf_dir}")
            return
        
        pdf_files = list(pdf_path.glob("*.pdf"))
        if not pdf_files:
            print(f"✗ Nenhum arquivo PDF encontrado em: {pdf_dir}")
            return
        
        print(f"📚 Processando {len(pdf_files)} PDFs de {pdf_dir}")
        
        for pdf_file in pdf_files:
            print(f"\n🔄 {pdf_file.name}")
            
            try:
                # Extrair fatos
                facts = self.extract_facts_from_pdf(str(pdf_file))
                
                if not facts:
                    print(f"  ⚠️  Nenhum fato extraído de {pdf_file.name}")
                    continue
                
                # Upload opcional
                storage_path = None
                if upload and bucket:
                    storage_path = self.upload_to_storage(str(pdf_file), bucket)
                
                # Salvar metadados
                model_code = self.extract_model_from_filename(pdf_file.name)
                doc_id = self.save_doc_metadata(str(pdf_file), model_code, storage_path)
                
                # Salvar fatos
                self.save_facts(doc_id, facts, replace)
                
                # Ações opcionais
                if upsert_parts:
                    self.upsert_parts(facts)
                
                if link_compat:
                    self.link_compatibility(facts)
                
                print(f"  ✅ Concluído: {len(facts)} fatos processados")
                
            except Exception as e:
                print(f"  ✗ Erro ao processar {pdf_file.name}: {e}")
                continue
        
        print(f"\n🎉 Processamento concluído!")

def main():
    parser = argparse.ArgumentParser(description='Ingestão segura de PDFs STIHL')
    parser.add_argument('--pdfs', required=True, help='Diretório com os PDFs')
    parser.add_argument('--bucket', help='Nome do bucket para upload')
    parser.add_argument('--upload', action='store_true', help='Fazer upload dos PDFs')
    parser.add_argument('--replace', action='store_true', help='Substituir fatos existentes')
    parser.add_argument('--upsert-parts', action='store_true', help='Atualizar catálogo de peças')
    parser.add_argument('--link-compat', action='store_true', help='Criar compatibilidades')
    
    args = parser.parse_args()
    
    # Obter URL do banco
    db_url = os.getenv('SUPABASE_DB_URL')
    if not db_url:
        print("✗ Variável SUPABASE_DB_URL não definida")
        sys.exit(1)
    
    # Inicializar processor
    processor = PDFProcessor(db_url)
    processor.connect_db()
    
    try:
        processor.process_pdfs(
            pdf_dir=args.pdfs,
            bucket=args.bucket,
            upload=args.upload,
            replace=args.replace,
            upsert_parts=args.upsert_parts,
            link_compat=args.link_compat
        )
    finally:
        if processor.conn:
            processor.conn.close()

if __name__ == "__main__":
    main()