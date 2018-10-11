<#	Written by Patrick Löwe		27/08/2018
	This script will request a Patient CSN/VisitID
	It will return all relevant patient information in an excel file at the same directory
#>
#	------------------------------------------------------------------------------------------	#
Write-Host "`nEnter VisitID: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$VisitID = Read-Host
#	Setup SQL Details
Write-Host "Enter SQL Username: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Username = Read-Host
#	 Get password as masked input
Write-Host "Enter SQL Password: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Password = Read-Host -AsSecureString
#	 Get Server Instance
Write-Host "Enter SQL Server Instance: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$ServerInstance = Read-Host
#	Get SQL Database Name
Write-Host "Enter SQL Database: " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Database = Read-Host
#	------------------------------------------------------------------------------------------	#
#	Setup results file, delete any existing files
$OutFile = ".\Patient_Info.csv"
if(Test-Path -Path $OutFile)
{
	Remove-Item $OutFile
}
Write-Host "`nRetrieving Data for " -BackgroundColor Black -ForegroundColor Cyan -nonewline
Write-Host "$VisitID" -BackgroundColor Black -ForegroundColor Red;

#	------------------------------------------------------------------------------------------	#
$Admission = @"
DECLARE @AdmitID uniqueidentifier = 
(select PatientAdmissionGuid from PatientAdmission 	
where VisitID = '$VisitID')
--***********************************************--
select 
'ADMISSION' as 'Query', 
VisitID, 
PatientAdmissionId, 
PatientID, 
AdmittedOn, 
DischargedOn, 
ExpectedDischargeDate, 
InboxID,
Verified, 
HospitalService, 
PatientAdmissionGuid 
from PatientAdmission where PatientAdmissionGuid = @AdmitID;
"@
#	------------------------------------------------------------------------------------------	#

$Patient = @"
DECLARE @AdmitID uniqueidentifier = 
(select PatientAdmissionGuid from PatientAdmission 	
where VisitID = '$VisitID')
--***********************************************--
select 
'PATIENT' AS 'Query',
TagGroupID,
CultureID,
PrimaryLanguage,
PatientID,
StoryBoardID,
FreeTrialStarted,
DateCreated,
LastSession,
PatientNumber,
MandatoryCOntentViewed,
DoNotDisturb,
YearOfBirth,
CurrentStage,
ThemeID,
PictureID,
ParentalControlEnabled
PIN,
SafeBrowsingEnabled,
IncludeMyPhotosInScreensaver
from patient 
where PatientID = (select PatientID from PatientAdmission where PatientAdmissionGuid = @AdmitID);
"@
#	------------------------------------------------------------------------------------------	#
$Devices = @"
DECLARE @AdmitID uniqueidentifier = 
(select PatientAdmissionGuid from PatientAdmission 	
where VisitID = '$VisitID')
--***********************************************--
select	top 4
	pa.VisitID,
	c.Name,
	cp.* 
from PatientAdmission pa	
	join ClientPatient cp on pa.PatientAdmissionGuid = cp.PatientAdmissionGuid
	join Client c on cp.ClientID = c.ClientID
where cp.PatientAdmissionGuid = @AdmitID
order by [from] 
desc;
"@
#	------------------------------------------------------------------------------------------	#
$CareTeam = @"
DECLARE @AdmitID uniqueidentifier = 
(select PatientAdmissionGuid from PatientAdmission 	
where VisitID = '$VisitID')
--***********************************************--
select
	s.EmployeeID,		
	(Firstname + ', ' + LastName) as 'Staff Name', 		
	PatientFriendlyRole, 		
case 			
	when ImageBlobGuid is NULL	
	then 'No' 			
	else 'Yes' 
	end as 'Has Photo',
	s.StaffGuid, 
	[From], 
	[To], 
	ImageBlobGuid
from Staff s
join CareTeamAssignment cta on s.StaffGuid = cta.StaffGuid 
join CareTeamRole ctr on cta.CareTeamRoleID = ctr.CareTeamRoleID
where cta.PatientAdmissionGuid = @AdmitID
"@
#	------------------------------------------------------------------------------------------	#
$DietOrder = @"
DECLARE @AdmitID uniqueidentifier = 
(select PatientAdmissionGuid from PatientAdmission 	
where VisitID = '$VisitID')
--***********************************************--
select	
'DIETORDER' as 'Query',
pdo.OrderID,
pdo.OrderType,
pdo.DietCode,
DietInstruction,
MealPeriod,
EffectiveFrom,
EffectiveTo,
DietOrderID,
OrderTime,
ExternalID,
OrderControl,
PatientAdmissionID,	
PatientAdmissionGuid,
dt.[Name],
dt.ShowDietType,
dt.ShowMealOrdering
	from PatientDietOrder pdo		
	join PatientOrder po on pdo.OrderID = po.OrderID
	join DietType dt on pdo.DietCode = dt.DietCode
	where PatientAdmissionGuid = @AdmitID 
order by EffectiveFrom 
desc
"@
#	------------------------------------------------------------------------------------------	#
$Allergies = @"
DECLARE @AdmitID uniqueidentifier = 
(select PatientAdmissionGuid from PatientAdmission 	
where VisitID = '$VisitID')
--***********************************************--
select	
'ALLERGIES' as 'Query',
PatientAdmissionID,
pa.AllergyID,
PatientAdmissionGuid,
AllergyCode,
AllergyName,
AllergyDescription,
AllergyType,
AllergyNameLID,
AllergyDescriptionLID	
	from PatientAllergy pa		
	join Allergy a on pa.AllergyID =  a.AllergyID
