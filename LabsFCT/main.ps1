#Requires -Version 5
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Script Modular de Manutenção Windows
.DESCRIPTION
    Execute com: irm RAW_URL_MAIN | iex
#>

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "▓█████▄  ▒█████   ███▄ ▄███▓ ██▓███   █     █░ ▄▄▄       ██▀███  " -ForegroundColor Cyan
    Write-Host "▒██▀ ██▌▒██▒  ██▒▓██▒▀█▀ ██▒▓██░  ██▒▓█░ █ ░█░▒████▄    ▓██ ▒ ██▒" -ForegroundColor Blue
    Write-Host "░██   █▌▒██░  ██▒▓██    ▓██░▓██░ ██▓▒▒█░ █ ░█ ▒██  ▀█▄  ▓██ ░▄█ ▒" -ForegroundColor Magenta
    Write-Host "░▓█▄   ▌▒██   ██░▒██    ▒██ ▒██▄█▓▒ ▒░█░ █ ░█ ░██▄▄▄▄██ ▒██▀▀█▄  " -ForegroundColor Green
    Write-Host "░▒████▓ ░ ████▓▒░▒██▒   ░██▒▒██▒ ░  ░ ░░██▒██▓ ▓█   ▓██▒░██▓ ▒██▒" -ForegroundColor Yellow
    Write-Host " ▒▒▓  ▒ ░ ▒░▒░▒░ ░ ▒░   ░  ░▒▓▒░ ░  ░ ░ ▓░▒ ▒  ▒▒   ▓▒█░░ ▒▓ ░▒▓░" -ForegroundColor Red
    Write-Host " ░ ▒  ▒   ░ ▒ ▒░ ░  ░      ░░▒ ░        ▒ ░ ░   ▒   ▒▒ ░  ░▒ ░ ▒░" -ForegroundColor DarkCyan
    Write-Host " ░ ░  ░ ░ ░ ░ ▒  ░      ░   ░░          ░   ░   ░   ▒     ░░   ░ " -ForegroundColor Gray
    Write-Host "   ░        ░ ░         ░                ░           ░  ░   ░    " -ForegroundColor DarkGray
    Write-Host " ░                                                              " -ForegroundColor DarkMagenta
    Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " 1. 🔄 Atualizar Políticas de Grupo" -ForegroundColor Green
    Write-Host " 2. 🛒 Resetar Loja Windows" -ForegroundColor Blue
    Write-Host " 3. 📜 Listar Programas Instalados" -ForegroundColor Magenta
    Write-Host " 4. 💻 Alterar Nome do Computador" -ForegroundColor Cyan
    Write-Host " 5. 🚀 Reiniciar Computador" -ForegroundColor Red
    Write-Host " 6. ❌ Sair do Script" -ForegroundColor DarkGray
    Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Update-GroupPolicies {
    Write-Host "`n[🔄] Atualizando políticas de grupo..." -ForegroundColor Yellow
    try {
        $output = gpupdate /force 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[✅] Políticas atualizadas com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "[❌] Erro na atualização: $output" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[❗] Erro crítico: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "`nPressione Enter para continuar..."
}

function Invoke-StoreReset {
    Write-Host "`n[🛠️] Iniciando processo de reset da Loja Windows..." -ForegroundColor Yellow
    try {
        Write-Host "├─ Etapa 1/3: Resetando permissões..." -ForegroundColor Cyan
        Start-Process icacls -ArgumentList "`"C:\Program Files\WindowsApps`" /reset /t /c /q" -Wait -NoNewWindow
        
        Write-Host "├─ Etapa 2/3: Executando WSReset..." -ForegroundColor Cyan
        Start-Process wsreset -NoNewWindow
        Write-Host "│  Aguardando 30 segundos..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 30
        
        Write-Host "└─ Etapa 3/3: Finalizando processos..." -ForegroundColor Cyan
        taskkill /IM wsreset.exe /F *>$null
        taskkill /IM WinStore.App.exe /F *>$null
        
        Write-Host "[✅] Processo concluído com sucesso!`n" -ForegroundColor Green
    }
    catch {
        Write-Host "[❗] Erro durante o processo: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "Pressione Enter para continuar..."
}

function Export-InstalledApps {
    $dateStamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $fileName = "apps-instalados-$dateStamp.txt"
    $documentsPath = [Environment]::GetFolderPath("MyDocuments")
    $filePath = Join-Path -Path $documentsPath -ChildPath $fileName

    Write-Host "`n[🔍] Gerando lista de programas instalados..." -ForegroundColor Yellow
    
    try {
        $apps = @()
        $paths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        foreach ($path in $paths) {
            $apps += Get-ItemProperty $path | Where-Object DisplayName -ne $null
        }

        $apps | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
            Sort-Object DisplayName |
            Format-Table -AutoSize |
            Out-File -FilePath $filePath -Width 200

        Write-Host "[📂] Arquivo salvo em: $filePath" -ForegroundColor Green
        Write-Host "[ℹ️] Total de programas listados: $($apps.Count)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[❗] Erro ao gerar lista: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "`nPressione Enter para continuar..."
}

function Rename-PC {
    Write-Host "`n[⚠️] Operação sensível - Requer reinicialização!" -ForegroundColor Red
    $currentName = $env:COMPUTERNAME
    $newName = Read-Host "`nDigite o novo nome do computador (atual: $currentName)"

    if (-not $newName -or $newName -notmatch "^[a-zA-Z0-9-]{1,15}$") {
        Write-Host "[❌] Nome inválido! Use até 15 caracteres (A-Z, 0-9, hífen)" -ForegroundColor Red
        return
    }

    try {
        Rename-Computer -NewName $newName -Force -ErrorAction Stop
        Write-Host "[✅] Nome alterado para: $newName" -ForegroundColor Green
        
        $choice = Read-Host "`nDeseja reiniciar agora para aplicar as mudanças? [S/N]"
        if ($choice -eq 'S') {
            shutdown /r /f /t 15
            exit
        }
    }
    catch {
        Write-Host "[❗] Erro ao renomear: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "`nPressione Enter para continuar..."
}

function Restart-Computer {
    Write-Host "`n[⚠️] ATENÇÃO: Operação irreversível!" -ForegroundColor Red
    $confirm = Read-Host "`nTem certeza que deseja reiniciar o computador? (Digite 'CONFIRMAR' para prosseguir)"
    
    if ($confirm -eq 'CONFIRMAR') {
        Write-Host "[⏳] Reiniciando em 15 segundos..." -ForegroundColor Yellow
        shutdown /r /f /t 15
        exit
    }
    else {
        Write-Host "[❌] Operação cancelada pelo usuário" -ForegroundColor Red
        Read-Host "`nPressione Enter para continuar..."
    }
}

# Verificação de administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[⚠️] Elevando privilégios..." -ForegroundColor Yellow
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -Command `"irm RAW_URL_MAIN | iex`"" -Verb RunAs
    exit
}

# Loop principal
while ($true) {
    try {
        Show-Menu
        $choice = Read-Host "`nDigite a opção desejada [1-6]"
        
        switch ($choice) {
            '1' { Update-GroupPolicies }
            '2' { Invoke-StoreReset }
            '3' { Export-InstalledApps }
            '4' { Rename-PC }
            '5' { Restart-Computer }
            '6' { exit }
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
