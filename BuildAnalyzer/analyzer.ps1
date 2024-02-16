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
[bool]$CoThrowError = Get-VstsInput -Name compilerWarningThrowError -AsBool
[bool]$ObsoleteThrowError = Get-VstsInput -Name obsoleteWarningThrowError -AsBool
# Access System.DefaultWorkingDirectory
$defaultWorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY

#$defaultWorkingDirectory = "C:\Git\D365-F-O-build-analyzer\BuildAnalyzer"
#$LogPath = "C:\Git\D365-F-O-build-analyzer\examples"
#$BpThrowError = $false

$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}

/* Style the button that is used to open and close the collapsible content */
.collapsible {
  background-color: #eee;
  color: #444;
  cursor: pointer;
  padding: 8px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  font-size: 15px;
}

/* Add a background color to the button if it is clicked on (add the .active class with JS), and when you move the mouse over it (hover) */
.active, .collapsible:hover {
  background-color: #ccc;
}

/* Style the collapsible content. Note: hidden by default */
.content {
  padding: 0 18px;
  display: none;
  overflow: hidden;
  background-color: #f1f1f1;
  overflow-x: auto;
} 

/*
.message {
    width: 200px;
}

.path {
    width: 200px;
}
*/
</style>
"@

$JS = @"
<script>

var coll = document.getElementsByClassName("collapsible");
var i;

for (i = 0; i < coll.length; i++) {
  coll[i].addEventListener("click", function() {
    this.classList.toggle("active");
    var content = this.nextElementSibling;
    if (content.style.display === "block") {
      content.style.display = "none";
    } else {
      content.style.display = "block";
    }
  });
}
</script>
"@

$BP_Collapsible = @"
<button type="button" class="collapsible">Best practice</button>
<div class="content">
"@

$CP_Collapsible = @"
<button type="button" class="collapsible">Compiler warnings</button>
<div class="content">
"@

$MP_Collapsible = @"
<button type="button" class="collapsible">Metadata warnings</button>
<div class="content">
"@

$TP_Collapsible = @"
<button type="button" class="collapsible">Tasks</button>
<div class="content">
"@

Clear-Host
$results = Get-ChildItem -Path $LogPath -Filter "*.xpp*.xml" -Recurse -ErrorAction SilentlyContinue -Force

$bp_collection=@()
$compiler_collection=@()
$metadata_collection=@()
$task_collection=@()

foreach ($result in $results)
{
    $model = $result.Name.Split(".")[2]

    try
    {
        $doc = New-Object xml
        $doc.Load((Convert-Path $result.FullName) )

        #$doc.Diagnostics.Items.Diagnostic

        $bestPractices = $doc.Diagnostics.Items.Diagnostic | Where-Object { $_.DiagnosticType -eq "BestPractices"  -and $_.Severity -ne "Informational"}

        foreach ($bestPractice in $bestPractices)
        {
            if($BpThrowError -eq $true)
            {
                 Write-Host "##vso[task.logissue type=error] [$model] BestPratice Warning: $($bestPractice.Moniker) - $($bestPractice.Message) - Path: $($bestPractice.Path)" -ForegroundColor Red
            }
            else 
            {
                Write-Host "[$model]" -ForegroundColor Green -NoNewline ; Write-Host " BestPratice Warning: $($bestPractice.Moniker) - $($bestPractice.Message) - Path: $($bestPractice.Path)" -ForegroundColor Yellow
            }
            
            $Row = "" | Select-Object Model,Moniker,Message,Path, Severity
            $Row.Model = $model
            $Row.Moniker = $bestPractice.Moniker
            $Row.Message = $bestPractice.Message
            $Row.Path = $bestPractice.Path
            $Row.Severity = $bestPractice.Severity
            $bp_collection += $Row
        }

        $compileWarnings = $doc.Diagnostics.Items.Diagnostic | Where-Object { ($_.DiagnosticType -eq "Compile" -or $_.DiagnosticType -eq "Compile Fatal" -or $_.DiagnosticType -eq "Unspecified" -or $_.DiagnosticType -eq "Generation") -and $_.Severity -ne "Informational"}

        foreach ($compilerWarning in $compileWarnings)
        {
            if($CoThrowError -eq $true)
            {
                Write-Host "##vso[task.logissue type=error] [$model] Compiler Warning: $($compilerWarning.Message) - Path: $($compilerWarning.Path)" -ForegroundColor Red
            }
            else 
            {
                Write-Host "[$model]" -ForegroundColor Green -NoNewline ; Write-Host " Compiler Warning: $($compilerWarning.Message) - Path: $($compilerWarning.Path)" -ForegroundColor Yellow
            }

            $Row = "" | Select-Object Model,Message,Path,Moniker,Severity
            $Row.Model = $model
            $Row.Severity = $compilerWarning.Severity
            $Row.Message = $compilerWarning.Message
            $Row.Path = $compilerWarning.Path
            $Row.Moniker = $compilerWarning.Moniker
            $compiler_collection += $Row
        }

        $metadataWarnings = $doc.Diagnostics.Items.Diagnostic | Where-Object { ($_.DiagnosticType -eq "Metadata" -or $_.DiagnosticType -eq "MetadataProvider") -and $_.Severity -ne "Informational"}
        foreach($metadataWarning in $metadataWarnings)
        {
            if($ObsoleteThrowError -eq $true)
            {
                if($metadataWarning.Moniker -eq "ReferencedObjectIsObsolete")
                {
                    Write-Host "##vso[task.logissue type=error] [$model] Metadata Warning: $($metadataWarning.Message) - Path: $($metadataWarning.Path)" -ForegroundColor Red
                }
                else 
                {
                    Write-Host "[$model] Metadata Warning: $($metadataWarning.Message) - Path: $($metadataWarning.Path)" -ForegroundColor Yellow
                }
            }
            else 
            {
                Write-Host "[$model]" -ForegroundColor Green -NoNewline ; Write-Host " Metadata Warning: $($metadataWarning.Message) - Path: $($metadataWarning.Path)" -ForegroundColor Yellow
            }

            $Row = "" | Select-Object Model,Message,Path,Moniker,Severity
            $Row.Model = $model
            $Row.Severity = $metadataWarning.Severity
            $Row.Message = $metadataWarning.Message
            $Row.Path = $metadataWarning.Path
            $Row.Moniker = $metadataWarning.Moniker
            $metadata_collection += $Row
        }

        $tasks = $doc.Diagnostics.Items.Diagnostic | Where-Object { $_.DiagnosticType -eq "TaskListItem" }
        foreach($task in $tasks)
        {
            Write-Host "[$model]" -ForegroundColor Green -NoNewline ; Write-Host " Task: $($task.Message) - Path: $($task.Path)" -ForegroundColor Yellow

            $Row = "" | Select-Object Model,Message,Path,Moniker
            $Row.Model = $model
            $Row.Message = $task.Message
            $Row.Path = $task.Path
            $Row.Moniker = $task.Moniker
            $task_collection += $Row
        }

    }
    catch
    {
        Write-Host "##vso[task.logissue type=error] Error during processing" -ForegroundColor Red
    }
}

