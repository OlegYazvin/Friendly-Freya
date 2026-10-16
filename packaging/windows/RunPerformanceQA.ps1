param(
    [ValidateRange(0, 300)][int]$WarmupSeconds = 15,
    [ValidateRange(5, 3600)][int]$SampleSeconds = 135,
    [ValidateRange(1, 240)][int]$MinimumWindowFps = 30
)

$ErrorActionPreference = 'Stop'
$gameDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$gameExe = Join-Path $gameDirectory 'FriendlyFreya.exe'
$gamePack = Join-Path $gameDirectory 'FriendlyFreya.pck'
if (-not (Test-Path -LiteralPath $gameExe) -or -not (Test-Path -LiteralPath $gamePack)) {
    throw 'Keep RunPerformanceQA.ps1 beside FriendlyFreya.exe and FriendlyFreya.pck in the extracted ZIP.'
}

$logDirectory = Join-Path $gameDirectory ('performance-qa-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $logDirectory | Out-Null
$report = @(
    'Friendly Freya exported Windows graphical performance QA',
    ('Started: ' + (Get-Date -Format o)),
    ('Package: ' + $gameExe),
    ('Seed: 20260831; warm-up: {0}s; sample: {1}s; target: every five-second window >= {2} FPS' -f $WarmupSeconds, $SampleSeconds, $MinimumWindowFps),
    'The stress scenario is staged. It does not write the campaign save.',
    'Check the active GPU and power mode in Windows before accepting a result.'
)

try {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = @(Get-CimInstance Win32_Processor | ForEach-Object { $_.Name.Trim() }) -join '; '
    $computer = Get-CimInstance Win32_ComputerSystem
    $gpus = @(Get-CimInstance Win32_VideoController | ForEach-Object {
        '{0} (driver {1}, display {2}x{3})' -f $_.Name, $_.DriverVersion, $_.CurrentHorizontalResolution, $_.CurrentVerticalResolution
    }) -join '; '
    $report += 'Windows: {0} {1}' -f $os.Caption, $os.Version
    $report += 'CPU: ' + $cpu
    $report += 'GPU(s) installed: ' + $gpus
    $report += 'RAM: {0:N1} GiB' -f ($computer.TotalPhysicalMemory / 1GB)
    $report += 'Power scheme: ' + ((powercfg /getactivescheme 2>$null) -join ' ')
} catch {
    $report += 'Hardware inventory unavailable: ' + $_.Exception.Message
}

$previousEnvironment = @{}
foreach ($name in @('FREYA_EXPORTED_PERF_STRESS', 'FREYA_EXPORTED_CAMPAIGN_QA', 'FREYA_EXPORTED_WATCH_INTRO_QA', 'FREYA_WORLD_SEED', 'FREYA_PERF_STRESS_WARMUP_SECONDS', 'FREYA_PERF_STRESS_SAMPLE_SECONDS', 'FREYA_PERF_STRESS_HIDE_LANE_DASHES', 'FREYA_PERF_BENCHMARK', 'FREYA_PERF_PROFILE_GAMEPLAY', 'FREYA_STARTUP_VALIDATE', 'FREYA_SMOKE', 'FREYA_VALIDATE', 'FREYA_RELEASE_CONTENT_VALIDATE', 'FREYA_STARTUP_VIEW', 'FREYA_VISUAL_VIEW', 'FREYA_ALIEN_VIEW', 'FREYA_FAMILY_INTRO_VIEW', 'FREYA_ENDING_VIEW', 'FREYA_NATURAL_CAMPAIGN')) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$cleanEnvironment = @('FREYA_EXPORTED_CAMPAIGN_QA', 'FREYA_EXPORTED_WATCH_INTRO_QA', 'FREYA_PERF_STRESS_HIDE_LANE_DASHES', 'FREYA_PERF_BENCHMARK', 'FREYA_PERF_PROFILE_GAMEPLAY', 'FREYA_STARTUP_VALIDATE', 'FREYA_SMOKE', 'FREYA_VALIDATE', 'FREYA_RELEASE_CONTENT_VALIDATE', 'FREYA_STARTUP_VIEW', 'FREYA_VISUAL_VIEW', 'FREYA_ALIEN_VIEW', 'FREYA_FAMILY_INTRO_VIEW', 'FREYA_ENDING_VIEW', 'FREYA_NATURAL_CAMPAIGN')
foreach ($name in $cleanEnvironment) {
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}
$env:FREYA_EXPORTED_PERF_STRESS = '1'
$env:FREYA_WORLD_SEED = '20260831'
$env:FREYA_PERF_STRESS_WARMUP_SECONDS = [string]$WarmupSeconds
$env:FREYA_PERF_STRESS_SAMPLE_SECONDS = [string]$SampleSeconds

$allPassed = $true
try {
    foreach ($resolution in @('1280x720', '1920x1080')) {
        $logPath = Join-Path $logDirectory ('perf-' + $resolution + '.log')
        $windowMode = '--windowed'
        if ($resolution -eq '1920x1080') { $windowMode = '--fullscreen' }
        $arguments = '{0} --resolution {1} --log-file "{2}"' -f $windowMode, $resolution, $logPath
        Write-Host ('Running {0} graphical stress sample in {1} mode ({2}s warm-up + {3}s sample)...' -f $resolution, $windowMode, $WarmupSeconds, $SampleSeconds)
        $peakWorkingSetMb = 0.0
        $process = $null
        try {
            $process = Start-Process -FilePath $gameExe -WorkingDirectory $gameDirectory -ArgumentList $arguments -PassThru
            $deadline = (Get-Date).AddSeconds([Math]::Max(600, $WarmupSeconds + $SampleSeconds + 300))
            while (-not $process.WaitForExit(1000)) {
                $liveProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
                if ($null -ne $liveProcess) {
                    $peakWorkingSetMb = [Math]::Max($peakWorkingSetMb, $liveProcess.WorkingSet64 / 1MB)
                }
                if ((Get-Date) -gt $deadline) {
                    $process.Kill()
                    throw ('Game did not finish the {0} performance run before the timeout.' -f $resolution)
                }
            }
            $process.Refresh()
            if ($process.ExitCode -ne 0) {
                throw ('Game exited with code {0}.' -f $process.ExitCode)
            }
            if (-not (Test-Path -LiteralPath $logPath)) {
                throw 'Game log was not created.'
            }
            $resultLine = Select-String -LiteralPath $logPath -Pattern 'PERF_STRESS_RESULT' | Select-Object -Last 1
            if ($null -eq $resultLine) {
                throw 'Game log has no PERF_STRESS_RESULT marker.'
            }
            $displayLine = Select-String -LiteralPath $logPath -Pattern 'PERF_STRESS_DISPLAY phase=end' | Select-Object -Last 1
            if ($null -eq $displayLine) {
                throw 'Game log has no final display-size marker.'
            }
            $displayMatch = [regex]::Match($displayLine.Line, 'window=(\d+)x(\d+)\s+stable=(true|false)')
            if (-not $displayMatch.Success) {
                throw 'Final display-size marker is malformed.'
            }
            $actualResolution = '{0}x{1}' -f $displayMatch.Groups[1].Value, $displayMatch.Groups[2].Value
            if ($actualResolution -ne $resolution -or $displayMatch.Groups[3].Value -ne 'true') {
                throw ('Display size was {0} or changed during sampling; requested {1}.' -f $actualResolution, $resolution)
            }
            $values = @{}
            foreach ($entry in ($resultLine.Line -split '\s+')) {
                $pair = $entry -split '=', 2
                if ($pair.Count -eq 2) { $values[$pair[0]] = $pair[1] }
            }
            foreach ($required in @('seconds', 'windows', 'avg_fps', 'min_5s_fps', 'p95_frame_ms', 'p99_frame_ms')) {
                if (-not $values.ContainsKey($required)) {
                    throw ('Result marker has no {0} field.' -f $required)
                }
            }
            $reportedSeconds = [double]::Parse($values['seconds'], [Globalization.CultureInfo]::InvariantCulture)
            $completedWindows = [int]::Parse($values['windows'], [Globalization.CultureInfo]::InvariantCulture)
            $minimumWindows = [int][Math]::Ceiling($SampleSeconds / 5.0)
            if ($reportedSeconds -lt $SampleSeconds -or $completedWindows -lt $minimumWindows) {
                throw ('Sample ended early: {0}s and {1} completed five-second windows; expected at least {2}s and {3} windows.' -f $reportedSeconds, $completedWindows, $SampleSeconds, $minimumWindows)
            }
            $worstFps = [double]::Parse($values['min_5s_fps'], [Globalization.CultureInfo]::InvariantCulture)
            $status = 'PASS'
            if ($worstFps -lt $MinimumWindowFps) {
                $status = 'BELOW TARGET'
                $allPassed = $false
            }
            $summary = '{0}: {1}; average {2} FPS; worst five-second window {3} FPS; p95/p99 {4}/{5} ms; sampled peak working set {6:N1} MiB' -f $resolution, $status, $values['avg_fps'], $values['min_5s_fps'], $values['p95_frame_ms'], $values['p99_frame_ms'], $peakWorkingSetMb
            Write-Host $summary
            $report += $summary
        } catch {
            $allPassed = $false
            $failure = '{0}: ERROR: {1}' -f $resolution, $_.Exception.Message
            Write-Host $failure
            $report += $failure
            if ($null -ne $process -and -not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit()
            }
        }
        $report += 'Log: ' + $logPath
    }
} finally {
    foreach ($name in $previousEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process')
    }
    $report += 'Finished: ' + (Get-Date -Format o)
    $reportPath = Join-Path $logDirectory 'summary.txt'
    $report | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Host ('Report and full logs: ' + $logDirectory)
}

if (-not $allPassed) { exit 1 }
