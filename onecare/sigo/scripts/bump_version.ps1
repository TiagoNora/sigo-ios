param(
  [ValidateSet("build", "patch", "minor", "major")]
  [string]$Mode = "build"
)

$pubspecPath = Join-Path -Path $PSScriptRoot -ChildPath "..\\pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
  throw "pubspec.yaml not found at $pubspecPath"
}

$content = Get-Content -Raw $pubspecPath
$versionRegex = [regex]"(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$"
$match = $versionRegex.Match($content)

if (-not $match.Success) {
  throw "Could not find a version line like 'version: 1.2.3+4' in pubspec.yaml"
}

$major = [int]$match.Groups[1].Value
$minor = [int]$match.Groups[2].Value
$patch = [int]$match.Groups[3].Value
$build = [int]$match.Groups[4].Value

switch ($Mode) {
  "major" { $major++; $minor = 0; $patch = 0; $build = 1 }
  "minor" { $minor++; $patch = 0; $build = 1 }
  "patch" { $patch++; $build = 1 }
  "build" { $build++ }
}

$newVersionLine = "version: $major.$minor.$patch+$build"
$updatedContent = $versionRegex.Replace($content, $newVersionLine, 1)
Set-Content -NoNewline -Path $pubspecPath -Value $updatedContent

Write-Host "Updated $pubspecPath to $newVersionLine"
