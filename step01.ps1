 #STEP 01 - Name the computer and apply an IP address

#Don't forget, 
#  1) you will need to edit the CSV files first with data specific to the site
#  2) run these steps from an elevated powershell prompt

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

#Setup path
$path = "C:\AD_setup"
If(!(test-path -PathType container $path))
{
      New-Item -ItemType Directory -Path $path
      New-Item -ItemType Directory -Path "$path\Scripts"
      New-Item -ItemType Directory -Path "$path\Logs"
}

#Gathering variables
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Gathering Information---------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
$dc01name = read-host "What is the name of the first domain controller? (up to 15 characters, alpha or numberical only)"
$IP = read-host "What do you want to set the IPv4 to? (123.123.123.123 format)"
$MaskBits = read-host "How many bits is the subnet mask? (24 bits = 255.255.255.0)"
$Gateway = read-host "What do you want to set the gateway to? (123.123.123.123 format)"
$Dns = read-host "What do you want to set the first DNS to? (123.123.123.123 format)"
$IPType = "IPv4"
Write-Log "gathered user input for NIC configuration. IP address = $IP.  SubnetMask = $MaskBits bits.  Gateway = $Gateway.  DNS = $Dns."  

#Save these details
${c:\ad_setup\dc01name.txt} = $dc01name
${c:\ad_setup\ipv4.txt} = $IP +" "+ $MaskBits +" "+ $Gateway +" "+ $Dns

# Apply static IP
Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Applying the static IPv4 address----------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
 $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}
If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
 $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}
 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
 -AddressFamily $IPType `
 -IPAddress $IP `
 -PrefixLength $MaskBits `
 -DefaultGateway $Gateway
# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
write-log "applied the static IP address" 

#Rename the computer
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Changing the computer name----------------" -ForegroundColor Green
Write-Host "-----and then rebooting------------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
$Username = 'Administrator'
$Password = read-host "Please enter the local administrator account password" -AsSecureString
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass
Rename-Computer -NewName $dc01name -DomainCredential $Cred 
write-log "renamed the computer" 

Write-Host " "
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "-----Rebooting---------------------------------" -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host " "
Start-Sleep -Seconds 5
Restart-Computer 
