$ErrorActionPreference = 'Stop'
$atlasEngine = Get-Command godot -ErrorAction SilentlyContinue
if (-not $atlasEngine) {
    throw 'Godot 4 is required. Install it, or open project.godot in the Godot editor.'
}
& $atlasEngine.Source --path $PSScriptRoot
