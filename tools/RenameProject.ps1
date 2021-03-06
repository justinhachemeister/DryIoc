<#
PowerShell script to rename C# Project including: 
- Copying project folder to folder with new project name
- Renaming .csproj file and other files with project name but different extension
- Changing project name reference in .sln solution file
- Changing RootNamespace and AssemblyName in .csproj file
- Renaming project inside AssemblyInfo.cs
#>
param(
    [parameter(
        HelpMessage="Existing C# Project path to rename.",
        Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateScript({
        if (Test-Path $_.Trim().Trim('"')) { $true }
        else { throw "Path does not exist: $_" }
    })]
    [string]$ProjectFilePath,
    
    [parameter(
        HelpMessage="New project file name, without extension.",
        Mandatory=$true)]
    [string]$NewProjectName,
 
    [parameter(
        HelpMessage="Path to solution file.",
        Mandatory=$true)]
    [ValidateScript({
        if (Test-Path $_.Trim().Trim('"')) { $true }
        else { throw "Path does not exist: $_" }
    })]
    [string]$SolutionFilePath,
    
    [parameter(
        HelpMessage="Relative path to AssemblyInfo.cs file, e.g. "".\Properties\AssemblyInfo.cs"".`nKeep it empty to skip AssemblyInfo processing.",
        Mandatory=$true)]
    [AllowEmptyString()]
    [string]$RelativeAssemblyInfoPath
)

$ProjectFilePath = $ProjectFilePath.Trim().Trim('"')
$SolutionFilePath = $SolutionFilePath.Trim().Trim('"')

function ProceedOrExit {
    if ($?) { echo "Proceed.." } else { echo "Script FAILED! Exiting.."; exit 1 } 
}

echo "Rename '$ProjectFilePath' to '$NewProjectName'"
echo "=========================================================="

$OldProjectFolder  = Split-Path $ProjectFilePath
echo "1. Set current location to project folder '$OldProjectFolder'"
cd $OldProjectFolder 
ProceedOrExit
        
$NewProjectFolder="..\$NewProjectName"
echo "----------"
echo "2. Copy project folder to '$NewProjectFolder'"
copy . $NewProjectFolder -Recurse #-WhatIf
ProceedOrExit

$NewProjectFolder=Resolve-Path $NewProjectFolder
echo "----------"
echo "3. Set current location to New project folder '$NewProjectFolder'"
cd $NewProjectFolder
ProceedOrExit

echo "----------"
echo "4. Rename .proj and other files inside '$NewProjectFolder'"

$OldProjectName=[IO.Path]::GetFileNameWithoutExtension($ProjectFilePath)
dir -Include "$OldProjectName.*" -Recurse | 
    ren -NewName {$_.Name -replace [regex]("^"+$OldProjectName+"\b"), $NewProjectName} #-WhatIf
ProceedOrExit
 
echo "----------"
echo "5. Copy solution file to '$SolutionFilePath.backup'" 
copy "$SolutionFilePath" "$SolutionFilePath.backup" #-WhatIf
ProceedOrExit
 
echo "----------"
echo "6. Rename project reference inside solution file."

# Put get-content in () brackets to read whole file before modifying it.
(Get-Content $SolutionFilePath) |
   % { if ($_ -match ("\b(" + $OldProjectName + ")\b\.csproj")) { $_ -replace $($matches[1]), $NewProjectName } else { $_ }} |
   Set-Content $SolutionFilePath
ProceedOrExit

$NewProjectFile="$NewProjectName.csproj"
echo "----------"
echo "7. Rename project in tags AssemblyName and RootNamespace inside '$NewProjectFile'"

(Get-Content $NewProjectFile) |
    % { if ($_ -match ("<(?:AssemblyName|RootNamespace)>(" + $OldProjectName +")</")) { $_ -replace $($matches[1]), $NewProjectName } else { $_ }} |
    Set-Content $NewProjectFile
ProceedOrExit

$RelativeAssemblyInfoPath = $RelativeAssemblyInfoPath.Trim().Trim('"')
if ($RelativeAssemblyInfoPath) {
    echo "----------"
    echo "8. Rename project inside '$RelativeAssemblyInfoPath'"
    
    if (!(Test-Path $RelativeAssemblyInfoPath)) { echo "ERROR: Path does not exist." }
    else {
        (Get-Content $RelativeAssemblyInfoPath) |
           % { if ($_ -match ("""\b("+$OldProjectName+")\b""")) { $_ -replace $($matches[1]), $NewProjectName } else { $_ }} |
           Set-Content $RelativeAssemblyInfoPath #-WhatIf
        ProceedOrExit  
    }
}
 
echo "=========="
echo "DONE."
echo "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")