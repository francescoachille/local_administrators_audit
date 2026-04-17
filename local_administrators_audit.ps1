<#
.SYNOPSIS
    Script di Audit per l'estrazione dei membri del gruppo 'Administrators' locale.
    Creato per itchronicle.com
#>

function Get-LocalAdminAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]$ComputerNames,
        
        [Parameter()]
        [string]$OutputPath = "Audit_LocalAdmins_Report.csv"
    )

    $results = @()

    foreach ($computer in $ComputerNames) {
        Write-Host "Analisi in corso su: $computer..." -ForegroundColor Cyan
        
        try {
            # Verifica connettività (Ping)
            if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
                throw "Computer non raggiungibile."
            }

            # Estrazione membri del gruppo Administrators
            $members = Invoke-Command -ComputerName $computer -ScriptBlock {
                Get-LocalGroupMember -Group "Administrators" | Select-Object Name, PrincipalSource, Class
            } -ErrorAction Stop

            foreach ($member in $members) {
                $results += [PSCustomObject]@{
                    ComputerName    = $computer
                    AccountName     = $member.Name
                    PrincipalSource = $member.PrincipalSource
                    Type            = $member.Class
                    AuditDate       = Get-Date -Format "yyyy-MM-dd HH:mm"
                }
            }
        }
        catch {
            Write-Warning "Errore su $computer : $($_.Exception.Message)"
            $results += [PSCustomObject]@{
                ComputerName    = $computer
                AccountName     = "ERRORE"
                PrincipalSource = "N/A"
                Type            = "LOG: $($_.Exception.Message)"
                AuditDate       = Get-Date -Format "yyyy-MM-dd HH:mm"
            }
        }
    }

    # Esportazione finale in CSV
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
    Write-Host "`nAudit completato! File salvato in: $OutputPath" -ForegroundColor Green
}

# ESEMPIO DI UTILIZZO:
# Get-LocalAdminAudit -ComputerNames "NomePC01", "NomeServer02"
