function Rename-PC {
    Write-Host "`n[⚠️] Operação sensível - Requer reinicialização!" -ForegroundColor Red
    $currentName = $env:COMPUTERNAME
    $newName = Read-Host "`nDigite o novo nome do computador (atual: $currentName)"

    if (-not $newName -or $newName -notmatch "^[a-zA-Z0-9-]+$") {
        Write-Host "[❌] Nome inválido! Use apenas letras, números e hífens" -ForegroundColor Red
        return
    }

    try {
        Rename-Computer -NewName $newName -Force -ErrorAction Stop
        Write-Host "[✅] Nome alterado para: $newName" -ForegroundColor Green
        
        $choice = Read-Host "`nDeseja reiniciar agora para aplicar as mudanças? [S/N]"
        if ($choice -eq 'S') {
            Restart-Computer
        }
    }
    catch {
        Write-Host "[❗] Erro ao renomear: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "`nPressione Enter para continuar..."
}