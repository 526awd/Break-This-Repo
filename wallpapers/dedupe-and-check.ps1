<#
  Dedupe downloaded wallpapers by wallhaven id, then pull each wallpaper's tag list
  from the API so we can confirm the character actually matches.
  ASCII-only on purpose.
#>
param([string]$Root = "E:\APP\deepseek\wallpapers")

$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
$headers = @{ "User-Agent" = $UA }

function Get-WithRetry {
    param([string]$Uri, [int]$Retries = 6)
    for ($a = 1; $a -le $Retries; $a++) {
        try { return Invoke-RestMethod -Uri $Uri -Headers $headers -TimeoutSec 40 }
        catch { if ($a -eq $Retries) { throw }; Start-Sleep -Milliseconds (700 * $a) }
    }
}

foreach ($dir in (Get-ChildItem -Path $Root -Directory)) {
    $files = Get-ChildItem -Path $dir.FullName -File | Where-Object { $_.Extension -in ".jpg", ".png" }
    $byId = [ordered]@{}
    foreach ($f in $files) {
        if ($f.Name -match '_([a-z0-9]{6})_(\d+x\d+)\.(jpg|png)$') {
            $id = $Matches[1]
            if ($byId.Contains($id)) {
                if ($f.Name.Length -lt $byId[$id].Name.Length) {
                    Remove-Item $byId[$id].FullName -Force -ErrorAction SilentlyContinue
                    $byId[$id] = $f
                }
                else { Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue }
            }
            else { $byId[$id] = $f }
        }
    }
    Write-Host ("=== {0}: {1} file(s), {2} unique id(s)" -f $dir.Name, $files.Count, $byId.Count)
    foreach ($id in $byId.Keys) {
        $f = $byId[$id]
        $tags = ""
        try {
            $meta = Get-WithRetry -Uri ("https://wallhaven.cc/api/v1/w/" + $id)
            $tags = (@($meta.data.tags | ForEach-Object { $_.name }) -join ", ")
        }
        catch { $tags = "(tag lookup failed)" }
        Write-Host ("  {0}`n     file : {1}`n     tags : {2}" -f $id, $f.Name, $tags)
        Start-Sleep -Milliseconds 400
    }
}
