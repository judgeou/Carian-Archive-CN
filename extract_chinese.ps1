# Extract Elden Ring Simplified Chinese text into GameTextCN (same layout as GameText / GameTextJP).
# Prerequisites: Game\msg\zhocn\*.msgbnd.dcx (from UXM selective unpack with zhocn-only dictionary).

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Game = "G:\SteamLibrary\steamapps\common\ELDEN RING\Game"
$Yabber = Join-Path $Root "tools\Yabber 1.3.1\Yabber.exe"
$MsgDir = Join-Path $Game "msg\zhocn"
$Work = Join-Path $Root "tools\work_zhocn"
$Out = Join-Path $Root "GameTextCN"

if (-not (Test-Path $Yabber)) { throw "Yabber not found: $Yabber" }
if (-not (Test-Path $MsgDir)) {
    throw @"
Missing $MsgDir
Run UXM Selective Unpack first:
  1. Open tools\UXM Selective Unpack 2.4.2.0\UXM Selective Unpack.exe
  2. Confirm game path points to eldenring.exe
  3. Click Unpack (dictionary is set to zhocn msg only)
"@
}

New-Item -ItemType Directory -Force -Path $Work | Out-Null
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Out | Out-Null

$msgbnd = Get-ChildItem $MsgDir -Filter "*.msgbnd.dcx"
if ($msgbnd.Count -eq 0) { throw "No .msgbnd.dcx in $MsgDir" }

Write-Host "Unpacking $($msgbnd.Count) msgbnd files with Yabber..."
foreach ($f in $msgbnd) {
    Write-Host "  $($f.Name)"
    & $Yabber $f.FullName | Out-Null
}

# Yabber creates *-msgbnd-dcx folders next to each dcx in msg\zhocn
$bndFolders = Get-ChildItem $MsgDir -Directory -Filter "*msgbnd*"
if ($bndFolders.Count -eq 0) { throw "No unpacked *-msgbnd-dcx folders in $MsgDir" }

$destMsg = Join-Path $Out "GR\data\INTERROOT_win64\msg"
$langName = "zhoCN"
$destLang = Join-Path $destMsg $langName
New-Item -ItemType Directory -Force -Path $destLang | Out-Null

$totalFmg = 0
foreach ($dir in $bndFolders) {
    $msgRoot = Join-Path $dir.FullName "GR\data\INTERROOT_win64\msg"
    if (-not (Test-Path $msgRoot)) { continue }
    $langDirs = Get-ChildItem $msgRoot -Directory
    foreach ($langDir in $langDirs) {
        $langName = $langDir.Name
        $destLang = Join-Path $destMsg $langName
        New-Item -ItemType Directory -Force -Path $destLang | Out-Null
        $fmgs = Get-ChildItem $langDir.FullName -Filter "*.fmg"
        Write-Host "Converting $($fmgs.Count) FMG from $($dir.Name) ..."
        foreach ($f in $fmgs) {
            & $Yabber $f.FullName | Out-Null
            $xml = "$($f.FullName).xml"
            if (Test-Path $xml) {
                Copy-Item $xml $destLang -Force
                $totalFmg++
            }
        }
    }
}

$xmlCount = (Get-ChildItem $destLang -Filter "*.fmg.xml").Count
if ($xmlCount -eq 0) { throw "No .fmg.xml produced under $destLang" }
Write-Host "Done. $xmlCount XML files in $destLang"
Write-Host "Run: python parser.py"
