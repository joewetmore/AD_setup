 #STEP 02 - Create the AD forest & domain

#Setup variables
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Gathering Information---------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
$domain = read-host "What is the domain name? (not FQDN, just first word)" 
$domainName = $domain + “.local”
$SMPassword = read-host "Specify a new safe mode (DSRM) administrator password? (write this down!)" -AsSecureString
$SMPassword = ConvertTo-SecureString $SMPassword -AsPlainText -Force
${c:\ad_setup\Domain.txt} = $domain
${c:\ad_setup\DomainName.txt} = $domainName

#Install ADDS
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Installing ADDS---------------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Install-Windowsfeature -Name AD-Domain-Services -IncludeManagementTool

#Create the forest and reboot. 
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating the AD Forest & Domain-----------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
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
