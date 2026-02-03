<#PSScriptInfo

.VERSION 1.1.0.0

.GUID 3d43aa60-7d79-4ccf-8493-cabf4761f690

.AUTHOR Paul Naughton pauljnav

.COMPANYNAME Paul Naughton

.COPYRIGHT Paul Naughton

.TAGS AST FunctionName ParseFile

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Extracts toplevel function names from PowerShell scripts using the AST for static analysis and tooling.

.PRIVATEDATA

.DESCRIPTION
Parses a PowerShell script using the PowerShell Abstract Syntax Tree (AST)
    and returns the names of the functions
#>

function Get-FunctionName {
    <#

.DESCRIPTION
    Parses a PowerShell script using the PowerShell Abstract Syntax Tree (AST)
    and returns the names of all filter and function definitions that are not nested
    inside other functions.
    This is useful for static analysis, linting, documentation generation.
.SYNOPSIS
    Retrieves top-level function names from a PowerShell script file.
.PARAMETER Path
    Path to a PowerShell script file (.ps1, .psm1, etc.) to analyze.
    The path must exist. This parameter accepts pipeline input.
.EXAMPLE
    Get-FunctionName -Path .\MyScript.ps1
    Returns all top-level function names defined in MyScript.ps1.
.EXAMPLE
    Get-ChildItem *.psm1 | Get-FunctionName
    Parses multiple module files and outputs their top-level function names.
.OUTPUTS
    System.String
    The name of each top-level function found in the script.
.NOTES
    Author: Paul Naughton
    Date: Jan 2026
#>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [string]$Path,

        # optionally search nested functions
        [Parameter()]
        [switch]$IncludeNestedFunctions = $false
    )

    Begin {
        $token = $null
        $errors = $null
    }
    Process {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $resolvedPath, [ref]$token, [ref]$errors
        )

        if ($ast -isnot [System.Management.Automation.Language.ScriptBlockAst]) { break }

        # extract FunctionDefinitionAst
        $ast.FindAll( {
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                ($IncludeNestedFunctions -or $node.Parent -isnot [System.Management.Automation.Language.FunctionDefinitionAst])
            }, $IncludeNestedFunctions).Name
    }
}
