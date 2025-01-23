#Requires -Version 5
<#
.SYNOPSIS
    Script de manutenção do Windows com interface interativa
.DESCRIPTION
    Execute diretamente com: irm [URL_RAW_AQUI] | iex
#>

function Show-Menu {
    Clear-Host
    Write-Host "════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "       SUPER TOOL DE MANUTENÇÃO     " -ForegroundColor Yellow
    Write-Host "════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " 1. 🔄 Atualizar Políticas de Grupo" -ForegroundColor Green
    Write-Host " 2. 🛒 Resetar Loja Windows" -ForegroundColor Blue
    Write-Host " 3. 🚀 Reiniciar Computador" -ForegroundColor Magenta
    Write-Host " 4. ❌ Sair do Script" -ForegroundColor Red
    Write-Host "════════════════════════════════════" -ForegroundColor Cyan
}

function Update-GroupPolicies {
    Write-Host "`n[🔄] Atualizando políticas de grupo..." -ForegroundColor Yellow
    gpupdate /force *>&1 | Out-Null
    Write-Host "[✅] Políticas atualizadas com sucesso!" -ForegroundColor Green
    Read-Host "`nPressione Enter para continuar..."
}

function Invoke-StoreReset {
    Write-Host "`n[🛠️] Resetando permissões da WindowsApps..." -ForegroundColor Yellow
    Start-Process icacls -ArgumentList "`"C:\Program Files\WindowsApps`" /reset /t /c /q" -Wait -NoNewWindow
    
    Write-Host "`n[🌀] Iniciando WSReset..." -ForegroundColor Yellow
    $wsProcess = Start-Process wsreset -PassThru
    Write-Host "[⏳] Aguardando 30 segundos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    Write-Host "`n[⚡] Finalizando processos..." -ForegroundColor Yellow
    taskkill /IM wsreset.exe /F *>&1 | Out-Null
    taskkill /IM WinStore.App.exe /F *>&1 | Out-Null
    Write-Host "[✅] Loja Windows resetada com sucesso!" -ForegroundColor Green
    Read-Host "`nPressione Enter para continuar..."
}

function Restart-Computer {
    Write-Host "`n[⚠️] ATENÇÃO: O computador será reiniciado em 15 segundos!" -ForegroundColor Red
    shutdown /r /f /t 15
    Write-Host "[⌛] Finalizando script em 5 segundos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    exit
}

# Execução principal
while ($true) {
    try {
        Show-Menu
        $choice = Read-Host "`nDigite a opção desejada [1-4]"
        
        switch ($choice) {
            '1' { Update-GroupPolicies }
            '2' { Invoke-StoreReset }
            '3' { Restart-Computer }
            '4' { exit }
            default {
                Write-Host "[❌] Opção inválida!" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
    catch {
        Write-Host "[❗] Erro: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Pressione Enter para continuar..."
    }
}
