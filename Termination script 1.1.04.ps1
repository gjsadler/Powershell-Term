# Establish Variables
$user = Read-Host -Prompt "Username"
$email = $user + "@domain.com"
$newPass = Read-Host -Prompt  "Password"
$computerName = Read-Host -Prompt "Computer"
$date = Get-Date
$description = "Terminated " + $date
$creds = Get-Credential


#checks to validate user
while (-not [bool] (Get-ADUser -Filter { SamAccountName -eq $user })){

	'Could not find user'
    	$user = Read-Host -Prompt "Username" }
    
# Resets the account password (Tested Works)
Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $newPass -Force)
Write-Output '$user password has been reset'

# Remove from all groups instead of Domain users (Tested Works)
Get-AdPrincipalGroupMembership -Identity $user | Where-Object -Property Name -Ne -Value 'Domain Users' | Remove-AdGroupMember -Members $user
Write-Output '$user has been removed from all groups'


# Puts termination date in description on AD (Tested Works)
Set-ADUser -Identity $user -Description $description


# Move User to terminated users OU (Works Testet [domain admin])
Get-ADUser $user | Move-ADObject -TargetPath "OU=Terminated Users,OU=IT,DC=Domain,DC=com"
Write-Output '$user has been moved to terminated users OU'


# Disable User's AD account (Tested Works)	
Disable-ADAccount -Identity $user
Write-Output '$user account has been disabled'



# Restart the computer if it is on
$comOn = Test-Connection -BufferSize 32 -Count 1 -ComputerName $computerName -Quiet
If($comOn -eq 'True'){
	Restart-Computer -ComputerName $computerName -Force
	}
else{ 
	Warning-Output = "Could not find computer $computerName"   }


#Connects to all required services, Uncomment module if you need to install
#not using creds variable because legacy auth is disabled
#Install-Module MicrosoftTeams
Connect-MicrosoftTeams 
#Install-Module ExchangeOnline
Connect-ExchangeOnline
#Install-Module MSOnline
Connect-MsolService


#Removes main Microsoft Teams
Remove-TeamUser -GroupId ###################################### -User $email
Write-Output '$user has been removed from team'
Remove-TeamUser -GroupId ######################################## -User $email
Write-Output '$user has been removed from team'
Remove-TeamUser -GroupId ######################################## -User $email
Write-Output '$user has been removed from team'

#changes mailbox to shared
Set-Mailbox $user -Type Shared
Get-Mailbox -Identity $user | Format-List RecipientTypeDetails




#removes all Microsoft Licenses
(Get-MsolUser -UserPrincipalName $email).licenses.AccountSkuId |
foreach{
    Set-MsolUserLicense -UserPrincipalName $email -RemoveLicenses $_
}



Write-Output '$user has been terminated, press enter to end session'
$end = Read-Host

