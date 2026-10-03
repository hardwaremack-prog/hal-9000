# HAL 9000 (offline) - tiny local web server.
# Serves HAL.html, the AI engine and HAL's brain from this folder to your browser.
# Uses only what's built into Windows: nothing to install, no internet needed.
# Close this window to shut HAL down.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$port = 9010
if ($env:HAL_PORT) { $port = [int]$env:HAL_PORT }
$url = "http://localhost:$port/"

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.wasm' = 'application/wasm'
  '.json' = 'application/json'
  '.txt'  = 'text/plain; charset=utf-8'
  '.png'  = 'image/png'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try {
  $listener.Start()
} catch {
  Write-Host "  HAL is already running - opening $url"
  if (-not $env:HAL_NO_BROWSER) { Start-Process $url }
  Start-Sleep -Seconds 2
  exit
}

Write-Host ""
Write-Host "  HAL 9000 is awake:  $url"
Write-Host "  Everything runs from this folder. No internet needed."
Write-Host "  Close this window to shut HAL down."
Write-Host ""
if (-not $env:HAL_NO_BROWSER) { Start-Process $url }

function Resolve-HalFile([string]$path) {
  if ($path -eq '/') { $path = '/HAL.html' }
  # the AI engine asks for brain files as /model/<variant>/resolve/main/<file>
  if ($path -match '^/model/([A-Za-z0-9_]+)/resolve/main/(.+)$') {
    $variant = $matches[1]; $name = $matches[2]
    $dir = Join-Path $root ("brain\" + $variant)
    $file = Join-Path $dir ($name -replace '/', '\')
    if (($name -eq 'tensor-cache.json') -and -not (Test-Path -LiteralPath $file -PathType Leaf)) {
      $file = Join-Path $dir 'ndarray-cache.json'
    }
    return $file
  }
  return Join-Path $root (($path.TrimStart('/')) -replace '/', '\')
}

while ($listener.IsListening) {
  try { $ctx = $listener.GetContext() } catch { break }
  $req = $ctx.Request
  $res = $ctx.Response
  $fs = $null
  try {
    $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
    $full = [IO.Path]::GetFullPath((Resolve-HalFile $path))
    if ((-not $full.StartsWith($root)) -or (-not (Test-Path -LiteralPath $full -PathType Leaf))) {
      $res.StatusCode = 404
    } else {
      $ext = [IO.Path]::GetExtension($full).ToLower()
      if ($mime.ContainsKey($ext)) { $res.ContentType = $mime[$ext] } else { $res.ContentType = 'application/octet-stream' }
      $res.Headers.Add('Cache-Control', 'no-cache')
      $fs = [IO.File]::OpenRead($full)
      $res.ContentLength64 = $fs.Length
      if ($req.HttpMethod -ne 'HEAD') { $fs.CopyTo($res.OutputStream) }
    }
  } catch {
    # the browser cancelled a download, or similar - just carry on
  } finally {
    if ($fs) { $fs.Dispose() }
    try { $res.Close() } catch {}
  }
}
