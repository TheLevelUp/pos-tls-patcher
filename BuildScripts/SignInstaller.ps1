[cmdletbinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$TargetFilepath
)

function IsSignToolAvailable(){
    $isWindowsSdkInstalled = $false;
    
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
    Write-Host "Signing  $TargetFilepath"

    & "signtool.exe" sign /sm /a /d "LevelUp" /t "http://timestamp.digicert.com" "$TargetFilepath"
}