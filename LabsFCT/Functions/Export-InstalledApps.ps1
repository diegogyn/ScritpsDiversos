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
            $apps += Get-ItemProperty $path | Where-Object { $_.DisplayName -ne $null }
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
}s