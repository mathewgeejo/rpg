param(
    [ValidateSet('title','play','forest','depth','ritual','map','benchmark','character','battle','dialogue','briar','tide','summon','debug','companions','settings','bossbenchmark','observatory')][string]$Mode = 'play',
    [ValidateSet('1440x900','1920x1080')][string]$Resolution = '1440x900'
)
$ErrorActionPreference = 'Stop'
$atlasRoot = Split-Path -Parent $PSScriptRoot
$atlasEngine = Get-ChildItem "$env:LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe" -Filter '*console.exe' | Select-Object -First 1
if (-not $atlasEngine) { throw 'The Godot console executable was not found.' }
$atlasName = if ($Resolution -eq '1440x900') { $Mode } else { "$Mode-$Resolution" }
$atlasLog = Join-Path $atlasRoot "artifacts/$atlasName.log"
$atlasErrors = Join-Path $atlasRoot "artifacts/$atlasName-errors.log"
$atlasArgs = @('--path', ('"' + $atlasRoot + '"'), '--resolution', $Resolution, '--', "--capture-$Mode")
if ($Resolution -eq '1920x1080') {
    $atlasArgs = @('--path', ('"' + $atlasRoot + '"'), '--fullscreen', '--resolution', $Resolution, '--', "--capture-$Mode")
}
$atlasProcess = Start-Process -FilePath $atlasEngine.FullName -ArgumentList $atlasArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $atlasLog -RedirectStandardError $atlasErrors
if (-not $atlasProcess.WaitForExit($(if ($Mode -eq 'bossbenchmark') { 60000 } else { 20000 }))) {
    Stop-Process -Id $atlasProcess.Id
    throw "Capture timed out. Inspect $atlasErrors"
}
$atlasErrorText = Get-Content -LiteralPath $atlasErrors -Raw
if ($atlasErrorText -match 'SCRIPT ERROR|ERROR:') { throw $atlasErrorText }
if ($atlasName -ne $Mode) {
    Move-Item -LiteralPath (Join-Path $atlasRoot "artifacts/$Mode.png") -Destination (Join-Path $atlasRoot "artifacts/$atlasName.png") -Force
}
Get-Content -LiteralPath $atlasLog
