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

#Pull-Update

$AggregateActivities = @{}
$lastCheckIn = Get-Date
$currentCheckIn = $lastCheckIn

