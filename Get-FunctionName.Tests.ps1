# PesterUtility \ Get-FunctionName

Describe "Get-FunctionName Tests" {

    BeforeAll {

        # dot load the script under test
        $scriptPath = $PSCommandPath.Replace(".Tests.ps1", ".ps1")
        . $scriptPath

        $commandName = 'Get-FunctionName'
        $command = Get-Command -Name $commandName -Module $module -ErrorAction Stop

        # Create a temporary PowerShell script file with functions to test
        $tempScriptPath = "TestDrive:\TestScript.ps1"
        Set-Content $tempScriptPath -Value @'
            function Test-One { }
            function Test-Two { param($param1) }
'@

    }

    # using a var <template> command & commandName
    Context "<command> ScriptAnalyzer" {

        It "Fn <command> Should pass ScriptAnalyzer rules" {
            $ScriptAnalyzerResult = Invoke-ScriptAnalyzer $scriptPath

            $ScriptAnalyzerResult.RuleName | Should -Not -Contain 'PSAvoidTrailingWhitespace'
            $ScriptAnalyzerResult.Severity | Should -Not -Contain 'Warning'
            $ScriptAnalyzerResult | Should -BeNullOrEmpty
        }
    }

    # using a var <template> command & commandName
    Context "<command> Help" {

        BeforeAll {
            $help = Get-Help -Name $command
        }

        It "<commandName> help" {
            $help | Should -Not -BeNullOrEmpty
        }
        It "<commandName> has a synopsis" {
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        It "<commandName> has a description" {
            -join $help.description.Text | Should -Not -BeNullOrEmpty
        }
        It "<commandName> has at least 2 examples" {
            $help.examples.example.Count | Should -BeGreaterOrEqual 2
        }
        It "<commandName> has example providing code and comment" {
            ($help.examples.example)[0].Code | Should -Not -BeNullOrEmpty
            ($help.examples.example)[0].remarks.Text | Should -Not -BeNullOrEmpty
        }

    }

    It "Should handle a script with no functions gracefully" {
        # Arrange: Create an empty script file in TestDrive
        $emptyScriptPath = "TestDrive:\EmptyScript.ps1"
        New-Item -Path $emptyScriptPath -ItemType File -Force | Out-Null

        # Act
        $result = $emptyScriptPath | Get-FunctionName

        # Assert
        $result | Should -BeNullOrEmpty
    }

    It "Should return function names from a valid PowerShell script" {
        # Act
        $result = Get-Item $tempScriptPath | Get-FunctionName

        # Assert
        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Contain "Test-One"
        $result.Name | Should -Contain "Test-Two"
        $result.Count | Should -BeExactly 2
    }

    It "Should accept input from the pipeline" {
        # Act
        $result = Get-Item $tempScriptPath | Get-FunctionName

        # Assert
        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Contain "Test-One"
        $result.Name | Should -Contain "Test-Two"
    }

    It "Should return an empty array if script has only comments and variables" {
        # Arrange: Create a script with no functions in TestDrive
        $commentOnlyScriptPath = "TestDrive:\CommentOnlyScript.ps1"
        @"
# This script has no functions
$globalVariable = 123
"@ | Set-Content -Path $commentOnlyScriptPath

        # Act
        $result = Get-FunctionName -Path $commentOnlyScriptPath

        # Assert
        $result | Should -BeNullOrEmpty
    }

}