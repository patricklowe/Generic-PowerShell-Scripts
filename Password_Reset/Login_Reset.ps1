<#	Written by Patrick Löwe		15/09/2018
	This script will set the default login as patient
	and reset the patient account password, which must be entered by script runner.
	Devices to be reset must be included in allmachines.txt
#>
#---------------------------------------------------------------------------------------------------#
$inFile = ".\allmachines.txt"
$AllDevices = (Get-Content $inFile)
#---------------------------------------------------------------------------------------------------#
Write-Host "Enter Device Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Username = Read-Host
#	 Get password as masked input
Write-Host "Enter Device Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Password = Read-Host | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
#---------------------------------------------------------------------------------------------------#
Write-Host "Enter password for patient account: " -nonewline -BackgroundColor Black -ForegroundColor Yellow
$Password = Read-Host -AsSecureString
#---------------------------------------------------------------------------------------------------#
ForEach ($Device in $AllDevices) {
#	Test if device can be remoted onto
	$Test = Test-Connection -ComputerName $Device -Count 1 -Quiet
#	If it can connect, run the following
    if($Test -eq "True"){
		$UserAccount = Get-LocalUser -Name "patient"
	#	Set Automatic login
		$AutoLogin = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {Set-ItemProperty -path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -name AutoAdminLogon -value 1}
	#	Set Default account login
		$DefaultAccount = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {Set-ItemProperty -path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -name DefaultUsername -value "patient"}
    #	Remove login count 
		$RemoveCount = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {Remove-ItemProperty -path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -name AutoLogonCount -ErrorAction SilentlyContinue}
	#	Set password expire to false
		$ExpiryFalse = Invoke-Command -ComputerName $Device -Credential $credential -ScriptBlock {WMIC useraccount WHERE "Name='patient'" SET PasswordExpires=false}
	#	Set Password
		$UserAccount | Set-LocalUser -Password $Password
	}
    }
    else{
        Write-Host "`n$Device is offline`n" -BackgroundColor Black -ForegroundColor Red
        $MessageOFFline = "OFFLINE"
        Add-Content $OutFile "$Device, $MessageOFFline"
        }
    }