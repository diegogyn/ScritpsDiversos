#Requires -Version 5
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Script Modular de Manutenção Windows - UFG Campus Aparecida
.DESCRIPTION
    Execute com: irm RAW_URL_MAIN | iex
.NOTES
    Versão: 2.4
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
    Write-Host " 7. 🧼 Labs Limpeza do Windows" -ForegroundColor DarkCyan
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
        $logPath = "C:\Windows\Logs\UFG-Limpeza-Labs"
        $logFile = "$logPath\Limpeza-Labs-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        
        # Criar diretório de logs se não existir
        if (-not (Test-Path $logPath)) { 
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null 
            Write-Host "[📁] Diretório de logs criado: $logPath" -ForegroundColor Cyan
        }

        # Função auxiliar para registrar logs
        function Write-Log {
            param([string]$Message, [string]$Level = "INFO")
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp][$Level] $Message"
            Add-Content -Path $logFile -Value $logEntry
            Write-Host $logEntry -ForegroundColor $(switch ($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } default { "White" } })
        }

        Write-Log "Iniciando limpeza avançada de laboratório..."

        # 1. Limpeza básica do sistema
        Write-Log "Etapa 1/4: Limpeza básica do sistema"
        try {
            $tempFolders = @("$env:TEMP\*", "C:\Windows\Temp\*")
            foreach ($folder in $tempFolders) {
                Write-Log "Limpando: $folder"
                Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                Write-Log "Sucesso: $folder limpo"
            }
            Write-Log "Esvaziando Lixeira"
            Clear-RecycleBin -Force -ErrorAction Stop -Confirm:$false
            Write-Log "Lixeira esvaziada"
        }
        catch {
            Write-Log "Falha na limpeza básica: $($_.Exception.Message)" -Level "ERROR"
        }

        # 2. Processar perfis de usuário
        Write-Log "Etapa 2/4: Processando perfis de usuário"
        try {
            $Users = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { 
                $_.Special -eq $false -and $_.Loaded -eq $false 
            }
            Write-Log "Perfis encontrados: $($Users.Count)"

            foreach ($User in $Users) {
                try {
                    $UserPath = $User.LocalPath
                    $SID = $User.SID
                    Write-Log "Processando perfil: $UserPath (SID: $SID)"

                    # Carregar registry hive
                    Write-Log "Carregando hive do registro: $UserPath\ntuser.dat"
                    reg load "HKU\$SID" "$UserPath\ntuser.dat" 2>&1 | Tee-Object -FilePath $logFile -Append
                    if ($LASTEXITCODE -ne 0) {
                        throw "Falha ao carregar hive do registro (Código: $LASTEXITCODE)"
                    }

                    # 2.1 Pastas críticas para limpeza
                    $PastasParaLimpar = @(
                        "$UserPath\Desktop\*",
                        "$UserPath\Downloads\*",
                        "$UserPath\AppData\Local\Temp\*",
                        "$UserPath\AppData\Local\Microsoft\Windows\INetCache\*",
                        "$UserPath\AppData\Local\Microsoft\Windows\History\*",
                        "$UserPath\AppData\Roaming\Microsoft\Windows\Recent\*"
                    )

                    foreach ($Pasta in $PastasParaLimpar) {
                        try {
                            if (Test-Path $Pasta) {
                                Write-Log "Limpando: $Pasta"
                                Remove-Item $Pasta -Recurse -Force -ErrorAction Stop -Confirm:$false
                                Write-Log "Sucesso:" $Pasta
                            }
                        }
                        catch {
                            Write-Log "Erro ao limpar $Pasta: $($_.Exception.Message)" -Level "ERROR"
                        }
                    }

                    # 2.3 Preservar ícones do desktop
                    try {
                        Write-Log "Preservando ícones do desktop"
                        $ItensPreservar = @('desktop.ini', '*.lnk')
                        Get-ChildItem "$UserPath\Desktop" -Exclude $ItensPreservar | 
                            Remove-Item -Recurse -Force -ErrorAction Stop
                    }
                    catch {
                        Write-Log "Erro ao processar desktop: $($_.Exception.Message)" -Level "ERROR"
                    }

                    # 2.4 Reset navegadores
                    $Browsers = @(
                        @{ Name = "Chrome"; Path = "$UserPath\AppData\Local\Google\Chrome\User Data\Default" },
                        @{ Name = "Edge"; Path = "$UserPath\AppData\Local\Microsoft\Edge\User Data\Default" },
                        @{ Name = "Firefox"; Path = "$UserPath\AppData\Roaming\Mozilla\Firefox\Profiles\*" }
                    )

                    foreach ($Browser in $Browsers) {
                        try {
                            if (Test-Path $Browser.Path) {
                                Write-Log "Resetando $($Browser.Name): $($Browser.Path)"
                                Remove-Item "$($Browser.Path)\*" -Recurse -Force -Exclude 'Bookmarks','Preferences' -ErrorAction Stop
                                Write-Log "Sucesso: $($Browser.Name) resetado"
                            }
                        }
                        catch {
                            Write-Log "Erro ao resetar $($Browser.Name): $($_.Exception.Message)" -Level "ERROR"
                        }
                    }

                    # 2.5 Credenciais
                    try {
                        Write-Log "Removendo credenciais armazenadas"
                        $credenciais = cmdkey /list | Where-Object { $_ -like "*Target:*" }
                        foreach ($credencial in $credenciais) {
                            $target = ($credencial -split ' ')[2]
                            cmdkey /del:$target 2>&1 | Tee-Object -FilePath $logFile -Append
                            Write-Log "Credencial removida: $target"
                        }
                    }
                    catch {
                        Write-Log "Erro ao remover credenciais: $($_.Exception.Message)" -Level "ERROR"
                    }

                    # Descarregar hive
                    Write-Log "Descarregando hive do registro"
                    [gc]::Collect()
                    Start-Sleep -Milliseconds 500
                    reg unload "HKU\$SID" 2>&1 | Tee-Object -FilePath $logFile -Append
                    if ($LASTEXITCODE -ne 0) {
                        throw "Falha ao descarregar hive (Código: $LASTEXITCODE)"
                    }
                }
                catch {
                    Write-Log "Erro no perfil $UserPath: $($_.Exception.Message)" -Level "ERROR"
                }
            }
        }
        catch {
            Write-Log "Falha geral no processamento de perfis: $($_.Exception.Message)" -Level "ERROR"
        }

        # 3. Reset configurações
        Write-Log "Etapa 3/4: Resetando configurações do sistema"
        try {
            Write-Log "Resetando esquemas de energia"
            powercfg /restoredefaultschemes 2>&1 | Tee-Object -FilePath $logFile -Append
            
            Write-Log "Resetando Winsock"
            netsh winsock reset 2>&1 | Tee-Object -FilePath $logFile -Append
            
            Write-Log "Resetando configurações IP"
            netsh int ip reset 2>&1 | Tee-Object -FilePath $logFile -Append
        }
        catch {
            Write-Log "Erro ao resetar configurações: $($_.Exception.Message)" -Level "ERROR"
        }

        # 4. Limpeza profunda
        Write-Log "Etapa 4/4: Limpeza profunda do sistema"
        try {
            Write-Log "Executando cleanmgr"
            Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -NoNewWindow -PassThru | Out-Null
            
            Write-Log "Executando DISM"
            DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Tee-Object -FilePath $logFile -Append
            
            Write-Log "Executando SFC"
            sfc /scannow 2>&1 | Tee-Object -FilePath $logFile -Append
        }
        catch {
            Write-Log "Erro na limpeza profunda: $($_.Exception.Message)" -Level "ERROR"
        }

        Write-Log "Limpeza concluída com sucesso!"
        Write-Host "[⚠] Log detalhado disponível em: $logFile" -ForegroundColor Yellow
        Write-Host "[⚠] Recomenda-se reinicialização" -ForegroundColor Yellow
    }
    catch {
        Write-Log "Erro crítico: $($_.Exception.Message)" -Level "ERROR"
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
