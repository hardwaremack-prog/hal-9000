# Downloads HAL's AI brain into this folder, one time.
# After this, the whole HAL Offline folder works with no internet,
# and you can copy it to a USB stick or another computer.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'      # makes downloads much faster in Windows PowerShell
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

Write-Host ""
Write-Host "  HAL 9000 - brain download"
Write-Host "  -------------------------"
Write-Host "  This downloads a small AI model (Llama 3.2 3B, about 2 GB) into the"
Write-Host "  'brain' folder here. You only need to do this once."
Write-Host ""
Write-Host "  1 = standard brain (most computers from the last few years)  [default]"
Write-Host "  2 = compatibility brain (use this if HAL says your graphics card can't run the standard one)"
Write-Host ""
$choice = Read-Host "  Press Enter for 1, or type 2"
if ($choice -eq '2') { $variant = 'q4f32_1' } else { $variant = 'q4f16_1' }

$base = "https://huggingface.co/mlc-ai/Llama-3.2-3B-Instruct-$variant-MLC/resolve/main/"
if ($env:HAL_BRAIN_URL) { $base = $env:HAL_BRAIN_URL }      # for testing only
$dest = Join-Path $root "brain\$variant"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

function Get-BrainFile([string]$name, [string]$saveAs) {
  $out = Join-Path $dest $saveAs
  if (Test-Path -LiteralPath $out) { return }          # already have it - lets you resume
  $tmp = "$out.part"
  Invoke-WebRequest -Uri ($base + $name) -OutFile $tmp -UseBasicParsing
  Move-Item -LiteralPath $tmp -Destination $out -Force
}

try {
  Write-Host ""
  Write-Host "  Getting the brain's settings..."
  Get-BrainFile 'mlc-chat-config.json' 'mlc-chat-config.json'
  try { Get-BrainFile 'tensor-cache.json' 'tensor-cache.json' }
  catch { Get-BrainFile 'ndarray-cache.json' 'tensor-cache.json' }

  $cfg = Get-Content -LiteralPath (Join-Path $dest 'mlc-chat-config.json') -Raw | ConvertFrom-Json
  foreach ($t in $cfg.tokenizer_files) { Get-BrainFile $t $t }

  $cache = Get-Content -LiteralPath (Join-Path $dest 'tensor-cache.json') -Raw | ConvertFrom-Json
  $shards = @($cache.records | ForEach-Object { $_.dataPath } | Select-Object -Unique)
  Write-Host "  Downloading $($shards.Count) pieces of HAL's brain..."
  $i = 0
  foreach ($s in $shards) {
    $i++
    $pct = [math]::Round(100 * $i / $shards.Count)
    Write-Host ("  [{0,3}%] piece {1} of {2}" -f $pct, $i, $shards.Count)
    Get-BrainFile $s $s
  }
  Set-Content -LiteralPath (Join-Path $dest 'complete.txt') -Value (Get-Date).ToString()
  Write-Host ""
  Write-Host "  Done. HAL's brain is installed."
  Write-Host "  Double-click 'Start HAL' to wake him up. No internet needed from now on."
} catch {
  Write-Host ""
  Write-Host "  The download stopped: $($_.Exception.Message)"
  Write-Host "  Check your internet connection and run 'Get HAL Brain' again."
  Write-Host "  It will pick up where it left off."
}
Write-Host ""
Read-Host "  Press Enter to close"
