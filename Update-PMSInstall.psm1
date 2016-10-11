<#
.Synopsis
   Updates systems that use both Plex Media Server and Plex Server Service.
.DESCRIPTION
   Use this script to update systems that have Plex Media Server and use the Plex Server service.
.EXAMPLE
   Update-PMSInstall
.EXAMPLE
   Update-PMSInstall -UserName JDoe
.EXAMPLE
   Invoke-Command -ComputerName Server1 -Credential Administrator -ScriptBlock ${function:Update-PMSInstall}
.EXAMPLE
   Invoke-Command -ComputerName Server1 -Credential Administrator -ScriptBlock ${function:Update-PMSInstall -UserName JDoe} 
#>
Function Update-PMSInstall {
    [CmdletBinding()]
    Param (
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=0)]
    # Change this to the user name you run Plex Media Server under, or use the parameter and enter a value.
    # If you want to use the current user name add a # before the equal, for example $UserName #= "Administrator"
    $UserName = "Admin"
    )
    Try{
        If ($UserName -eq $Null) {
            Write-Host 'Getting current user name...' -ForegroundColor Cyan
            $UserName = $env:USERNAME
            $UserName
        }
        Else {
            Write-Host 'Current user name...' -ForegroundColor Cyan
            $UserName
        }
        Write-Host "Getting $UserName SID..." -ForegroundColor Cyan
        $UserSID = (Get-WmiObject win32_useraccount -Filter "name = '$UserName'").SID
        $UserSID
        Write-Host "Creating new drive for $UserName registry hive..." -ForegroundColor Cyan
        New-PSDrive HKU -PSProvider Registry -Root Registry::HKEY_USERS -Verbose -ErrorAction SilentlyContinue
        Write-Host "Checking $UserName registry hive for data path..." -ForegroundColor Cyan
        If ($(Get-ItemProperty "HKU:\$UserSID\Software\Plex, Inc.\Plex Media Server" -Name "LocalAppDataPath" -ErrorAction SilentlyContinue)) {
            $LocalAppDataPath = $(Get-ItemProperty "HKU:\$UserSID\Software\Plex, Inc.\Plex Media Server" -Name "LocalAppDataPath").LocalAppDataPath
            $LocalAppDataPath
        }
        Else {
            $LocalAppDataPath = "$Env:HOMEDRIVE\Users\$UserName\AppData\Local"
            $LocalAppDataPath
        }
        Write-Host 'Getting most recent PMS install...' -ForegroundColor Cyan
        If (Get-ChildItem "$LocalAppDataPath\Plex Media Server\Updates" -Filter '*.exe' -Recurse -ErrorAction SilentlyContinue) {
            Get-ChildItem "$LocalAppDataPath\Plex Media Server\Updates" -Filter '*.exe' -Recurse -ErrorAction SilentlyContinue | Sort creationtime | Select -expand fullname -last 1 -OutVariable PMSInstaller
        }
        Else {
            Write-Warning "There are no PMS install files in $LocalAppDataPath\Plex Media Server\Update directory!"
            Break
        }
        Write-Host 'Checking for Plex Service...' -ForegroundColor Cyan
        If (Get-Service PlexService -ErrorAction SilentlyContinue) {
            Write-Host 'Stopping Plex Service...' -ForegroundColor Cyan
            While ($(Get-Service PlexService).Status -eq "Running") {
                Stop-Service PlexService -Force -Verbose
            }
        }
        Else {
            Write-Warning "There is no such Service named PlexService on $Env:COMPUTERNAME!"
            Break
        }
        Write-Host 'Stopping Plex Media Server Processes...' -ForegroundColor Cyan
        'Plex Media Server','Plex Media Scanner','PlexDlnaServer','PlexNewTranscoder','PlexScriptHost','PlexTranscoder' | Stop-Process -Force -Verbose -ErrorAction SilentlyContinue
        While (Start-Process -FilePath "$PMSInstaller" -ArgumentList "/install /passive /norestart" -Wait) {
                Write-Host 'Updating Plex Media Server...'
        }
        Write-Host 'Checking registry for default PMS settings...' -ForegroundColor Cyan
        If ($(Get-ItemProperty "HKU:\$UserSID\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Plex Media Server" -ErrorAction SilentlyContinue)) {
            Remove-ItemProperty "HKU:\$UserSID\Software\Microsoft\Windows\CurrentVersion\Run\" -Name "Plex Media Server" -Force -Verbose
        }
        Write-Host 'Starting Plex Service...' -ForegroundColor Cyan
        While ($(Get-Service PlexService).Status -ne "Running") {
            Start-Service PlexService -Verbose
        }
    }
    Catch{
        Write-Warning "Error occurred: $_"
    }
}
