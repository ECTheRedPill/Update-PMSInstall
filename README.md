# Update-PMSInstall
PowerShell module to update Windows Plex Media Server that uses Plex Service

Start by enabling PowerShell remoting:
https://www.google.com/search?q=configure+powershell+remoting+workgroup

Install module on local system:  
Create directory in "%Program Files%\WindowsPowerShell\Modules" called Update-PMSInstall.  
Copy the module Update-PMSInstall.psm1 into the %ProgramFiles%\WindowsPowerShell\Modules\Update-PMSInstall directory.  

Import module:  
launch PowerShell and run the following command:  
Import-Module Update-PMSInstall  

Run module:  
For local execution type either: 
Update-PMSInstall or Update-PMSInstall -UserName [<UserName>]  
For remote execution type either:  
Invoke-Command -ComputerName PlexServer -Credential Administrator -ScriptBlock ${function:Update-PMSInstall}  
or  
Invoke-Command -ComputerName PlexServer -Credential [<Administrator>] -ScriptBlock ${function:Update-PMSInstall -UserName [<UserName>]}
