<#
.SYNOPSIS
    Retrieves top-level function names from a PowerShell script file.

.DESCRIPTION
    Parses a PowerShell script using the PowerShell Abstract Syntax Tree (AST)
    and returns the names of all function definitions that are not nested
    inside other functions.

    This is useful for static analysis, linting, documentation generation.

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
    Version: 1.1

#>
function Get-FunctionName {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 1
        )]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path
    )

    begin {
        $predicate = {
            param($node)

            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Parent -isnot [System.Management.Automation.Language.FunctionDefinitionAst]
        }

        $token = $null
        $errors = $null
        $searchNestedScriptBlocks = $true
    }

    process {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $Path,
            [ref]$token,
            [ref]$errors
        )

        # Output the function names
        $ast.FindAll($predicate, $searchNestedScriptBlocks) | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
            }
        }
    }
}
