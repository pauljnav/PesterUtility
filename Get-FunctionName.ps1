function Get-FunctionName
{
<#
.SYNOPSIS
    Extracts function and filter names from a PowerShell script.
.DESCRIPTION
    This function reads a PowerShell script from a specified path, and using AST method it extracts all function
    and filter names defined in the script. Useful to collect function names for comparing against your Pester test suite.
.PARAMETER fileName
    The path to the PowerShell script file from which to extract function and filter names.
.EXAMPLE
    This command extracts and displays the names of functions and filters defined in the script
    Get-FunctionName -ScriptPath "C:\Path\To\Script.ps1"
.EXAMPLE
    This command supports pipelining
    $file = Get-Item -Path "C:\Path\To\Script.ps1"
    $file | Get-FunctionName
.NOTES
    Author: Paul Naughton
    Date: Jan 2025
    Version: 1.0
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$fileName
    )

    Process {
        $token = $null
        $errors = $null
        $ScriptBlockAst = [System.Management.Automation.Language.Parser]::ParseFile($fileName, [ref]$token, [ref]$errors)

        # extract FunctionDefinitionAst
        $functionNames = $ScriptBlockAst.EndBlock.Statements |
        Where-Object {$_ -is [System.Management.Automation.Language.FunctionDefinitionAst]} |
            Select-Object Name

        # PSCustomObject
        Write-Output $functionNames
    }
}