#Requires -Version 5
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Script Modular de Manutenção Windows - UFG Campus Aparecida
.DESCRIPTION
    Execute com: irm RAW_URL_MAIN | iex
.NOTES
    Versão: 2.2
    Autor: Departamento de TI UFG
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
    Write-Host " 5. 🏛 Aplicar GPOs da FCT" -ForegroundColor Green
    Write-Host " 6. 🧹 Restaurar GPOs Padrão do Windows" -ForegroundColor Blue
    Write-Host " 7. 🚀 Reiniciar Computador" -ForegroundColor Red
    Write-Host " 8. ❌ Sair do Script" -ForegroundColor DarkGray
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Invoke-PressKey {
    Read-Host "`nPressione Enter para continuar..."
}

function Testar-Admin {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "[⚠️] Elevando privilégios..." -ForegroundColor Yellow
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/diegogyn/ScritpsDiversos/refs/heads/master/main.ps1 | iex`"" -Verb RunAs
        exit
    }
}

function Atualizar-PoliticasGrupo {
    try {
        Write-Host "`n[🔄] Forçando atualização de políticas..." -ForegroundColor Yellow
        $output = gpupdate /force 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[✅] Atualização concluída: $($output -join ' ')" -ForegroundColor Green
        }
        else {
            Write-Host "[❌] Erro ${LASTEXITCODE}: $output" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[❗] Erro crítico: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Invoke-PressKey
    }
}

function Reiniciar-LojaWindows {
    try {
        Write-Host "`n[🛠️] Iniciando reset avançado da Microsoft Store..." -ForegroundColor Yellow
        
        $etapas = @(
            @{Nome = "Resetando ACLs"; Comando = { icacls "C:\Program Files\WindowsApps" /reset /t /c /q | Out-Null }},
            @{Nome = "Executando WSReset"; Comando = { Start-Process wsreset -NoNewWindow }},
            @{Nome = "Finalizando processos"; Comando = { taskkill /IM wsreset.exe /IM WinStore.App.exe /F | Out-Null }}
        )

        foreach ($etapa in $etapas) {
            Write-Host "├─ $($etapa.Nome)..." -ForegroundColor Cyan
            & $etapa.Comando
            
            if ($etapa.Nome -eq "Executando WSReset") {
                Write-Host "│  Aguardando conclusão..." -ForegroundColor DarkGray
                Start-Sleep -Seconds 30
            }
        }
        
        Write-Host "[✅] Loja reinicializada com sucesso!`n" -ForegroundColor Green
    }
    catch {
        Write-Host "[❗] Falha no processo: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Invoke-PressKey
    }
}

function Listar-ProgramasInstalados {
    try {
        $dateStamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "apps-instalados-$dateStamp.txt"
        $documentsPath = [Environment]::GetFolderPath("MyDocuments")
        $filePath = Join-Path -Path $documentsPath -ChildPath $fileName

        Write-Host "`n[🔍] Coletando dados de programas instalados..." -ForegroundColor Yellow
        
        $registryPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        $apps = $registryPaths | ForEach-Object {
            Get-ItemProperty $_ | Where-Object DisplayName -ne $null
        } | Sort-Object DisplayName

        $apps | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
            Format-Table -AutoSize |
            Out-File -FilePath $filePath -Width 200

        Write-Host "[📂] Relatório gerado: $filePath" -ForegroundColor Green
        Write-Host "[ℹ️] Programas encontrados: $($apps.Count)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[❗] Erro na geração do relatório: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Invoke-PressKey
    }
}

function Alterar-NomeComputador {
    try {
        $currentName = $env:COMPUTERNAME
        Write-Host "`n[💻] Nome atual do computador: $currentName" -ForegroundColor Cyan
        
        do {
            $newName = Read-Host "`nDigite o novo nome (15 caracteres alfanuméricos)"
        } until ($newName -match '^[a-zA-Z0-9-]{1,15}$')

        if ((Read-Host "`nConfirma alteração para '$newName'? (S/N)") -eq 'S') {
            Rename-Computer -NewName $newName -Force -ErrorAction Stop
            Write-Host "[✅] Nome alterado com sucesso!" -ForegroundColor Green
            
            if ((Read-Host "`nReiniciar agora? (S/N)") -eq 'S') {
                shutdown /r /f /t 15
                exit
            }
        }
    }
    catch {
        Write-Host "[❗] Erro na operação: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Invoke-PressKey
    }
}

