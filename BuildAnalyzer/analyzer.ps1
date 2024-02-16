<#
    .SYNOPSIS
    Analyzes the compiler and bestpractices logs from D365 F&O builds.
    .DESCRIPTION
    Analyzes the compiler and best practice output logs for warnings, informations and ToDos to provide a build summary about them. And if needed the build can be failed.
    .PARAMETER logPath
    Path to the log files
    .NOTES
    Written by Dominik Downarowicz
    https://downardo.at
    #>

[CmdletBinding()]
param()


Write-Host "Starting Build Analyzer" -ForegroundColor Green

[string]$LogPath = Get-VstsInput -Name logPath
[bool]$BpThrowError = Get-VstsInput -Name bpCheckThrowError -AsBool
# Access System.DefaultWorkingDirectory
$defaultWorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY

#$defaultWorkingDirectory = "C:\Git\D365-F-O-build-analyzer\BuildAnalyzer"
#$LogPath = "C:\Git\D365-F-O-build-analyzer\examples"
#$BpThrowError = false

$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

Clear-Host
$results = Get-ChildItem -Path $LogPath -Filter "*.xpp*.xml" -Recurse -ErrorAction SilentlyContinue -Force

$bp_collection=@()

foreach ($result in $results)
{
    $model = $result.Name.Split(".")[2]

    try
    {
        $doc = New-Object xml
        $doc.Load((Convert-Path $result.FullName) )

        #$doc.Diagnostics.Items.Diagnostic

        $bestPractices = $doc.Diagnostics.Items.Diagnostic | Where-Object { $_.DiagnosticType -eq "BestPractices" }

        foreach ($bestPractice in $bestPractices)
        {
            if($BpThrowError -eq $true)
            {
                 Write-Host "##vso[task.logissue type=error] [$model] BestPratice Warning: $($bestPractice.Moniker) - $($bestPractice.Message)" -ForegroundColor Red
            }
            else 
            {
                Write-Host "[$model]" -ForegroundColor Green -NoNewline ; Write-Host " BestPratice Warning: $($bestPractice.Moniker) - $($bestPractice.Message)" -ForegroundColor Yellow
            }
            
            $Row = "" | Select-Object Model,Moniker,Message
            $Row.Model = $model
            $Row.Moniker = $bestPractice.Moniker
            $Row.Message = $bestPractice.Message
            $bp_collection += $Row
        }
    }
    catch
    {
        Write-Host "##vso[task.logissue type=error] Error during processing" -ForegroundColor Red
    }
}

#$bp_count_moniker = $bp_collection | Group-Object -Property Model, Moniker
$bp_count_model = $bp_collection | Group-Object -Property Model



# Convert the array to HTML
$html = $bp_count_model | ConvertTo-Html -Title "Best Practice checks" -Head $Header -Body "<h1>Best practice checks</h1>" -Property Name, Count

[System.IO.File]::WriteAllLines("$defaultWorkingDirectory/BPCheck.html", $html, [System.Text.Encoding]::UTF8)

#Out-File -FilePath $defaultWorkingDirectory/BPCheck.html


Write-Host "##vso[task.addattachment type=buildanalyzerresult;name=bpcheck;]$defaultWorkingDirectory/BPCheck.html"


# For more information on the Azure DevOps Task SDK:
# https://github.com/Microsoft/vsts-task-lib
#Trace-VstsEnteringInvocation $MyInvocation
#try {
    # Set the working directory.
#    $cwd = Get-VstsInput -Name cwd -Require
#    Assert-VstsPath -LiteralPath $cwd -PathType Container
#    Write-Verbose "Setting working directory to '$cwd'."
#    Set-Location $cwd

    # Output the message to the log.
#    Write-Host (Get-VstsInput -Name msg)
#} finally {
#    Trace-VstsLeavingInvocation $MyInvocation
#}
