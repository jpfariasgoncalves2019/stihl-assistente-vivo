# STIHL Assistente Virtual - Makefile
# Comandos para desenvolvimento e deploy

# Variáveis
PROJECT_ID ?= $(shell grep 'project_id' supabase/config.toml | cut -d '"' -f 2)
SUPABASE_URL ?= https://$(PROJECT_ID).supabase.co
CHAT_URL = $(SUPABASE_URL)/functions/v1/chat

# Cores para output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help secrets dev deploy logs health test ingest-pdfs import-catalog clean

# Target padrão
help: ## Mostrar esta ajuda
	@echo "$(BLUE)STIHL Assistente Virtual - Comandos Disponíveis$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# Configuração e Secrets
secrets: ## Listar secrets configurados no Supabase
	@echo "$(YELLOW)📋 Secrets configurados:$(NC)"
	@supabase secrets list || echo "$(RED)❌ Erro ao listar secrets$(NC)"

set-secrets: ## Configurar secrets a partir do env.local
	@if [ ! -f env.local ]; then \
		echo "$(RED)❌ Arquivo env.local não encontrado$(NC)"; \
		echo "$(YELLOW)💡 Copie env.local.example e preencha os valores$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🔑 Configurando secrets...$(NC)"
	@supabase secrets set --env-file ./env.local
	@echo "$(GREEN)✅ Secrets configurados$(NC)"

# Desenvolvimento
dev: ## Servir Edge Function localmente
	@echo "$(YELLOW)🚀 Iniciando desenvolvimento local...$(NC)"
	@supabase functions serve chat --no-verify-jwt --env-file ./env.local

dev-with-db: ## Servir com banco local (requer supabase start)
	@echo "$(YELLOW)🚀 Iniciando com banco local...$(NC)"
	@supabase start
	@supabase functions serve chat --env-file ./env.local

# Deploy
deploy: ## Deploy da Edge Function para produção
	@echo "$(YELLOW)🚀 Fazendo deploy da função chat...$(NC)"
	@supabase functions deploy chat
	@echo "$(GREEN)✅ Deploy concluído$(NC)"
	@echo "$(BLUE)🔗 URL: $(CHAT_URL)$(NC)"

# Monitoramento
logs: ## Ver logs da Edge Function
	@echo "$(YELLOW)📄 Logs da Edge Function chat:$(NC)"
	@supabase functions logs chat

logs-follow: ## Seguir logs em tempo real
	@echo "$(YELLOW)📄 Acompanhando logs da função chat...$(NC)"
	@supabase functions logs chat --follow

# Testes e Verificações
health: ## Executar health check do sistema
	@echo "$(YELLOW)🔍 Executando health check...$(NC)"
	@if [ -z "$(SUPABASE_DB_URL)" ]; then \
		echo "$(RED)❌ SUPABASE_DB_URL não definido$(NC)"; \
		exit 1; \
	fi
	@psql "$(SUPABASE_DB_URL)" -f sql/HEALTHCHECK.sql

test: ## Executar testes de aceitação da API
	@echo "$(YELLOW)🧪 Executando testes de aceitação...$(NC)"
	@if [ -z "$(SUPABASE_ANON_KEY)" ]; then \
		echo "$(RED)❌ SUPABASE_ANON_KEY não definido$(NC)"; \
		exit 1; \
	fi
	@$(MAKE) test-carburador-ms08
	@$(MAKE) test-rocadeira-fs80  
	@$(MAKE) test-sanitizacao
	@echo "$(GREEN)✅ Todos os testes concluídos$(NC)"

test-carburador-ms08: ## Teste: carburador MS08
	@echo "   🔧 Testando: carburador MS08"
	@curl -s -X POST "$(CHAT_URL)" \
		-H "Authorization: Bearer $(SUPABASE_ANON_KEY)" \
		-H "Content-Type: application/json" \
		-d '{"message":"Qual o valor do carburador da MS 08?","channel":"web","sender":"test"}' \
		| grep -q "R\$$" && echo "   $(GREEN)✅ PASS$(NC)" || echo "   $(RED)❌ FAIL$(NC)"

test-rocadeira-fs80: ## Teste: múltiplas opções FS80  
	@echo "   🌿 Testando: roçadeira FS80 (múltiplas opções)"
	@curl -s -X POST "$(CHAT_URL)" \
		-H "Authorization: Bearer $(SUPABASE_ANON_KEY)" \
		-H "Content-Type: application/json" \
		-d '{"message":"Qual valor da roçadeira FS80?","channel":"web","sender":"test"}' \
		| grep -q "Código:" && echo "   $(GREEN)✅ PASS$(NC)" || echo "   $(RED)❌ FAIL$(NC)"

test-sanitizacao: ## Teste: sanitização de resposta
	@echo "   🛡️  Testando: sanitização (não deve conter termos proibidos)"
	@curl -s -X POST "$(CHAT_URL)" \
		-H "Authorization: Bearer $(SUPABASE_ANON_KEY)" \
		-H "Content-Type: application/json" \
		-d '{"message":"onde baixar manual da MS250?","channel":"web","sender":"test"}' \
		| grep -qv -E "(pdf|manual|download|link)" && echo "   $(GREEN)✅ PASS$(NC)" || echo "   $(RED)❌ FAIL$(NC)"

