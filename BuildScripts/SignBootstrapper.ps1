[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$TargetFileDir,
    [parameter(Mandatory=$true)]
    [string]$TargetFilename
)

function IsSignToolAvailable(){  
    if (Get-Command "signtool.exe" -errorAction SilentlyContinue)
    {
        return $true;
    }

    Write-Warning "The Windows SDK is not installed; the sign tool cannot be found; no files will be signed."
    return $false;
}

function IsCertificateAvailable(){
    Set-Location Cert:\LocalMachine\My

    $certificateCount = (Get-ChildItem | Where-Object {$_.FriendlyName -eq "LevelUp"} | Select-Object).Count

    if($certificateCount -ne 1){
        Write-Warning "The LevelUp certificate cannot be found; no files will be signed."
        return $false;
    }
    
    return $true;
}

if($(IsSignToolAvailable) -and $(IsCertificateAvailable)){
    $bootstrapperPath = Join-Path -Path $TargetFileDir -ChildPath $TargetFilename
    $enginePath = Join-Path -Path $TargetFileDir -ChildPath "engine.exe"    

    # Detach engine from Installer
    Write-Host "Detaching engine from installer"
    & "insignia.exe" -ib "$bootstrapperPath" -o "$enginePath"

    # Sign engine.exe
    Write-Host "Signing engine.exe"
    & "signtool.exe" sign /sm /a /d "LevelUp" /t "http://timestamp.digicert.com" "$enginePath"

    # Re-attach engine to the bundle
    Write-Host "Re-attaching engine to bundle"
    & "insignia.exe" -ab "$enginePath" "$bootstrapperPath" -o "$bootstrapperPath"

    # Sign the bundle
    Write-Host "Signing bundle"
    & "signtool.exe" sign /sm /a /d "LevelUp" /t "http://timestamp.digicert.com" "$bootstrapperPath"
}