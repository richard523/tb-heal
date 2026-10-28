# tb-heal installer for Windows (status query only - PC-side heal is
# Linux/PipeWire only). Requires Python 3 and hidapi:  pip install hidapi
$ErrorActionPreference = "Stop"

$dest = "$env:LOCALAPPDATA\Programs\tb-heal"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item "$PSScriptRoot\tb-heal" "$dest\tb-heal.py" -Force
Write-Host "installed: $dest\tb-heal.py"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$dest*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$dest", "User")
  Write-Host "added $dest to your user PATH (new terminals only)"
}

Write-Host "run it with:  tb-heal.py   (or:  python $dest\tb-heal.py)"
