function Pull-Update {
	param()
	$replacementPath = Join-Path $PSScriptRoot "DayTracker.ps1"
	try {
		$oldFile = Get-Content $replacementPath

		$updatedFile = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MichaelRDube/DayTrackerGit/refs/heads/main/DayTracker.ps1"
		$updatedFile = $updatedFile.Content
		
		Clear-Content $replacementPath
		$updatedFile | Out-File $replacementPath -Append
		
	}
	catch {
		Write-Host "Could not update"
		Clear-Content $replacementPath
		$oldFile | Out-File $replacementPath -Append
	}
}

function Log-Setup {
	param(
		[string]today
	)
	
	New-Item -ItemType Directory -Path $logFolder -Force | Out-Null

}

#Pull-Update

$AggregateActivities = @{}
$lastCheckIn = Get-Date
$currentCheckIn = $lastCheckIn

$logFolder = Join-Path $PSScriptRoot "MyDays"
$logFile = Join-Path $logFolder "MyDay $($lastCheckIn.ToString('MM-dd-yyyy')).txt"