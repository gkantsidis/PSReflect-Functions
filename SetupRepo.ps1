#Requires -Version 3

[CmdletBinding()]
param(
)

if ((git remote) -notcontains "official") {
    Write-Verbose -Message "Creating remote for official depot"
    git remote add --tags official https://github.com/jaredcatkinson/PSReflect-Functions.git
    git fetch official
}
