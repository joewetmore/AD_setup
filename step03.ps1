 #STEP 03 - 

#Set the Log File Location
$LogFile = "C:\AD_setup\logs\AD_setup.log"
 
#Function to Create a Log File
Function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string] $message,
        [Parameter(Mandatory = $false)] [ValidateSet("INFO","WARNING","ERROR")] [string] $level = "INFO"
    )
    $Timestamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "$timestamp [$level] - $message"
}
 
#Call the Function to Log a Message
#Write-Log -level ERROR -message "String failed to be a string"


Clear-Host

# create AD sites
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating AD Sites & Subnets---------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
import-csv c:\AD_setup\newsites.csv | New-ADReplicationSite 
Write-Log "created AD sites"

# import subnet list
import-csv c:\AD_setup\newsubnets.csv | New-ADReplicationSubnet 
Write-Log "created AD subnets"

# get the domain from step02
$domain = Get-Content C:\AD_setup\Domain.txt

# create OU structure
# Note: you must edit the "newOUs.csv" file first to change DC=CHANGEME,DC=local to the correct domain name. This will be fixed in a later version of this script. 
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating the Organizational Units---------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
import-csv C:\AD_setup\newOUs.csv | ForEach-Object {
#    New-ADOrganizationalUnit -Name $($_.Name) -Path $($_.Path)+"DC=$domain,DC=local" -Description $($_.Description)
    New-ADOrganizationalUnit -Name $($_.Name) -Path $($_.Path) -Description $($_.Description)
}
Write-Log "created OU structure"

# create security groups
# Note: you must edit the "securitygroups.csv" file first to change DC=CHANGEME,DC=local to the correct domain name. This will be fixed in a later version of this script. 
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating Security Groups------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
import-csv C:\AD_setup\securitygroups.csv | ForEach-Object {
    New-ADGroup -name $($_.Name) -SamAccountName $($_.Name) -GroupCategory $($_.GroupCategory) -GroupScope $($_.GroupScope) -Path $($_.Path) 
}
Write-Log "created security groups"

# configure NTP
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Configuring the time service--------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
$var = 'w32tm /config /manualpeerlist:pool.ntp.org /syncfromflags:manual /reliable:yes /update'
Start-Process -Verb RunAs cmd.exe -Args '/c', $var
Restart-Service w32time
Write-Log "configured the time service"

# install DFS
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Installing DFS----------------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
Install-Windowsfeature -Name FS-DFS-Namespace
Write-Log "installed DFS namespace feature"

 
