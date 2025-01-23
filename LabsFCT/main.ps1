#Requires -Version 5
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Script Modular de Manutenção Windows
.DESCRIPTION
    Execute com: irm RAW_URL_MAIN | iex
#>

$script:ScriptRoot = $PSScriptRoot
$global:ExecutionPath = Get-Location

# Carregar funções
function Import-Functions {
    try {
        $functionsPath = Join-Path -Path $script:ScriptRoot -ChildPath "Functions"
        
        Get-ChildItem -Path "$functionsPath\*.ps1" | ForEach-Object {
            . $_.FullName
            Write-Host "Função carregada: $($_.BaseName)" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "Falha crítica ao carregar funções: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Elevar privilégios se necessário
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Elevando privilégios..." -ForegroundColor Yellow
    $scriptCommand = "irm RAW_URL_MAIN | iex"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -Command `"$scriptCommand`"" -Verb RunAs
    exit
}

# Inicialização
Import-Functions
Clear-Host

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
                Write-Host "Opção inválida!" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
    catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Pressione Enter para continuar..."
    }
}