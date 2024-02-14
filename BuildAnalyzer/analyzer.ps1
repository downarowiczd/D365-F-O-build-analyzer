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

[string]$LogPath = Get-VstsInput -Name logPath

#$LogPath = "C:\Git\D365 Build Analyzer Extension Test"

Clear-Host

# Inputs
$bp_throw_error = $false
#$obsolete_throw_error = $false
#$compiler_warning_throw_error = $false


$results = Get-ChildItem -Path $LogPath -Filter "*.xpp*.xml" -Recurse -ErrorAction SilentlyContinue -Force
#$objects = @()


$bp_arr=@{}
$bp_arr["BP_ALL_MODELS"] = @{}

foreach ($result in $results)
{
    $model = $result.Name.Split(".")[2]

    if($null -eq $bp_arr[$model])
    {
        $bp_arr[$model] = @{}
    }

    try
    {
        $doc = New-Object xml
        $doc.Load((Convert-Path $result.FullName) )

        #$doc.Diagnostics.Items.Diagnostic

        $bestPractices = $doc.Diagnostics.Items.Diagnostic | Where-Object { $_.DiagnosticType -eq "BestPractices" }

        foreach ($bestPractice in $bestPractices)
        {
            if($bp_throw_error -eq $true)
            {
                Write-Host "##vso[task.logissue type=error] [$model] BestPratice Warning: $($bestPractice.Moniker) - $($bestPractice.Message)" -ForegroundColor Red
            }
            else 
            {
                Write-Host "[$model]" -ForegroundColor Green -NoNewline ; Write-Host " BestPratice Warning: $($bestPractice.Moniker) - $($bestPractice.Message)" -ForegroundColor Yellow
            }
            
            if($null -eq $bp_arr[$model][$bestPractice.Moniker])
            {
                $bp_arr[$model][$bestPractice.Moniker] = 1
            }
            else 
            {
                $bp_arr[$model][$bestPractice.Moniker]++
            }

            if($null -eq $bp_arr["BP_ALL_MODELS"][$bestPractice.Moniker])
            {
                $bp_arr["BP_ALL_MODELS"][$bestPractice.Moniker] = 1
            }
            else 
            {
                $bp_arr["BP_ALL_MODELS"][$bestPractice.Moniker]++
            }
        }
    }
    catch
    {
        Write-Host "##vso[task.logissue type=error] Error during processing" -ForegroundColor Red
    }
}


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
