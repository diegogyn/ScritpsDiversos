function Invoke-StoreReset {
    Write-Host "`n[🛠️] Iniciando processo de reset da Loja Windows..." -ForegroundColor Yellow
    try {
        Write-Host "├─ Etapa 1/3: Resetando permissões..." -ForegroundColor Cyan
        Start-Process icacls -ArgumentList "`"C:\Program Files\WindowsApps`" /reset /t /c /q" -Wait -NoNewWindow
        
        Write-Host "├─ Etapa 2/3: Executando WSReset..." -ForegroundColor Cyan
        $wsProcess = Start-Process wsreset -PassThru
        Write-Host "│  Aguardando 30 segundos..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 30
        
        Write-Host "└─ Etapa 3/3: Finalizando processos..." -ForegroundColor Cyan
        taskkill /IM wsreset.exe /F *>&1 | Out-Null
        taskkill /IM WinStore.App.exe /F *>&1 | Out-Null
        
        Write-Host "[✅] Processo concluído com sucesso!`n" -ForegroundColor Green
    }
    catch {
        Write-Host "[❗] Erro durante o processo: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "Pressione Enter para continuar..."
}