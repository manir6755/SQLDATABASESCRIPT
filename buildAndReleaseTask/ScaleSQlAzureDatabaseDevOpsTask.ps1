[CmdletBinding()] 
param() 
 
Trace-VstsEnteringInvocation $MyInvocation

# Get inputs. 
$SqlServerName = Get-VstsInput -Name 'SqlServerName' -Require 
$SqlServerUsername = Get-VstsInput -Name 'SqlServerUsername' -Require 
$SqlServerPassword = Get-VstsInput -Name 'SqlServerPassword' -Require 
$DatabaseName = Get-VstsInput -Name 'DatabaseName' -Require 
$Edition = Get-VstsInput -Name 'Edition' -Require 
$PerfLevel = Get-VstsInput -Name 'PerfLevel' -Require 

Write-Output "Starting vertical scaling..."
Write-Output "Using following inputs:"
Write-Output "SqlServerName: $SqlServerName"
Write-Output "SqlServerUsername: $SqlServerUsername"
Write-Output "SqlServerPassword: ***** (come on you didn't think we'd print out your password did you!)"
Write-Output "DatabaseName: $DatabaseName"
Write-Output "Edition: $Edition"
Write-Output "PerfLevel: $PerfLevel"

# Establish credentials for Azure SQL Database server 
$Servercredential = new-object System.Management.Automation.PSCredential($SqlServerUsername, ($SqlServerPassword | ConvertTo-SecureString -asPlainText -Force)) 

# Create connection context for Azure SQL Database server
$CTX = New-AzureSqlDatabaseServerContext -ManageUrl "https://$SqlServerName.database.windows.net" -Credential $ServerCredential

# Get Azure SQL Database context
$Db = Get-AzureSqlDatabase $CTX -DatabaseName $DatabaseName

# GEt db info in order to check if database is not already on the required perf level
$DbInfo = Get-AzureSqlDatabase $CTX -Database $Db

if (($DbInfo.Edition -eq $Edition) -and ($DbInfo.ServiceObjectiveName -eq $PerfLevel)) {
	Write-Output "Database is already at specified edition ($Edition) and perf level ($PerfLevel)"
} else {
	# Specify the specific performance level for the target $DatabaseName
	$ServiceObjective = Get-AzureSqlDatabaseServiceObjective $CTX -ServiceObjectiveName "$PerfLevel"

	# Set the new edition/performance level
	Set-AzureSqlDatabase $CTX -Database $Db -ServiceObjective $ServiceObjective -Edition $Edition -Force

	# Output final status message
	Write-Output "Requested Scaling the performance level of $DatabaseName to $Edition - $PerfLevel "

	$DbInfo = Get-AzureSqlDatabase $CTX -Database $Db

	DO {
		Write-Output "waiting for database scale request to complete..."
		Start-Sleep -s 15
		
		# retrieve database info again for next interaction check
		$DbInfo = Get-AzureSqlDatabase $CTX -Database $Db

		if ($DbInfo.Edition -eq $Edition){
			Write-Output "Edition is $Edition"
		} else {
			Write-Output "Edition is not yet $Edition"
		}

		if ($DbInfo.ServiceObjectiveName -eq $PerfLevel) {
			Write-Output "PerfLevel is $PerfLevel"
		} else {
			Write-Output "PerfLevel is not yet $PerfLevel"
		}

	} While (($DbInfo.Edition -ne $Edition) -or ($DbInfo.ServiceObjectiveName -ne $PerfLevel))

	Write-Output "Scaled the performance level of $DatabaseName to $Edition - $PerfLevel "
}

Write-Output "Thank you for using the CodeStream Scale Sql Azure Database Task."


