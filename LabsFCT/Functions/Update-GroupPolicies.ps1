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