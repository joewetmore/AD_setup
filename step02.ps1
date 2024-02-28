#STEP 02 - Create the AD forest & domain

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

Write-Log "Beginning STEP02 of AD_Setup"

#Setup variables
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Gathering Information---------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
$domain = read-host "What is the domain name? (not FQDN, just first word)" 
$domainName = $domain + “.local”
$SMPassword = read-host "Specify a new safe mode (DSRM) administrator password? (write this down!)" -AsSecureString
$SMPassword = ConvertTo-SecureString $SMPassword -AsPlainText -Force
${c:\ad_setup\Domain.txt} = $domain
${c:\ad_setup\DomainName.txt} = $domainName
Write-Log "gathered user input. Domainname = $domainName."

#Install ADDS
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Installing ADDS---------------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
Install-Windowsfeature -Name AD-Domain-Services -IncludeManagementTool
Write-Log "installing ADDS feature" 
Write-Log -level ERROR -message "ERROR installing ADDS feature" 

#Create the forest and reboot. 
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating the AD Forest & Domain-----------" -ForegroundColor Green
Write-Host "-----and then rebooting------------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
Write-Log "Configuring the AD forest and domain. See C:\Windows\debug\Dcpromo.log and Dcpromoui.log for details" 
#Domain and Forest mode "7" is Windows 2016
$HashArguments = @{
    CreateDnsDelegation            = $false
    DomainName                     = $domainName
    DomainMode                     = 7
    ForestMode                     = 7
    DomainNetbiosName              = $Domain
    SafeModeAdministratorPassword  = $SMPassword 
}
Install-ADDSForest @HashArguments -InstallDns -force