function Aplicar-GPOsFCT {
    try {
        Write-Host "`n[🏛️] Conectando ao servidor de políticas..." -ForegroundColor DarkMagenta
        
        $gpoPaths = @{
            User    = "\\fog\gpos\user.txt"
            Machine = "\\fog\gpos\machine.txt"
        }

        if (-not (Test-Path $gpoPaths.User)) { throw "Arquivo User GPO não encontrado" }
        if (-not (Test-Path $gpoPaths.Machine)) { throw "Arquivo Machine GPO não encontrado" }

        $gpoPaths.GetEnumerator() | ForEach-Object {
            Write-Host "├─ Aplicando política $($_.Key)..." -ForegroundColor Cyan
            & "\\fog\gpos\lgpo.exe" /t $_.Value 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Erro ${LASTEXITCODE} na aplicação" }
        }

        Write-Host "[✅] Políticas aplicadas com sucesso!" -ForegroundColor Green
        Write-Host "[⚠️] Recomenda-se reinicialização do sistema" -ForegroundColor Yellow
    }
    catch {
        Write-Host "[❗] Falha na aplicação: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Invoke-PressKey
    }
}

function Restaurar-PoliticasPadrao {
    try {
        Write-Host "`n[🧹] Iniciando restauração de segurança..." -ForegroundColor DarkYellow
        
        $confirm = Read-Host "`nEsta operação REMOVERÁ todas as políticas personalizadas. Continuar? (S/N)"
        if ($confirm -ne 'S') { return }

        $gpoPaths = @(
            "$env:windir\System32\GroupPolicy",
            "$env:windir\System32\GroupPolicyUsers"
        )

        $gpoPaths | ForEach-Object {
            if (Test-Path $_) {
                Remove-Item $_ -Recurse -Force -ErrorAction Stop
                Write-Host "├─ [$(Split-Path $_ -Leaf)] Removido" -ForegroundColor Green
            }
        }

        Write-Host "[✅] Restauração concluída!" -ForegroundColor Green
        Write-Host "[⚠️] Execute a opção 1 para atualizar as políticas" -ForegroundColor Yellow
    }
    catch {
        Write-Host "[❗] Erro na restauração: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Invoke-PressKey
    }
}

function Reiniciar-Computador {
    try {
        Write-Host "`n[🚨] ATENÇÃO: Esta operação é irreversível!" -ForegroundColor Red
        $confirmacao = Read-Host "`nCONFIRME com 'REINICIAR' para prosseguir"
        if ($confirmacao -eq 'REINICIAR') {
            Write-Host "[⏳] Reinício em 15 segundos..." -ForegroundColor Yellow
            shutdown /r /f /t 15
            exit
        }
        else {
            Write-Host "[❌] Operação cancelada" -ForegroundColor Red
        }
    }
    finally {
        Invoke-PressKey
    }
}

# Main Execution
Testar-Admin

while ($true) {
    try {
        Show-Menu
        switch (Read-Host "`nSelecione uma opção [1-8]") {
            '1' { Atualizar-PoliticasGrupo }
            '2' { Reiniciar-LojaWindows }
            '3' { Listar-ProgramasInstalados }
            '4' { Alterar-NomeComputador }
            '5' { Aplicar-GPOsFCT }
            '6' { Restaurar-PoliticasPadrao }
            '7' { Reiniciar-Computador }
            '8' { exit }
            default {
                Write-Host "[❌] Opção inválida!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
    catch {
        Write-Host "[❗] Erro não tratado: $($_.Exception.Message)" -ForegroundColor Red
        Invoke-PressKey
    }
}
