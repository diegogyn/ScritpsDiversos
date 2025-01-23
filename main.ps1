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
    # Logo UFG em ASCII Art
    Write-Host @"  

	 ██╗   ██╗███████╗ ██████╗ 
	 ██║   ██║██╔════╝██╔════╝ 
	 ██║   ██║█████╗  ██║  ███╗
	 ██║   ██║██╔══╝  ██║   ██║
	 ╚██████╔╝██║     ╚██████╔╝
	  ╚═════╝ ╚═╝      ╚═════╝ 

    Universidade Federal de Goiás
"@ -ForegroundColor Blue

    Write-Host "`n          Campus Aparecida`n" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " 1. 🔄 Atualizar Políticas de Grupo" -ForegroundColor Green
    Write-Host " 2. 🛒 Resetar Loja Windows" -ForegroundColor Blue
    Write-Host " 3. 📜 Listar Programas Instalados" -ForegroundColor Magenta
    Write-Host " 4. 💻 Alterar Nome do Computador" -ForegroundColor Cyan
    Write-Host " 5. 🚀 Reiniciar Computador" -ForegroundColor Red
    Write-Host " 6. 🏛️ Aplicar GPOs FCT/UFG" -ForegroundColor DarkMagenta
    Write-Host " 7. 🧹 Restaurar Políticas Padrão" -ForegroundColor DarkYellow
    Write-Host " 8. ❌ Sair do Script" -ForegroundColor DarkGray
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Atualizar-PoliticasGrupo {
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

function Reiniciar-LojaWindows {
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

function Listar-ProgramasInstalados {
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

function Alterar-NomeComputador {
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

function Reiniciar-Computador {
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

function Aplicar-GPOsFCT {
    Write-Host "`n[🏛️] Aplicando GPOs da FCT/UFG..." -ForegroundColor DarkMagenta
    try {
        Write-Host "├─ Etapa 1/2: Aplicando GPO do usuário..." -ForegroundColor Cyan
        & "\\fog\gpos\lgpo.exe" /t "\\fog\gpos\user.txt" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Erro na aplicação da GPO do usuário" }

        Write-Host "├─ Etapa 2/2: Aplicando GPO da máquina..." -ForegroundColor Cyan
        & "\\fog\gpos\lgpo.exe" /t "\\fog\gpos\machine.txt" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Erro na aplicação da GPO da máquina" }

        Write-Host "[✅] Políticas aplicadas com sucesso!" -ForegroundColor Green
        Write-Host "[⏳] Finalizando em 5 segundos..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 5
    }
    catch {
        Write-Host "[❗] Falha crítica: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[⚠️] Verifique a conectividade com o servidor FOG" -ForegroundColor Yellow
    }
    Read-Host "`nPressione Enter para continuar..."
}

function Restaurar-PoliticasPadrao {
    Write-Host "`n[🧹] Restaurando políticas padrão do Windows..." -ForegroundColor DarkYellow
    try {
        $paths = @(
            "$env:windir\System32\GroupPolicy",
            "$env:windir\System32\GroupPolicyUsers"
        )

        foreach ($path in $paths) {
            if (Test-Path $path) {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                Write-Host "├─ [$($path.Split('\')[-1])] Removido com sucesso" -ForegroundColor Green
            }
            else {
                Write-Host "├─ [$($path.Split('\')[-1])] Não encontrado" -ForegroundColor DarkGray
            }
        }

        Write-Host "[✅] Restauração concluída com sucesso!" -ForegroundColor Green
        Write-Host "[⚠️] Execute a opção 1 para atualizar as políticas" -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
    catch {
        Write-Host "[❗] Erro durante a operação: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "`nPressione Enter para continuar..."
}

# Verificação de administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[⚠️] Elevando privilégios..." -ForegroundColor Yellow
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/diegogyn/ScritpsDiversos/refs/heads/master/LabsFCT/main.ps1 | iex`"" -Verb RunAs
    exit
}

# Loop principal
while ($true) {
    try {
        Show-Menu
        $choice = Read-Host "`nDigite a opção desejada [1-8]"
        
        switch ($choice) {
            '1' { Atualizar-PoliticasGrupo }
            '2' { Reiniciar-LojaWindows }
            '3' { Listar-ProgramasInstalados }
            '4' { Alterar-NomeComputador }
            '5' { Reiniciar-Computador }
            '6' { Aplicar-GPOsFCT }
            '7' { Restaurar-PoliticasPadrao }
            '8' { exit }
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
