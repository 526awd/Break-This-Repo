<#
  Fetch STATIC anime wallpapers from wallhaven.cc public API and download them locally.
  Purity is locked to SFW (100) so no NSFW/adult results are ever pulled.
  Only raster stills (jpeg/png) are kept: no gif/apng/webm, i.e. purely static wallpapers.
  NOTE: this file is intentionally ASCII-only; non-ASCII bytes break the parser when
        PowerShell reads a BOM-less UTF-8 script as ANSI.
#>
param(
    [Parameter(Mandatory = $true)][string]$Query,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [int]$Count = 12,
    [int]$MinWidth = 1920,
    [string]$Sorting = "relevance",
    [int]$Pages = 3
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
$headers = @{ "User-Agent" = $UA; "Accept" = "*/*" }

function Get-WithRetry {
    param([string]$Uri, [int]$Retries = 6)
    for ($a = 1; $a -le $Retries; $a++) {
        try { return Invoke-RestMethod -Uri $Uri -Headers $headers -TimeoutSec 40 }
        catch {
            if ($a -eq $Retries) { throw }
            Start-Sleep -Milliseconds (700 * $a)
        }
    }
}

function Save-WithRetry {
    param([string]$Uri, [string]$OutFile, [int]$Retries = 6)
    for ($a = 1; $a -le $Retries; $a++) {
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -Headers $headers -TimeoutSec 120
            if ((Get-Item $OutFile).Length -gt 20480) { return $true }
            Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
            throw "file too small"
        }
        catch {
            if ($a -eq $Retries) { return $false }
            Start-Sleep -Milliseconds (700 * $a)
        }
    }
}

$found = New-Object System.Collections.Generic.List[object]
$seen = New-Object System.Collections.Generic.HashSet[string]

foreach ($p in 1..$Pages) {
    $api = "https://wallhaven.cc/api/v1/search?q=" + [uri]::EscapeDataString($Query) +
           "&categories=010&purity=100&sorting=$Sorting&order=desc&page=$p"
    try { $resp = Get-WithRetry -Uri $api }
    catch { Write-Host "  ! page $p failed: $($_.Exception.Message)"; break }
    if (-not $resp.data -or @($resp.data).Count -eq 0) { break }
    foreach ($w in $resp.data) { if ($seen.Add($w.id)) { $found.Add($w) } }
    Start-Sleep -Milliseconds 500
}

# keep static stills only: jpeg/png, landscape, wide enough for a desktop
$static = @($found | Where-Object {
    ($_.file_type -eq "image/jpeg" -or $_.file_type -eq "image/png") -and
    ([int]$_.dimension_x -ge $MinWidth) -and
    ([int]$_.dimension_x -ge [int]$_.dimension_y)
})

Write-Host ("query='{0}'  raw={1}  static-landscape>={2}px = {3}" -f $Query, $found.Count, $MinWidth, $static.Count)

$safe = ($Query -replace '[^\w\-]', '_')
$ok = 0
foreach ($w in $static) {
    if ($ok -ge $Count) { break }
    $ext = if ($w.file_type -eq "image/png") { ".png" } else { ".jpg" }
    $file = Join-Path $OutDir ("{0}_{1}_{2}{3}" -f $safe, $w.id, $w.resolution, $ext)
    if (Test-Path $file) { $ok++; continue }
    if (Save-WithRetry -Uri $w.path -OutFile $file) {
        $ok++
        $mb = [math]::Round((Get-Item $file).Length / 1MB, 2)
        Write-Host ("  [{0}/{1}] OK {2}  {3}MB  {4}" -f $ok, $Count, (Split-Path $file -Leaf), $mb, $w.url)
    }
    else { Write-Host ("  FAIL {0}" -f $w.id) }
    Start-Sleep -Milliseconds 350
}
Write-Host ("done: {0} file(s) -> {1}" -f $ok, $OutDir)
