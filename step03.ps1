 #STEP 03 - 

# create AD sites
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating AD Sites & Subnets---------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
import-csv c:\AD_setup\newsites.csv | New-ADReplicationSite -verbose

# import subnet list
import-csv c:\AD_setup\newsubnets.csv | New-ADReplicationSubnet -verbose

# get the domain from step02
$domain = Get-Content C:\AD_setup\Domain.txt

# create OU structure
# Note: you must edit the "newOUs.csv" file first to change DC=CHANGEME,DC=local to the correct domain name. This will be fixed in a later version of this script. 
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating the Organizational Units---------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
import-csv C:\AD_setup\newOUs.csv | ForEach-Object {
#    New-ADOrganizationalUnit -Name $($_.Name) -Path $($_.Path)+"DC=$domain,DC=local" -Description $($_.Description)
    New-ADOrganizationalUnit -Name $($_.Name) -Path $($_.Path) -Description $($_.Description)
}

# create TLA-Regional Admins and TLA-Helpdesk groups
# Note: you must edit the "securitygroups.csv" file first to change DC=CHANGEME,DC=local to the correct domain name. This will be fixed in a later version of this script. 
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Creating Security Groups------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
import-csv C:\AD_setup\securitygroups.csv | ForEach-Object {
    New-ADGroup -name $($_.Name) -SamAccountName $($_.Name) -GroupCategory $($_.GroupCategory) -GroupScope $($_.GroupScope) -Path $($_.Path) 
} 
