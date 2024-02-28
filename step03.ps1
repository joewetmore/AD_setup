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

Write-Log "Beginning STEP03 of AD_Setup"

# get the domain from step02
$domain = Get-Content C:\AD_setup\Domain.txt


# create AD sites
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating AD Sites & Subnets---------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
import-csv c:\AD_setup\newsites.csv | New-ADReplicationSite 
Write-Log "creating AD sites"
#Write-Log -level ERROR -message "ERROR creating AD sites"

# import subnet list
import-csv c:\AD_setup\newsubnets.csv | New-ADReplicationSubnet 
Write-Log "creating AD subnets"
#Write-Log -level ERROR -message "ERROR creating AD subnets"

# create inter-site transport links

Read-Host -Prompt "Press Enter to continue"


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
Write-Log "creating OU structure"
#Write-Log -level ERROR -message "ERROR creating OU structure"

Read-Host -Prompt "Press Enter to continue"


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
Write-Log "creating security groups"
#Write-Log -level ERROR -message "ERROR creating security groups"

Read-Host -Prompt "Press Enter to continue"


# configure NTP
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Configuring the time service--------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Important: make sure VM options are-------" -ForegroundColor Green
Write-Host "-----not set to sync time with hypervisor------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
$timezone = Read-Host "What time zone is this system in? (Pacific Standard Time|Mountain Standard Time|Central Standard Time|Eastern Standard Time)" 
Set-TimeZone -Name $timezone
Write-Log "setting time zone to $timezone"
$var = 'w32tm /config /manualpeerlist:pool.ntp.org /syncfromflags:manual /reliable:yes /update'
Start-Process -Verb RunAs cmd.exe -Args '/c', $var
Restart-Service w32time
Write-Log "configuring the time service"
#Write-Log -level ERROR -message "ERROR configuring time service"

Read-Host -Prompt "Press Enter to continue"


# install & configure DFS
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Installing & configuring------------------" -ForegroundColor Green
Write-Host "-----DFS & File Services-----------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
Install-Windowsfeature -Name FS-DFS-Namespace
Install-Windowsfeature -Name FS-DFS-Replication
add-WindowsFeature -Name RSAT-DFS-Mgmt-Con
Install-WindowsFeature -Name File-Services
Install-WindowsFeature -Name FS-Resource-Manager
Write-Log "installing DFS namespace, replication, management tool, file services, fs-resource manager"

$path = "C:\DomainFiles"
If(!(test-path -PathType container $path))
{
      New-Item -ItemType Directory -Path $path
}
Write-Log "configuring DFS namespace & replication"


#Write-Log -level ERROR -message "ERROR installing DFS namespace feature"

Read-Host -Prompt "Press Enter to continue"


# optionally install NPS
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Option: Network Policy Services-----------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
$no = @("no","nah","nope","n")
$yes = @("yes","yup","yeah","y")
do
{
    $answ = read-host "Do you wish to install network policy services (*y/n)?"
}
until($no -contains $answ -or $yes -contains $answ)

if($no -contains $answ)
{
    # continue
}
elseif($yes -contains $answ)
{
    Install-WindowsFeature -Name NPAS
    Write-Log "installing network policy service"

}

Read-Host -Prompt "Press Enter to continue"


# optionally install print services
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Option: Print Services--------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
$no = @("no","nah","nope","n")
$yes = @("yes","yup","yeah","y")
do
{
    $answ = read-host "Do you wish to install print services (*y/n)?"
}
until($no -contains $answ -or $yes -contains $answ)

if($no -contains $answ)
{
    # continue
}
elseif($yes -contains $answ)
{
    Install-WindowsFeature -Name Print-Server
    Write-Log "installing print services"

}

Read-Host -Prompt "Press Enter to continue"


# Configure DNS
$domainName = Get-Content C:\AD_setup\domainname.txt
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Configuring DNS---------------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
Add-DnsServerForwarder -IPAddress 8.8.8.8 -PassThru
Add-DnsServerForwarder -IPAddress 1.1.1.1 -PassThru
# create reverse lookup zones
import-csv C:\AD_setup\DNSreverselookupzones.csv | ForEach-Object {
    Add-DnsServerPrimaryZone -NetworkId $($_.NetworkID) -ReplicationScope $($_.ReplicationScope)
}
# bulk create A records
Import-Csv -Path C:\AD_setup\DNSArecords.csv -Delimiter "," | ForEach-Object {
    Add-DnsServerResourceRecordA -Name $_.hostname -ZoneName $domainName -AllowUpdateAny -IPv4Address $_.host_ip -CreatePtr
}
Write-Log "configuring DNS"

Read-Host -Prompt "Press Enter to continue"


# Unconfigure all GPOs
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Clearing previous GPOs--------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
Remove-Item -LiteralPath "WinDir%\System32\GroupPolicyUsers" -Force -Recurse
Remove-Item -LiteralPath "%WinDir%\System32\GroupPolicy" -Force -Recurse
Write-Log "unconfigured preexisting GPOs"

# Copy ADMX files

# *********Final configurations****************

# Configure DNS1 and DNS2 on the network interface

Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Finished----------------------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
