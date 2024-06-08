function Get-FunctionNamesFromScript
{
<#
.SYNOPSIS
    Extracts function and filter names from a PowerShell script.
.DESCRIPTION
    This function reads a PowerShell script from a specified path, tokenizes its content, and extracts all function
    and filter names defined in the script. Useful to collect function names for comparing against your Pester test suite.
.PARAMETER ScriptPath
    The path to the PowerShell script file from which to extract function and filter names.
.OUTPUTS
    PSCustomObject of the names of functions and filters defined in the script.
.EXAMPLE
    This command extracts and displays the names of functions and filters defined in the script
    Get-FunctionNamesFromScript -ScriptPath "C:\Path\To\YourScript.ps1"
.EXAMPLE
    This command supports pipelining
    $ScriptPath | Get-FunctionNamesFromScript
.NOTES
    Author: Paul Naughton
    Date: June 2024
    Version: 1.0
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$ScriptPath
    )

    process {
        # Read the content of the script
        $scriptContent = Get-Content -Path $ScriptPath -Raw

        # Tokenize the PowerShell script content
        $tokens = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$null)

        # Iterate through the tokens
        for ($i = 0; $i -lt $tokens.Count; $i++) {
            $token = $tokens[$i]

            # Check if the token represents the start of a function or filter definition
            if ($token.Type -eq "Keyword" -and ($token.Content -eq "function" -or $token.Content -eq "filter")) {
                # Find the corresponding function or filter name
                for ($j = $i + 1; $j -lt $tokens.Count; $j++) {
                    $nextToken = $tokens[$j]
                    if ($nextToken.Type -eq "CommandArgument") {
                        # PSCustomObject
                        Write-Output (
                            [PSCustomObject] @{
                                FunctionName = $nextToken.Content
                            }
                        )
                        break # Exit the inner loop once the function or filter name is found
                    }
                }
            }
        }#for (outer loop)
    }
}
