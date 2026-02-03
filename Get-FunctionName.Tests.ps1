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
            function Test-Two ([int]$param1) {
                filter Test-Three ([bool]$param1, [string]$param2) { }
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
            $result.Name | Should -Contain "Test-One"
            $result.Name | Should -Contain "Test-Two"
            $result.Name | Should -Not -Contain "Test-Three"
            $result.Count | Should -BeExactly 2
        }

        It "Should accept input from the pipeline" {
            # Act
            $result = Get-Item $tempPath | Get-FunctionName

            # Assert
            $result.Name | Should -Not -BeNullOrEmpty
            $result.Name | Should -Contain "Test-One"
            $result.Name | Should -Contain "Test-Two"
            $result.Count | Should -BeExactly 2
        }

        It "Should accept IncludeNestedFunctions parameter" {
            # Act
            $result = Get-FunctionName -Path $tempPath -IncludeNestedFunctions

            # Assert
            $result.Name | Should -Contain "Test-One"
            $result.Name | Should -Contain "Test-Two"
            $result.Name | Should -Contain "Test-Three"
            $result.Count | Should -BeExactly 3
        }

        It "Result from first (parent) function should have expected properties" {
            # Act
            $result = Get-FunctionName -Path $tempPath | Select-Object -First 1

            # Assert
            $result.Name | Should -BeExactly 'Test-One'
            $result.IsFilter | Should -BeFalse
            $result.Parameters | Should -BeNullOrEmpty
            $result.LineNumber | Should -BeExactly 1
            $result.FilePath | Should -Match 'TestScript.ps1$'
            $result.FileName | Should -BeExactly 'TestScript.ps1'
            $result.Text | Should -Match '^function Test-One'
        }

        It "Result from second (parent) function should have expected properties" {
            # Act
            $result = Get-FunctionName -Path $tempPath | Select-Object -First 1 -Skip 1

            # Assert
            $result.Name | Should -BeExactly 'Test-Two'
            $result.IsFilter | Should -BeFalse
            $result.Parameters | Should -Not -BeNullOrEmpty
            $result.Parameters[0].Name | Should -BeExactly '$param1'
            $result.LineNumber | Should -BeExactly 2
            $result.FilePath | Should -Match 'TestScript.ps1$'
            $result.FileName | Should -BeExactly 'TestScript.ps1'
            $result.Text | Should -Match '^function Test-Two'
        }

        It "Result from third (nested) function should have expected properties" {
            # Act
            $result = Get-FunctionName -Path $tempPath -IncludeNestedFunctions | Select-Object -First 1 -Skip 2

            # Assert
            $result.Name | Should -BeExactly 'Test-Three'
            $result.IsFilter | Should -BeTrue
            $result.Parameters | Should -Not -BeNullOrEmpty
            $result.Parameters[0].Name | Should -BeExactly '$param1'
            $result.Parameters[1].Name | Should -BeExactly '$param2'
            $result.LineNumber | Should -BeExactly 3
            $result.FilePath | Should -Match 'TestScript.ps1$'
            $result.FileName | Should -BeExactly 'TestScript.ps1'
            $result.Text | Should -Match '^filter Test-Three'
        }
        It "Should return empty if script has only comments and variables" {
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