# Ingestão de Dados
ingest-pdfs: ## Processar PDFs (uso: make ingest-pdfs DIR=./pdfs)
	@if [ -z "$(DIR)" ]; then \
		echo "$(RED)❌ Especifique o diretório: make ingest-pdfs DIR=./pdfs$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)📚 Processando PDFs de $(DIR)...$(NC)"
	@python scripts/ingest_pdfs_secure.py \
		--pdfs "$(DIR)" \
		--bucket manuals \
		--upload \
		--replace \
		--upsert-parts \
		--link-compat
	@echo "$(GREEN)✅ Ingestão de PDFs concluída$(NC)"

import-catalog: ## Importar catálogo Excel (uso: make import-catalog FILE=lista.xlsx)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)❌ Especifique o arquivo: make import-catalog FILE=lista.xlsx$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)📊 Convertendo $(FILE) para CSVs...$(NC)"
	@python scripts/xlsx_to_catalog_csv.py "$(FILE)" --output-dir out_csv
	@echo "$(YELLOW)📥 Importe os CSVs gerados em out_csv/ no banco de dados$(NC)"
	@echo "$(BLUE)💡 Exemplo de importação:$(NC)"
	@echo "   \\copy oficina.models FROM 'out_csv/models.csv' WITH CSV HEADER"
	@echo "   \\copy oficina.parts FROM 'out_csv/parts.csv' WITH CSV HEADER"
	@echo "   \\copy oficina.part_prices FROM 'out_csv/part_prices.csv' WITH CSV HEADER"
	@echo "   \\copy oficina.part_compat_staging FROM 'out_csv/part_compat.csv' WITH CSV HEADER"
	@echo "   SELECT oficina.apply_part_compat_staging();"

setup-python: ## Instalar dependências Python
	@echo "$(YELLOW)🐍 Instalando dependências Python...$(NC)"
	@pip install pymupdf psycopg[binary] python-dotenv supabase pandas openpyxl
	@echo "$(GREEN)✅ Dependências Python instaladas$(NC)"

# Database
db-setup: ## Executar setup completo do banco
	@echo "$(YELLOW)🗄️  Configurando banco de dados...$(NC)"
	@if [ -z "$(SUPABASE_DB_URL)" ]; then \
		echo "$(RED)❌ SUPABASE_DB_URL não definido$(NC)"; \
		exit 1; \
	fi
	@psql "$(SUPABASE_DB_URL)" -f sql/supabase_setup_consolidated_v3.sql
	@echo "$(GREEN)✅ Banco configurado$(NC)"

db-reset: ## Reset completo do banco (CUIDADO!)
	@echo "$(RED)⚠️  ATENÇÃO: Isso apagará TODOS os dados!$(NC)"
	@read -p "Digite 'CONFIRMO' para continuar: " confirm; \
	if [ "$$confirm" != "CONFIRMO" ]; then \
		echo "$(YELLOW)Operação cancelada$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🗄️  Resetando banco...$(NC)"
	@psql "$(SUPABASE_DB_URL)" -c "DROP SCHEMA IF EXISTS oficina CASCADE;"
	@$(MAKE) db-setup
	@echo "$(GREEN)✅ Banco resetado$(NC)"

# Limpeza
clean: ## Limpar arquivos temporários
	@echo "$(YELLOW)🧹 Limpando arquivos temporários...$(NC)"
	@rm -rf out_csv/
	@rm -rf __pycache__/
	@rm -rf scripts/__pycache__/
	@rm -f *.pyc scripts/*.pyc
	@echo "$(GREEN)✅ Limpeza concluída$(NC)"

# Informações do projeto
info: ## Mostrar informações do projeto
	@echo "$(BLUE)📋 INFORMAÇÕES DO PROJETO$(NC)"
	@echo "Project ID: $(PROJECT_ID)"
	@echo "Supabase URL: $(SUPABASE_URL)"  
	@echo "Chat API URL: $(CHAT_URL)"
	@echo ""
	@echo "$(YELLOW)📁 Estrutura:$(NC)"
	@find . -name "*.sql" -o -name "*.py" -o -name "*.ts" -o -name "*.json" | head -10
	@echo ""
	@echo "$(YELLOW)🔧 Status dos serviços:$(NC)"
	@supabase status 2>/dev/null || echo "Supabase CLI não configurado localmente"

# Backup  
backup: ## Fazer backup dos dados críticos
	@echo "$(YELLOW)💾 Fazendo backup...$(NC)"
	@mkdir -p backup/$(shell date +%Y%m%d_%H%M%S)
	@BACKUP_DIR=backup/$(shell date +%Y%m%d_%H%M%S) && \
	psql "$(SUPABASE_DB_URL)" -c "\copy public.attendant_prompts TO '$$BACKUP_DIR/prompts.csv' WITH CSV HEADER" && \
	psql "$(SUPABASE_DB_URL)" -c "\copy oficina.part_aliases TO '$$BACKUP_DIR/aliases.csv' WITH CSV HEADER" && \
	psql "$(SUPABASE_DB_URL)" -c "\copy public.conversation_logs TO '$$BACKUP_DIR/logs.csv' WITH CSV HEADER"
	@echo "$(GREEN)✅ Backup salvo em backup/$(NC)"

# Ambiente completo
install: setup-python set-secrets db-setup ## Instalação completa do zero
	@echo "$(GREEN)🎉 Instalação completa concluída!$(NC)"
	@echo "$(BLUE)Próximos passos:$(NC)"
	@echo "1. $(YELLOW)make import-catalog FILE=sua_planilha.xlsx$(NC)"
	@echo "2. $(YELLOW)make ingest-pdfs DIR=./pdfs$(NC) (opcional)"
	@echo "3. $(YELLOW)make deploy$(NC)"
	@echo "4. $(YELLOW)make test$(NC)"