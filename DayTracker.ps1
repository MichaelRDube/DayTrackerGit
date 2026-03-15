function Add-Activity {
	param (
		[string]$activityName,
		[string]$interval,
		[string]$activityDuration
	)

	$entry = [pscustomobject]@{
		Interval = $interval
		Duration = $activityDuration
	}

	if (-not $AggregateActivities.ContainsKey($activityName)) {
		$AggregateActivities[$activityName] = @()
	}

	$AggregateActivities[$activityName] += $entry

}

function Pull-Activities {
	param (
		[string[]]$logLines
	)

	$divider = "-------------------------------------------------------------------"

	"" | Out-File $logFile -Append
	$divider | Out-File $logFile -Append
	"" | Out-File $logFile -Append

	Write-Host ""
	Write-Host $divider
	Write-Host ""
	
	for ($i = 1; $i -lt $logLines.Count; $i++) {
		$logLine = $logLines[$i]
		$delim1 = $logLine.IndexOf(" ------ ")
		$delim2 = $logLine.LastIndexOf(" ------ ")
		$lineInterval = $logLine.Substring(0, $delim1)
		$lineDuration = $logLine.Substring($delim2 + 8)
		$lineActivity = $logLine.Substring($delim1 + 8, $delim2-$delim1-8)
		
		Add-Activity $lineActivity $lineInterval $lineDuration
	}

	foreach ($activityEntry in $AggregateActivities.Keys) {
		$activityTime = "00:00:00"
		Write-Host "$($activityEntry):"
		$activityEntry | Out-File $logFile -Append

		foreach ($entry in $AggregateActivities[$activityEntry]) {
			Write-Host "$($entry.Interval)----$($entry.Duration)"
			"$($entry.Interval)   ~$($entry.Duration)" | Out-File $logFile -Append
			$activityTime = Sum-Time $activityTime $entry.Duration
		}
		Write-Host "           Total time: $($activityTime)"
		"           Total time: $($activityTime)" | Out-File $logFile -Append
		Write-Host ""
		"" | Out-File $logFile -Append
		Write-Host "------------------------------------------------"
		"------------------------------------------------" | Out-File $logFile -Append
		Write-Host ""
		"" | Out-File $logFile -Append
	}

	"" | Out-File $logFile -Append
	"" | Out-File $logFile -Append
}

function Sum-Time {
	param (
		[string]$t1,
		[string]$t2
	)


	[int]$s1 = $t1.Substring(6)
	[int]$m1 = $t1.Substring(3, 2)
	[int]$h1 = $t1.Substring(0, 2)

	[int]$s2 = $t2.Substring(6)
	[int]$m2 = $t2.Substring(3, 2)
	[int]$h2 = $t2.Substring(0, 2)

	$s3 = $s1 + $s2
	$m3 = $m1 + $m2
	$h3 = $h1 + $h2

	$m3 += [math]::Floor($s3/60)
	$s3 %= 60

	$h3 += [math]::Floor($m3/60)
	$m3 %= 60

	$s3 = $s3.ToString("00")
	$m3 = $m3.ToString("00")
	$h3 = $h3.ToString("00")

	return "$($h3):$($m3):$($s3)"
}

function Remove-Summary {
	param (
	)
	$divider = "-------------------------------------------------------------------"
	$list = Get-Content $logFile
	$dividerFound = $false

	for ($i = 0; $i -lt $list.Count-1; $i++) {
		if ($list[$i] -match $divider -and [string]::IsNullOrWhiteSpace($list[$i-1]) -and [string]::IsNullOrWhiteSpace($list[$i+1])) {
			$keepBefore = $list[0..($i-2)]
			$dividerFound = $true
			break
		}
	}
	if ($dividerFound -eq $false) {
		return
	}
	#$last = Get-Content $logFile -Tail 1

	Clear-Content $logFile

	$keepBefore | Out-File $logFile -Append
	#$last | Out-File $logFile -Append
}


#Script start
###1
$replacementPath = Join-Path $PSSriptRoot "DayTracker.ps1"
try {
	Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MichaelRDube/DayTrackerGit/refs/heads/main/DayTracker.ps1" -OutFile $replacementPath
}
catch {
	Write-Host "Could not check for updates"
	Write-Host "$_"
	Write-Error "$($_.ScriptStackTrace)"
}


$AggregateActivities = @{}
$lastCheckIn = Get-Date
$currentCheckIn = $lastCheckIn

$logFolder = Join-Path $PSScriptRoot "MyDays"
$logFile = Join-Path $logFolder "MyDay $($lastCheckIn.ToString('MM-dd-yyyy')).txt"
New-Item -ItemType Directory -Path $logFolder -Force | Out-Null

$activity = "Tracker started"
try {
	if (Test-Path $logFile -PathType Leaf) {
		if (Get-Content $logFile -TotalCount 1) {
			Remove-Summary
			$activity = "Tracker restarted (Inactive during interval)"
			$lastLine = Get-Content $logFile -Tail 1
			$lastKnownInterval = $lastLine.Substring(0, $lastLine.indexOf(" ------ "))
			$lastKnownTime = $lastKnownInterval.Substring($lastKnownInterval.IndexOf(" - ")+3)
			$lastCheckIn = [datetime]::ParseExact($lastKnownTime, "HH:mm:ss", $null)
		}
	}
	while ($activity -ne "end" -and $activity -ne "exit" -and $activity -ne "done") {
	
		$currentCheckIn = Get-Date
		$duration = $currentCheckIn - $lastCheckIn

		$formattedActivity = "$($lastCheckIn.ToString('HH\:mm\:ss')) - $($currentCheckIn.ToString('HH:mm:ss')) ------ $activity ------ $($duration.ToString('hh\:mm\:ss'))"
		Write-Host $formattedActivity
		$formattedActivity | Out-File $logFile -Append

		$activity = Read-Host
		$lastCheckIn = $currentCheckIn

		#if ($activity -eq "end" -or $activity -eq "done") {
		#	$fileContents = Get-Content $logFile
		#	Pull-Activities $fileContents
		#}
	}
}
catch {
	Write-Host "$_"
	Write-Error "$($_.ScriptStackTrace)"
}
finally{
	$currentCheckIn = Get-Date
	$duration = $currentCheckIn - $lastCheckIn
	$formattedActivity = "$($lastCheckIn.ToString('HH\:mm\:ss')) - $($currentCheckIn.ToString('HH\:mm\:ss')) ------ Untracked ------ $($duration.ToString('hh\:mm\:ss'))"
	$formattedActivity | Out-File $logFile -Append

	$fileContents = Get-Content $logFile
	#
	Pull-Activities $fileContents
	
}