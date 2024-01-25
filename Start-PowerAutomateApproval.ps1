Function Start-PowerAutomateApproval {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string]$AssignedTo,

        [Parameter(Mandatory=$true)]
        [string]$Details,

        [Parameter(Mandatory=$true)]
        [string]$Waitseconds
    )

    $logicAppUrl = "https://customAPIurl.com"

    $body = @{
        Title = "$Title"
        AssignedTo = $AssignedTo
        Details = $Details
    } | ConvertTo-Json

    $header = @{
        "Content-Type" = "application/json"
    }

    $output1 = Invoke-WebRequest -Method POST -Uri $logicAppUrl -Headers $header -ContentType 'application/json' -Body $body -UseBasicParsing

    [string]$newUrl = $output1.Headers.Location

    do {
        $output2 = Invoke-WebRequest -Method GET -Uri $newUrl -Headers $header -ContentType 'application/json' -UseBasicParsing
        write-host "Waiting for Approval to be processed" -ForegroundColor Green
        Start-Sleep -Seconds $waitseconds
    } while ($output2.StatusCode -eq 202)

    if ($output2.StatusCode -ne 200) {
        Write-Warning "Something went wrong:"
        Write-Warning $output2.Content
    } else {
        try {
            # Parse $output2.content into individual properties
            $lines = $output2.Content -split "`n" | ForEach-Object { $_.Trim() }
            $results = New-Object PSObject
            foreach ($line in $lines) {
                $parts = $line -split ':',2
                $name = $parts[0].Trim()
                $value = $parts[1].Trim()
                $results | Add-Member -MemberType NoteProperty -Name $name -Value $value
            }
        } catch {
            Write-Warning "Error parsing response: $_"
        }

        # Return the parsed results
        return $results
    }
}
