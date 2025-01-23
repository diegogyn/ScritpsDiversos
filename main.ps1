#Requires -Version 5
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Script Modular de Manutenção Windows - UFG Campus Aparecida
.DESCRIPTION
    Execute com: irm RAW_URL_MAIN | iex
.NOTES
    Versão: 2.3
    Autor: Departamento de TI UFG
#>

function Show-Menu {
    Clear-Host
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
    Write-Host " 1. 📜 Listar Programas Instalados" -ForegroundColor Magenta
    Write-Host " 2. 💻 Alterar Nome do Computador" -ForegroundColor Cyan
    Write-Host " 3. 🏛 Aplicar GPOs da FCT" -ForegroundColor Blue
    Write-Host " 4. 🧹 Restaurar GPOs Padrão do Windows" -ForegroundColor DarkYellow
    Write-Host " 5. 🔄 Atualizar GPOs" -ForegroundColor Green
    Write-Host " 6. 🛒 Reset Windows Store" -ForegroundColor Blue
    Write-Host " 7. 🧼 Limpeza de Labs" -ForegroundColor DarkCyan
    Write-Host " 8. 🚀 Reiniciar Computador" -ForegroundColor Red
    Write-Host " 9. ❌ Sair do Script" -ForegroundColor DarkGray
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Invoke-PressKey {
    Read-Host "`nPressione Enter para continuar..."
}

function Testar-Admin {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "[⚠] Elevando privilégios..." -ForegroundColor Yellow
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/diegogyn/ScritpsDiversos/refs/heads/master/main.ps1 | iex`"" -Verb RunAs
        exit
    }
}

function Listar-ProgramasInstalados {
    try {
        $dateStamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "apps-instalados-$dateStamp.txt"
        $filePath = Join-Path -Path "C:\" -ChildPath $fileName

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

        Write-Host "[📂] Relatório salvo em: $filePath" -ForegroundColor Green
        Write-Host "[ℹ] Programas encontrados: $($apps.Count)" -ForegroundColor Cyan
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
        Write-Host "`n[🏛] Conectando ao servidor de políticas..." -ForegroundColor DarkMagenta
        
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
        Write-Host "[⚠] Recomenda-se reinicialização do sistema" -ForegroundColor Yellow
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
        Write-Host "[⚠] Execute a opção 5 para atualizar as políticas" -ForegroundColor Yellow
    }
    catch {
        Write-Host "[❗] Erro na restauração: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Invoke-PressKey
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
        Write-Host "`n[🛠] Iniciando reset avançado da Microsoft Store..." -ForegroundColor Yellow
        
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

function Limpeza-Labs {
    try {
        Write-Host "`n[🧼] Iniciando limpeza avançada de laboratório..." -ForegroundColor DarkCyan

        # 1. Limpeza básica do sistema
        Write-Host "├─ Etapa 1/4: Limpeza básica do sistema..." -ForegroundColor Cyan
        Remove-Item -Path "$env:TEMP\*", "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue -Confirm:$false
        
        # 2. Processar perfis de usuário
        Write-Host "├─ Etapa 2/4: Processando perfis de usuário..." -ForegroundColor Cyan
        $Users = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { 
            $_.Special -eq $false -and $_.Loaded -eq $false 
        }

        foreach ($User in $Users) {
            try {
                $UserPath = $User.LocalPath
                $SID = $User.SID
                
                Write-Host "│  ├─ Limpando perfil: $(Split-Path $UserPath -Leaf)" -ForegroundColor DarkGray

                # Carregar registry hive
                reg load "HKU\$SID" "$UserPath\ntuser.dat" 2>&1 | Out-Null

                # 2.1 Arquivos temporários
                $UserTempPaths = @(
                    "$UserPath\AppData\Local\Temp\*",
                    "$UserPath\AppData\Local\Microsoft\Windows\INetCache\*",
                    "$UserPath\AppData\Local\Microsoft\Windows\History\*"
                )
                Remove-Item $UserTempPaths -Force -Recurse -ErrorAction SilentlyContinue

                # 2.2 Reset navegadores
                $Browsers = @(
                    @{ Name = "Chrome"; Path = "$UserPath\AppData\Local\Google\Chrome\User Data\Default" },
                    @{ Name = "Edge"; Path = "$UserPath\AppData\Local\Microsoft\Edge\User Data\Default" },
                    @{ Name = "Firefox"; Path = "$UserPath\AppData\Roaming\Mozilla\Firefox\Profiles\*" }
                )

                foreach ($Browser in $Browsers) {
                    if (Test-Path $Browser.Path) {
                        Remove-Item $Browser.Path -Recurse -Force -Exclude 'Bookmarks','Preferences' -ErrorAction SilentlyContinue
                    }
                }

                # 2.3 Personalizações
                Remove-Item "$UserPath\Desktop\*", "$UserPath\Downloads\*" -Force -Exclude 'desktop.ini' -ErrorAction SilentlyContinue
                Remove-Item "$UserPath\AppData\Roaming\Microsoft\Windows\Themes\*" -Force -ErrorAction SilentlyContinue

                # 2.4 Credenciais
                cmdkey /list | ForEach-Object { 
                    if ($_ -like "*Target:*") { cmdkey /del:($_ -split ' ')[2] }
                }

                # Descarregar hive
                [gc]::Collect()
                reg unload "HKU\$SID" 2>&1 | Out-Null

            } catch {
		Write-Host "│  └─ [⚠] Erro no perfil ${UserPath}∶ $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        # 3. Reset configurações
        Write-Host "├─ Etapa 3/4: Resetando configurações..." -ForegroundColor Cyan
        powercfg /restoredefaultschemes | Out-Null
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null

        # 4. Limpeza profunda
        Write-Host "├─ Etapa 4/4: Limpeza profunda..." -ForegroundColor Cyan
        Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -NoNewWindow
        DISM /Online /Cleanup-Image /RestoreHealth | Out-Null
        sfc /scannow | Out-Null

        Write-Host "[✅] Limpeza concluída com sucesso!" -ForegroundColor Green
        Write-Host "[⚠] Recomenda-se reinicialização" -ForegroundColor Yellow
    }
    catch {
        Write-Host "[❗] Erro crítico: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Invoke-PressKey
    }
}

function Reiniciar-Computador {
    try {
        Write-Host "`n[🚨] ATENÇÃO: Operação irreversível!" -ForegroundColor Red
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

# Execução Principal
Testar-Admin

while ($true) {
    try {
        Show-Menu
        switch (Read-Host "`nSelecione uma opção [1-9]") {
            '1' { Listar-ProgramasInstalados }
            '2' { Alterar-NomeComputador }
            '3' { Aplicar-GPOsFCT }
            '4' { Restaurar-PoliticasPadrao }
            '5' { Atualizar-PoliticasGrupo }
            '6' { Reiniciar-LojaWindows }
            '7' { Limpeza-Labs }
            '8' { Reiniciar-Computador }
            '9' { exit }
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
