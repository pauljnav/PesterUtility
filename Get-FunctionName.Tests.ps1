# PesterUtility \ Get-FunctionName

Describe "Get-FunctionName Tests" {

    BeforeAll {

        # dot load the script under test
        $scriptPath = $PSCommandPath.Replace('.Tests.ps1', '.ps1')
        . $scriptPath

        # GetFileNameWithoutExtension to derive command name
        $commandName = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
        $command = Get-Command -Name $commandName -ErrorAction Stop

        # Create a temporary PowerShell script file with functions to test
        $tempPath = "TestDrive:\TestScript.ps1"
        Set-Content $tempPath -Value @'
            function Test-One { }
            function Test-Two ($param1) {
                function Test-Three ($param1) { }
            }
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
    Context "<command> Functionality" {

        It "Should gracefully handle a script without any functions" {
            # Arrange: Create an empty script file in TestDrive
            $emptyScriptPath = "TestDrive:\EmptyScript.ps1"
            New-Item -Path $emptyScriptPath -ItemType File -Force | Out-Null

            # Act
            $result = Get-FunctionName -Path $emptyScriptPath

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It "Should return function names from a valid PowerShell script" {
            # Act
            $result = Get-FunctionName -Path $tempPath

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain "Test-One"
            $result | Should -Contain "Test-Two"
            $result | Should -Not -Contain "Test-Three"
            $result.Count | Should -BeExactly 2
        }

        It "Should accept input from the pipeline" {
            # Act
            $result = Get-Item $tempPath | Get-FunctionName

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain "Test-One"
            $result | Should -Contain "Test-Two"
            $result | Should -Not -Contain "Test-Three"
        }

        It "Should accept IncludeNestedFunctions parameter" {
            # Act
            $result = Get-FunctionName -Path $tempPath -IncludeNestedFunctions

            # Assert
            $result | Should -Contain "Test-One"
            $result | Should -Contain "Test-Two"
            $result | Should -Contain "Test-Three"
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
}