where PatientAdmissionGuid = @AdmitID 
"@
#	------------------------------------------------------------------------------------------	#
$MealOrders = @"
DECLARE @AdmitID uniqueidentifier = 
(select PatientAdmissionGuid from PatientAdmission 	
where VisitID = '$VisitID')
--***********************************************--
select	
	'MEALS ORDERS' as 'Query',
MealOrder.PlacedOrder.PlacedOrderId,
MealId,
MealDate,
PatientAdmissionId,
RequiredDeliveryTime,
COntent,
CreatedAt,
ExternalOrderId	
	from MealOrder.PlacedOrder		
	where PatientAdmissionId = @AdmitID
order by CreatedAt 
desc
"@
#	------------------------------------------------------------------------------------------	#
$Education = @"
DECLARE @AdmitID uniqueidentifier = 
(select PatientAdmissionGuid from PatientAdmission 	
where VisitID = '$VisitID')
--***********************************************--
select	
	'ASSIGNED EDUCATION' as 'Query',
PatientEducationId,
PatientAdmissionId,
EducationLibraryItemId,
Rating,
AssignedDateUtc,
AssignedBy,
AssignmentSource,
CompletedDateUtc,
PatientEducationGuid,
DetailsBlob
	from PatientEngagement.PatientEducation		
	where PatientAdmissionId = @AdmitID
"@
#	------------------------------------------------------------------------------------------	#
Write-Host "`nQuerying " -BackgroundColor Black -ForegroundColor Cyan -nonewline
Write-Host "$ServerInstance\$Database " -BackgroundColor Black -ForegroundColor Red -nonewline
Write-Host "using " -BackgroundColor Black -ForegroundColor Cyan -nonewline
Write-Host "$Username" -BackgroundColor Black -ForegroundColor Red
$Result1 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Admission
$Result2 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Patient
$Result3 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Devices
$Result4 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $CareTeam
$Result5 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $DietOrder
$Result6 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Allergies
$Result7 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $MealOrders
$Result8 = invoke-sqlcmd -serverinstance $ServerInstance -database $Database -Username $Username -Password $Password -query $Education
#	------------------------------------------------------------------------------------------	#
$Result1 | Export-csv -Path ".\Admission.csv" -Append -Force
$Result2 | Export-Csv -Path ".\Patient.csv" -Append -Force
$Result3 | Export-Csv -Path ".\Devices.csv" -Append -Force
$Result4 | Export-Csv -Path ".\CareTeam.csv" -Append -Force
$Result5 | Export-Csv -Path ".\DietOrder.csv" -Append -Force
$Result6 | Export-Csv -Path ".\Allergies.csv" -Append -Force
$Result7 | Export-Csv -Path ".\MealOrders.csv" -Append -Force
$Result8 | Export-Csv -Path ".\Education.csv" -Append -Force
#	------------------------------------------------------------------------------------------	#
Write-Host "`nMerging Results..." -BackgroundColor Black -ForegroundColor Cyan

#	This will skip the first line within each of the 8 queries, do not change. It skips adding the '#TYPE System.Data.DataRow' into the Results file
$SkipLine = $true

#	Gather all data in all files at below location (with csv file type), then append onto results file
Get-ChildItem ".\*.csv" | foreach {
    $FilePath = $_
    $lines =  $lines = Get-Content $FilePath  
    $CopiedData = switch($SkipLine) {
           $true  {$lines}
           $false {$lines | Select -Skip 1}

    }
    $SkipLine = $false
    Add-Content ".\Patient_Info.csv" $CopiedData
#	Appends a new line between queries for easier reading
	Add-Content ".\Patient_Info.csv" -Value ""
    }

#	------------------------------------------------------------------------------------------	#
#	Delete the separate query results files
if(Test-Path -Path ".\Admission.csv"){Remove-Item ".\Admission.csv"}
if(Test-Path -Path ".\Patient.csv"){Remove-Item ".\Patient.csv"}
if(Test-Path -Path ".\Devices.csv"){Remove-Item ".\Devices.csv"}
if(Test-Path -Path ".\CareTeam.csv"){Remove-Item ".\CareTeam.csv"}
if(Test-Path -Path ".\DietOrder.csv"){Remove-Item ".\DietOrder.csv"}
if(Test-Path -Path ".\Allergies.csv"){Remove-Item ".\Allergies.csv"}
if(Test-Path -Path ".\MealOrders.csv"){Remove-Item ".\MealOrders.csv"}
if(Test-Path -Path ".\Education.csv"){Remove-Item ".\Education.csv"}
#	------------------------------------------------------------------------------------------	#
Write-Host "`nOpen Results Folder (Y/N): " -BackgroundColor Black -ForegroundColor Yellow -nonewline
$Option = Read-Host
if($Option.toLower() -eq "y")
{
	ii .
}
else 
{
	Write-Host "`nResults exported to "-BackgroundColor Black -ForegroundColor Cyan -nonewline
	Write-Host "$OutFile`n" -BackgroundColor Black -ForegroundColor Red
}