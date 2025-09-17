# Script para Deploy e Configuração do Bot Telegram - STIHL Assistente
# Execute este script após configurar o TELEGRAM_BOT_TOKEN no arquivo .env

Write-Host "🤖 STIHL Assistente - Deploy Bot Telegram" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Verificar se Supabase CLI está instalado
Write-Host "`n1. Verificando Supabase CLI..." -ForegroundColor Yellow
try {
    $supabaseVersion = supabase --version
    Write-Host "✅ Supabase CLI encontrado: $supabaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Supabase CLI não encontrado. Instale com: npm install -g supabase" -ForegroundColor Red
    exit 1
}

# Verificar se está logado no Supabase
Write-Host "`n2. Verificando login no Supabase..." -ForegroundColor Yellow
try {
    supabase projects list | Out-Null
    Write-Host "✅ Logado no Supabase" -ForegroundColor Green
} catch {
    Write-Host "❌ Não logado no Supabase. Execute: supabase login" -ForegroundColor Red
    exit 1
}

# Deploy da Edge Function
Write-Host "`n3. Fazendo deploy da Edge Function 'telegram'..." -ForegroundColor Yellow
try {
    supabase functions deploy telegram
    Write-Host "✅ Edge Function 'telegram' deployada com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro no deploy da Edge Function" -ForegroundColor Red
    exit 1
}

# Obter URL do projeto
Write-Host "`n4. Obtendo URL do projeto..." -ForegroundColor Yellow
$projectRef = "eclmgkajlhrstyyhejev"  # Seu project ID
$functionUrl = "https://$projectRef.supabase.co/functions/v1/telegram"
Write-Host "✅ URL da Edge Function: $functionUrl" -ForegroundColor Green

# Verificar se o token do bot está configurado
Write-Host "`n5. Verificando configuração do bot..." -ForegroundColor Yellow
$envContent = Get-Content .env -Raw
if ($envContent -match "TELEGRAM_BOT_TOKEN=(\w+:\w+)") {
    $botToken = $matches[1]
    Write-Host "✅ Token do bot encontrado" -ForegroundColor Green
    
    # Configurar webhook
    Write-Host "`n6. Configurando webhook do Telegram..." -ForegroundColor Yellow
    $webhookUrl = "https://api.telegram.org/bot$botToken/setWebhook"
    $webhookData = @{
        url = $functionUrl
        allowed_updates = @("message")
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $webhookData -ContentType "application/json"
        if ($response.ok) {
            Write-Host "✅ Webhook configurado com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "❌ Erro ao configurar webhook: $($response.description)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Erro na requisição do webhook: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Verificar status do webhook
    Write-Host "`n7. Verificando status do webhook..." -ForegroundColor Yellow
    $webhookInfoUrl = "https://api.telegram.org/bot$botToken/getWebhookInfo"
    try {
        $webhookInfo = Invoke-RestMethod -Uri $webhookInfoUrl -Method Get
        if ($webhookInfo.ok) {
            Write-Host "✅ Webhook ativo: $($webhookInfo.result.url)" -ForegroundColor Green
            Write-Host "   Última atualização: $($webhookInfo.result.last_error_date)" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ Erro ao verificar webhook" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ Token do bot não encontrado no arquivo .env" -ForegroundColor Red
    Write-Host "   Configure TELEGRAM_BOT_TOKEN no arquivo .env" -ForegroundColor Yellow
    exit 1
}

# Teste da Edge Function
Write-Host "`n8. Testando Edge Function..." -ForegroundColor Yellow
$testData = Get-Content "test_telegram_bot.json" -Raw
try {
    $testResponse = Invoke-RestMethod -Uri $functionUrl -Method Post -Body $testData -ContentType "application/json"
    Write-Host "✅ Teste da Edge Function realizado" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Erro no teste (normal se o bot não estiver totalmente configurado)" -ForegroundColor Yellow
}

Write-Host "`n🎉 DEPLOY CONCLUÍDO!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "1. Procure seu bot no Telegram pelo username configurado" -ForegroundColor White
Write-Host "2. Inicie uma conversa com /start" -ForegroundColor White
Write-Host "3. Teste com: 'Qual o preço do carburador da FS55?'" -ForegroundColor White
Write-Host "`nMonitoramento:" -ForegroundColor Cyan
Write-Host "- Logs: supabase functions logs telegram --follow" -ForegroundColor White
Write-Host "- Status: supabase functions list" -ForegroundColor White
