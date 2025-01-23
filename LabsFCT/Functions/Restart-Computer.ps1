function Restart-Computer {
    Write-Host "`n[⚠️] ATENÇÃO: Operação irreversível!" -ForegroundColor Red
    $confirm = Read-Host "`nTem certeza que deseja reiniciar o computador? (Digite 'CONFIRMAR' para prosseguir)"
    
    if ($confirm -eq 'CONFIRMAR') {
        Write-Host "[⏳] Reiniciando em 15 segundos..." -ForegroundColor Yellow
        shutdown /r /f /t 15
        Write-Host "[⌛] Finalizando script em 5 segundos..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        exit
    }
    else {
        Write-Host "[❌] Operação cancelada pelo usuário" -ForegroundColor Red
        Read-Host "`nPressione Enter para continuar..."
    }
}