#$bp_count_path = $bp_collection | Group-Object -Property Model, Path, Moniker
#$bp_count_moniker = $bp_collection | Group-Object -Property Model, Moniker
$bp_count_model = $bp_collection | Group-Object -Property Model

$task_count_model = $task_collection | Group-Object -Property Model

$compilerWarnings_count_model = $compiler_collection | Group-Object -Property Model

$metadataWarnings_count_model = $metadata_collection | Group-Object -Property Model



# Overview

$overviewBP = $bp_count_model | ConvertTo-Html -Property Name, Count -Fragment
$overviewCP = $compilerWarnings_count_model | ConvertTo-Html -Property Name, Count -Fragment
$overviewMP = $metadataWarnings_count_model | ConvertTo-Html -Property Name, Count -Fragment
$overviewTP = $task_count_model | ConvertTo-Html -Property Name, Count -Fragment
$overviewBP = "<h1>Overview</h1><h2>Best practice</h2>" + $overviewBP + "<br/><h2>Compiler Warnings</h2>" + $overviewCP + "<h2>Metadata Warnings</h2>" + $overviewMP + "<h2>Tasks</h2>" + $overviewTP + "<br/>"

# Details
#$bpPerMoniker = $bp_count_moniker | ConvertTo-Html -Property Name, Count -Fragment
#$bpPerPath = $bp_count_path | ConvertTo-Html -Property Name, Count -Fragment
#$bpPerMoniker = $BP_Collapsible + $bpPerMoniker + "<br/>" + $bpPerPath + "</div>"
$bpTable = $bp_collection | ConvertTo-Html -Property Model, Severity, Moniker, Message, Path -Fragment
$bpTable = $BP_Collapsible + $bpTable + "</div>"
$bpTable = $bpTable -replace '<th>Message</th>', '<th class="message">Message</th>'
$bpTable = $bpTable -replace '<th>Path</th>', '<th class="path">Path</th>'

$cpTable = $compiler_collection | ConvertTo-Html -Property Model, Severity, Moniker, Message, Path -Fragment
$cpTable = $CP_Collapsible + $cpTable + "</div>"
$cpTable = $cpTable -replace '<th>Message</th>', '<th class="message">Message</th>'
$cpTable = $cpTable -replace '<th>Path</th>', '<th class="path">Path</th>'

$mpTable = $metadata_collection | ConvertTo-Html -Property Model, Severity, Moniker, Message, Path -Fragment
$mpTable = $MP_Collapsible + $mpTable + "</div>"
$mpTable = $mpTable -replace '<th>Message</th>', '<th class="message">Message</th>'
$mpTable = $mpTable -replace '<th>Path</th>', '<th class="path">Path</th>'

$tpTable = $task_collection | ConvertTo-Html -Property Model, Message, Path -Fragment
$tpTable = $TP_Collapsible + $tpTable + "</div>"
$tpTable = $tpTable -replace '<th>Message</th>', '<th class="message">Message</th>'
$tpTable = $tpTable -replace '<th>Path</th>', '<th class="path">Path</th>'

# Convert the array to HTML
$overview = ConvertTo-Html -Head $Header -Body "$overviewBP $bpTable $cpTable $mpTable $tpTable" -PostContent $JS

[System.IO.File]::WriteAllLines("$defaultWorkingDirectory/D365_BuildAnalyzer.html", $overview, [System.Text.Encoding]::UTF8)

#Out-File -FilePath $defaultWorkingDirectory/BPCheck.html

Write-Host "##vso[task.addattachment type=buildanalyzerresult;name=overview;]$defaultWorkingDirectory/D365_BuildAnalyzer.html"


# Setting failed status if there are any best practice warnings
if($BpThrowError -eq $true)
{
    if($bp_collection.Count -gt 0)
    {
        Write-Host "##vso[task.complete result=Failed;]There are best practice warnings"
    }
}

if($CoThrowError -eq $true)
{
    if($compiler_collection.Count -gt 0)
    {
        Write-Host "##vso[task.complete result=Failed;]There are compiler warnings"
    }
}

if($ObsoleteThrowError -eq $true)
{
    if($metadata_collection.Count -gt 0)
    {
        Write-Host "##vso[task.complete result=Failed;]There are metadata warnings"
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
