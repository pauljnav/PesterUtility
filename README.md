[![Follow on Twitter](https://img.shields.io/twitter/follow/tecknikp.svg?style=social&label=Follow%20%40tecknikp)](https://twitter.com/tecknikp)
# PesterUtility
Utility functions that assist when Pester testing

### Get-FunctionName.ps1
An improved function over the original Get-FunctionNamesFromScript.ps1

`Get-FunctionName` can optionally search nested/child functions using the IncludeNestedFunctions `switch parameter`.

Modify the $ast.FindAll() method in Get-FunctionName, simplify by removing the `-and $_.Parent -isnot [FunctionDefinitionAst]` method.

Updated Get-FunctionName to output a list of parameters with calculated parameters.
s